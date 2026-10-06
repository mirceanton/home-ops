#!/bin/sh
set -eu

cp /seed/config.yaml /opt/data/config.yaml
cp /seed/SOUL.md /opt/data/SOUL.md
if grep -q '^LITELLM_API_KEY=' /opt/data/.env 2>/dev/null; then
  sed -i "s|^LITELLM_API_KEY=.*|LITELLM_API_KEY=$LITELLM_API_KEY|" /opt/data/.env
else
  printf 'LITELLM_API_KEY=%s\n' "$LITELLM_API_KEY" >> /opt/data/.env
fi
# The Discord allowlist gate reads DISCORD_ALLOWED_USERS through the fail-closed per-profile
# secret scope (multiplex), which never falls through to container env, so seed it here too.
if grep -q '^DISCORD_ALLOWED_USERS=' /opt/data/.env 2>/dev/null; then
  sed -i "s|^DISCORD_ALLOWED_USERS=.*|DISCORD_ALLOWED_USERS=$DISCORD_ALLOWED_USERS|" /opt/data/.env
else
  printf 'DISCORD_ALLOWED_USERS=%s\n' "$DISCORD_ALLOWED_USERS" >> /opt/data/.env
fi
chmod 600 /opt/data/.env

for f in /seed/profiles.*.config.yaml; do
  name=$(basename "$f" .config.yaml | sed 's/^profiles\.//')
  mkdir -p "/opt/data/profiles/$name"
  cp "$f" "/opt/data/profiles/$name/config.yaml"
  cp "/seed/profiles.$name.SOUL.md" "/opt/data/profiles/$name/SOUL.md"
  {
    printf 'LITELLM_API_KEY=%s\n' "$LITELLM_API_KEY"
    printf 'DISCORD_ALLOWED_USERS=%s\n' "$DISCORD_ALLOWED_USERS"
  } > "/opt/data/profiles/$name/.env"
  chmod 600 "/opt/data/profiles/$name/.env"
  echo "seeded profile: $name"
done

mkdir -p /opt/data/.local/bin
ln -sfn /opt/mise/mise /opt/data/.local/bin/mise
