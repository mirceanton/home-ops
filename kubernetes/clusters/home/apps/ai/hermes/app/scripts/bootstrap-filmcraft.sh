#!/bin/sh
# Reference: manual filmcraft bootstrap on the hermes PVC.
#
# The HelmRelease mounts the filmcraft image volume at /opt/filmcraft, so
# this script is NOT needed in normal operation — the binary arrives with
# the pod. It exists as the git-side record of the upstream version and
# checksum for the video pipeline, and as a recovery path if the image
# volume were ever removed.
#
# Idempotent: re-running replaces the installation.

set -eu

VERSION="0.12.0"
SHA256="ddff0a2ec0d89e5e9e65644ed724b5b79959600b1602fd4ea6653b5a54bf88fd"
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    *) echo "unsupported arch: $ARCH" >&2; exit 1 ;;
esac

DEST="/opt/data/bin/filmcraft"
URL_BASE="https://github.com/storytold/filmcraft/releases/download/v${VERSION}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading FilmCraft ${VERSION} (linux-${ARCH})..."
curl -fsSL "${URL_BASE}/SHA256SUMS.txt" -o "${TMP}/SHA256SUMS.txt"
curl -fsSL "${URL_BASE}/filmcraft-${VERSION}-linux-${ARCH}.tar.gz" -o "${TMP}/filmcraft.tar.gz"

expected="$(grep "filmcraft-${VERSION}-linux-${ARCH}.tar.gz$" "${TMP}/SHA256SUMS.txt" | awk '{print $1}')"
actual="$(sha256sum "${TMP}/filmcraft.tar.gz" | awk '{print $1}')"
[ "${expected}" = "${actual}" ] || { echo "checksum mismatch: expected ${expected}, got ${actual}" >&2; exit 1; }
echo "Checksum verified."

tar -xzf "${TMP}/filmcraft.tar.gz" -C "${TMP}"
mkdir -p "${DEST}"
rm -rf "${DEST}-staging"
mv "${TMP}/filmcraft-${VERSION}-linux-${ARCH}" "${DEST}-staging"
rm -rf "${DEST}"
mv "${DEST}-staging" "${DEST}"

"${DEST}/bin/filmcraft-cli" --version
echo "Installed to ${DEST}"
