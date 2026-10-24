#!/bin/sh
set -eu

# =================================================================================================
# Default Profile Setup
# =================================================================================================
cp /seed/config.yaml /opt/data/config.yaml
cp /seed/SOUL.md /opt/data/SOUL.md

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
  cp "$f" "/opt/data/profiles/$name/config.yaml"

  echo "Importing SOUL.md..."
  cp "$f" "/opt/data/profiles/$name/config.yaml"

  echo "Importing SOUL.md..."
  cp "/seed/profiles.$name.SOUL.md" "/opt/data/profiles/$name/SOUL.md"

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
ln -sfn /opt/filmcraft/bin/filmcraft-cli /opt/data/.local/bin/filmcraft-cli
