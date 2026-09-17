#!/bin/sh
set -eu

KEY_FILE=/run/secrets/trends-mcp/api_key
AUTH_CONF=/etc/nginx/dynamic/auth.conf

write_conf() {
  printf 'set $hasdata_api_key "%s";\n' "$1" > "$AUTH_CONF.new"
  mv "$AUTH_CONF.new" "$AUTH_CONF"
}

# HasData API keys don't rotate like GitHub App installation tokens do, so
# unlike github-mcp's entrypoint this only needs to write the value once
# before nginx starts, not poll and reload on change.
write_conf "$(cat "$KEY_FILE")"

exec nginx -g 'daemon off;'
