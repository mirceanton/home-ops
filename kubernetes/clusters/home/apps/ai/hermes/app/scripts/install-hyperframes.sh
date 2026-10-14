#!/bin/sh
# Installs the HyperFrames CLI + the headless Chrome it renders with, for the
# youtube-assistant agent. Runs as the `hyperframes-setup` init container, which
# shares the app image (Debian trixie, node >= 22, apt lists, dpkg-deb) and the
# hermes data volume (/opt/data).
#
# Everything lands on the data volume so it survives a pod restart:
#   /opt/data/.local/bin/hyperframes    wrapper (LD_LIBRARY_PATH + unzip on PATH)
#   /opt/data/.local/lib/node_modules   npm global install
#   /opt/data/.local/share/hyperframes  vendored Chrome shared libraries
#   /opt/data/.cache/hyperframes        Chrome Headless Shell (~115 MB)
#
# WHY the library vendoring: the hermes image ships no Chrome shared objects, the
# container runs as uid 10000 with a read-only root filesystem, so the usual
# `apt-get install chromium` is not available. `apt-get download` + `dpkg-deb -x`
# need no privileges, so the packages are fetched and unpacked into the data
# volume and reached through LD_LIBRARY_PATH set by the wrapper only — the global
# container environment stays untouched. Core runtime packages (libc6,
# libstdc++, zlib) are deliberately NOT in the list: shadowing the system copies
# would break every other tool in the container.
#
# The package list is derived from `ldd chrome-headless-shell` on Debian trixie.
# The check at the end of this script re-runs ldd and warns if any library is
# still missing, so a list that drifts out of date is visible in the pod log.
#
# A marker keyed on the CLI version + HF_SETUP_REV short-circuits every later
# boot. Bump HF_SETUP_REV when the package list or the wrapper changes.
#
# This script is intentionally non-fatal: it never fails the init container, so a
# registry/apt outage cannot block the Hermes pod from starting. Failures are
# logged as `WARN [hyperframes-setup] ...`, the marker is not written, and the
# next pod start retries.

set -u

HF_VERSION=0.8.158
HF_SETUP_REV=r1

# Profile whose skills receive the HyperFrames agent skills bundled in the CLI
# package. Space separated if more than one profile needs them.
HF_PROFILES="youtube-assistant"
HF_SKILLS_CATEGORY=creative

BASE=/opt/data
PREFIX=$BASE/.local
SHARE=$PREFIX/share/hyperframes
LIB=$SHARE/lib
BIN=$SHARE/bin
NPMDIR=$PREFIX/lib/node_modules
MARKER=$SHARE/.installed-$HF_VERSION-$HF_SETUP_REV
WORK=/tmp/hyperframes-setup

export HOME=$BASE
export HYPERFRAMES_NO_AUTO_INSTALL=1

log() { echo "[hyperframes-setup] $*"; }
warn() { echo "WARN [hyperframes-setup] $*" >&2; }

# Debian trixie packages providing the Chrome Headless Shell shared libraries.
HF_DEB_PACKAGES="
unzip
libnss3 libnspr4
libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64
libcups2t64 libdrm2 libgbm1 libdbus-1-3
libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2
libxkbcommon0 libxrender1 libxcursor1 libxi6 libxtst6 libxshmfence1
libpango-1.0-0 libcairo2 libpixman-1-0 libpng16-16t64 libfreetype6
libfontconfig1 libharfbuzz0b libthai0 libdatrie1 libfribidi0 libgraphite2-3
libbrotli1 libxau6 libxdmcp6 libbsd0 libmd0
libglib2.0-0t64 libpcre2-8-0 libffi8
libasound2t64 libexpat1
libsm6 libice6 libwayland-client0 libwayland-server0 libwayland-cursor0
libegl1 libgles2 libopengl0
libudev1 libcap2 libacl1 libselinux1 libmount1 libblkid1 libuuid1
liblz4-1 libzstd1 libsystemd0 libgcrypt20 libgpg-error0 liblzma5 libbz2-1.0
libwebp7 libjpeg62-turbo libxml2
"

install_hyperframes() {
  mkdir -p "$LIB" "$BIN" "$SHARE/extract-cache" "$BASE/.cache"

  # This runs in the app image. Fail loudly here rather than half-way through if a
  # future image drops one of these.
  for tool in apt-get dpkg-deb npm tar cp; do
    command -v "$tool" >/dev/null 2>&1 || { warn "$tool is not on PATH"; return 1; }
  done

  # 1. Vendor the Chrome shared libraries.
  rm -rf "$WORK"
  mkdir -p "$WORK/debs"
  cd "$WORK/debs" || return 1
  missing=""
  for pkg in $HF_DEB_PACKAGES; do
    apt-get download "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
  done
  [ -n "$missing" ] && warn "packages not downloadable (suite changed?):$missing"
  count=0
  for deb in ./*.deb; do
    [ -e "$deb" ] || continue
    dpkg-deb -x "$deb" "$LIB" || warn "could not extract $deb"
    count=$((count + 1))
  done
  log "unpacked $count package(s) into $LIB"
  [ "$count" -gt 0 ] || return 1

  # unzip is what the CLI extracts its Chrome download with.
  cp "$LIB/usr/bin/unzip" "$BIN/unzip" 2>/dev/null || warn "no unzip in the downloaded set"

  # 2. Install the CLI into the data volume. /opt/data/.local/bin is already on
  #    the container PATH.
  npm install -g --prefix "$PREFIX" --no-fund --no-audit "hyperframes@$HF_VERSION" >/dev/null 2>&1 || {
    warn "npm install hyperframes@$HF_VERSION failed"
    return 1
  }
  [ -x "$PREFIX/bin/hyperframes" ] || { warn "npm did not create $PREFIX/bin/hyperframes"; return 1; }

  # 3. Replace npm's shim with a wrapper that scopes the vendored libraries and
  #    the extraction cache to the hyperframes process tree (Chrome inherits it).
  mv -f "$PREFIX/bin/hyperframes" "$PREFIX/bin/hyperframes-bin"
  cat >"$PREFIX/bin/hyperframes" <<'WRAPPER'
#!/bin/sh
# HyperFrames CLI wrapper. Adds the vendored Chrome shared libraries (and the
# unzip they are extracted with) for this process tree only, so the rest of the
# container keeps its own library path.
HF_SHARE=/opt/data/.local/share/hyperframes
LD_LIBRARY_PATH="$HF_SHARE/lib/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH
PATH="$HF_SHARE/bin:$PATH"
export PATH
HYPERFRAMES_EXTRACT_CACHE_DIR="$HF_SHARE/extract-cache"
export HYPERFRAMES_EXTRACT_CACHE_DIR
exec /opt/data/.local/bin/hyperframes-bin "$@"
WRAPPER
  chmod 755 "$PREFIX/bin/hyperframes" "$PREFIX/bin/hyperframes-bin"

  # 4. Fetch Chrome Headless Shell (~115 MB) and prove it can load its libraries.
  "$PREFIX/bin/hyperframes" browser ensure >/dev/null 2>&1 || warn "browser ensure failed"
  chrome=$("$PREFIX/bin/hyperframes" browser path 2>/dev/null | tail -1)
  if [ -z "$chrome" ] || [ ! -x "$chrome" ]; then
    warn "no Chrome Headless Shell after browser ensure"
    return 1
  fi
  log "chrome: $chrome"
  if command -v ldd >/dev/null 2>&1; then
    broken=$(LD_LIBRARY_PATH="$LIB/usr/lib/x86_64-linux-gnu" ldd "$chrome" 2>/dev/null | grep 'not found' | sort -u)
    [ -n "$broken" ] && warn "chrome still missing libraries: $(echo "$broken" | tr '\n' ' ')"
  fi

  # 5. Hand the agent skills bundled in the CLI package to the profile(s), so the
  #    authoring contract matches the installed CLI version.
  skills_src="$NPMDIR/hyperframes/dist/skills"
  for profile in $HF_PROFILES; do
    dest="$BASE/profiles/$profile/skills/$HF_SKILLS_CATEGORY"
    [ -d "$skills_src" ] || { warn "no bundled skills at $skills_src"; break; }
    mkdir -p "$dest"
    for skill in "$skills_src"/*; do
      [ -d "$skill" ] || continue
      cp -R "$skill" "$dest/" || warn "could not seed $(basename "$skill")"
    done
    log "seeded skills into $dest"
  done

  touch "$MARKER"
  log "installed hyperframes $HF_VERSION"
}

if [ -e "$MARKER" ]; then
  log "already installed (hyperframes $HF_VERSION, $HF_SETUP_REV) — nothing to do"
  exit 0
fi

if install_hyperframes; then
  log "done"
else
  warn "install did not complete; the agent will run without hyperframes and the next pod start retries"
fi

# Never fail the pod: hyperframes is a capability for one profile, not a
# dependency of the Hermes gateway.
exit 0
