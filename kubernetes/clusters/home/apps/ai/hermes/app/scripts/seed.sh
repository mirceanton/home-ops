#!/bin/sh
set -eu

# Each profile's .env is rendered from the .env.template next to its config.yaml and SOUL.md.
# Profile gateways read secrets through fail-closed per-profile scopes that never fall through
# to container env, so everything a profile needs must be in its own .env.
# --strict fails the seed on an unset variable instead of rendering an empty value.

cp /seed/config.yaml /opt/data/config.yaml
cp /seed/SOUL.md /opt/data/SOUL.md

# The default profile has no Discord app of its own: bot credentials live in the profile .env
# files now, and everything else the default profile needs is passed through the deployment env.
# Hermes' own setup previously wrote DISCORD_* and LITELLM_API_KEY into the default .env, and
# dotenv values shadow container env (override=True): a stale DISCORD_BOT_TOKEN there would make
# the gateway claim a credential that now belongs to a profile bot (one credential cannot be
# consumed twice) and a stale LITELLM_API_KEY would shadow the rotated envFrom value. Drop both;
# leave every other key Hermes wrote alone.
touch /opt/data/.env
sed -i '/^DISCORD_/d; /^LITELLM_/d' /opt/data/.env
chmod 600 /opt/data/.env

for f in /seed/profiles.*.config.yaml; do
  name=$(basename "$f" .config.yaml | sed 's/^profiles\.//')
  mkdir -p "/opt/data/profiles/$name"
  cp "$f" "/opt/data/profiles/$name/config.yaml"
  cp "/seed/profiles.$name.SOUL.md" "/opt/data/profiles/$name/SOUL.md"
  flux envsubst --strict < "/seed/profiles.$name.env.template" > "/opt/data/profiles/$name/.env"
  chmod 600 "/opt/data/profiles/$name/.env"
  echo "seeded profile: $name"
done

mkdir -p /opt/data/.local/bin
ln -sfn /opt/mise/mise /opt/data/.local/bin/mise
