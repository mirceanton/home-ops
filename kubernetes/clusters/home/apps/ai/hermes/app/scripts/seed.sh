#!/bin/sh
set -eu

# =================================================================================================
# Seed Policy
# =================================================================================================
# config.yaml and SOUL.md are SEED-IF-ABSENT: they are copied out of /seed only when the destination
# file does not exist yet, so changes made at runtime inside the pod survive container restarts.
# Secrets are deliberately NOT covered by that rule — see the .env handling below, which is
# re-rendered on every boot.
#
# Escape hatch: set HERMES_SEED_FORCE=1 on the seed-config initContainer in helm-release.yaml to
# restore the old "overwrite everything on every boot" behaviour for one rollout, e.g.
#
#   initContainers:
#     seed-config:
#       env:
#         HERMES_SEED_FORCE: "1"
#
# Remove it again afterwards — while it is set it discards runtime edits to the piped configs.
HERMES_SEED_FORCE="${HERMES_SEED_FORCE:-0}"

# seed_file <source> <destination>
seed_file() {
  if [ "$HERMES_SEED_FORCE" = "1" ]; then
    cp "$1" "$2"
    echo "  overwritten (HERMES_SEED_FORCE=1): $2"
  elif [ -s "$2" ]; then
    echo "  keeping existing file: $2"
  else
    cp "$1" "$2"
    echo "  seeded: $2"
  fi
}

# =================================================================================================
# Default Profile Setup
# =================================================================================================
seed_file /seed/config.yaml /opt/data/config.yaml
seed_file /seed/SOUL.md /opt/data/SOUL.md

# .env is always re-rendered and never seeded-if-absent: it carries secrets and has to be refreshed
# from the Secret on every boot.

touch /opt/data/.env
sed -i '/^DISCORD_/d; /^LITELLM_/d' /opt/data/.env

# The launch profile's own config declares `providers.litellm.key_env: LITELLM_API_KEY`, and under
# multiplexing a profile-scoped lookup miss returns "" instead of falling back to os.environ — so
# without this the aux/vision client resolves no key on every gateway start. Write it from the
# init container's env, which the HelmRelease already sources from the hermes-litellm-key secret.
printf 'LITELLM_API_KEY=%s\n' "$LITELLM_API_KEY" >> /opt/data/.env
chmod 600 /opt/data/.env


# =================================================================================================
# Per-Profile Setup
# =================================================================================================
for f in /seed/profiles.*.config.yaml; do
  name=$(basename "$f" .config.yaml | sed 's/^profiles\.//')
  echo "Seeding profile: $name"

  echo "Ensuring profile dir..."
  mkdir -p "/opt/data/profiles/$name"

  echo "Importing config.yaml..."
  seed_file "$f" "/opt/data/profiles/$name/config.yaml"

  echo "Importing SOUL.md..."
  seed_file "/seed/profiles.$name.SOUL.md" "/opt/data/profiles/$name/SOUL.md"

  # Per-profile .env is always re-rendered from its template, same secrets rule as the default .env.
  echo "Seeding .env file..."
  flux envsubst --strict < "/seed/profiles.$name.env.template" > "/opt/data/profiles/$name/.env"
  chmod 600 "/opt/data/profiles/$name/.env"

  echo "Checking profile contents:"
  ls -la "/opt/data/profiles/$name"

  echo "Seed complete for profile: $name"
done


# =================================================================================================
# Tooling Setup
# =================================================================================================
mkdir -p /opt/data/.local/bin
ln -sfn /opt/mise/mise /opt/data/.local/bin/mise