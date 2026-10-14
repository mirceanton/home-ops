#!/bin/sh
set -eu

# Each profile's .env is rendered from the .env.template next to its config.yaml and SOUL.md.
# Profile gateways read secrets through fail-closed per-profile scopes that never fall through
# to container env, so everything a profile needs (DISCORD_ALLOWED_USERS included) must be there.

# busybox ships no envsubst. This is its ${VAR} subset, except that an unset VAR fails the seed
# instead of silently rendering an empty value.
envsubst() {
  awk '{
    out = ""
    while (match($0, /[$][{][A-Za-z_][A-Za-z0-9_]*[}]/)) {
      name = substr($0, RSTART + 2, RLENGTH - 3)
      if (!(name in ENVIRON)) { print "envsubst: " name " is not set" > "/dev/stderr"; exit 1 }
      out = out substr($0, 1, RSTART - 1) ENVIRON[name]
      $0 = substr($0, RSTART + RLENGTH)
    }
    print out $0
  }'
}

cp /seed/config.yaml /opt/data/config.yaml
cp /seed/SOUL.md /opt/data/SOUL.md
# Hermes also writes the default profile's .env itself (setup, dashboard), so merge the
# templated keys into it in place instead of overwriting it.
seed=$(envsubst < /seed/.env.template)
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
  envsubst < "/seed/profiles.$name.env.template" > "/opt/data/profiles/$name/.env"
  chmod 600 "/opt/data/profiles/$name/.env"
  echo "seeded profile: $name"
done

mkdir -p /opt/data/.local/bin
ln -sfn /opt/mise/mise /opt/data/.local/bin/mise
