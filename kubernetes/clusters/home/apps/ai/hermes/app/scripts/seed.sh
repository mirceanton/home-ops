#!/bin/sh
set -eu

# Each profile's .env is rendered from the .env.template next to its config.yaml and SOUL.md.
# Profile gateways read secrets through fail-closed per-profile scopes that never fall through
# to container env, so everything a profile needs (DISCORD_ALLOWED_USERS included) must be there.
# --strict fails the seed on an unset variable instead of rendering an empty value.

cp /seed/config.yaml /opt/data/config.yaml
cp /seed/SOUL.md /opt/data/SOUL.md
# Hermes also writes the default profile's .env itself (setup, dashboard), so merge the
# templated keys into it in place instead of overwriting it.
seed=$(flux envsubst --strict < /seed/.env.template)
touch /opt/data/.env
printf '%s\n' "$seed" | awk -F= '
  NR == FNR { if (/^[A-Za-z_][A-Za-z0-9_]*=/) { seed[$1] = $0; order[++n] = $1 }; next }
  $1 in seed { print seed[$1]; merged[$1] = 1; next }
  { print }
  END { for (i = 1; i <= n; i++) if (!(order[i] in merged)) print seed[order[i]] }
' - /opt/data/.env > /opt/data/.env.new
mv /opt/data/.env.new /opt/data/.env
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
