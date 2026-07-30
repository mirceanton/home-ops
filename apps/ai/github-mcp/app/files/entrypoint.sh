#!/bin/sh
set -eu

TOKEN_FILE=/run/secrets/github-mcp/token
AUTH_CONF=/etc/nginx/dynamic/auth.conf

write_conf() {
  printf 'set $github_mcp_token "Bearer %s";\n' "$1" > "$AUTH_CONF.new"
  mv "$AUTH_CONF.new" "$AUTH_CONF"
}

LAST_TOKEN=$(cat "$TOKEN_FILE")
write_conf "$LAST_TOKEN"

nginx -g 'daemon off;' &
NGINX_PID=$!
trap 'kill -TERM "$NGINX_PID" 2>/dev/null; wait "$NGINX_PID"; exit 0' TERM INT

while kill -0 "$NGINX_PID" 2>/dev/null; do
  sleep 30
  CURRENT_TOKEN=$(cat "$TOKEN_FILE")
  if [ "$CURRENT_TOKEN" != "$LAST_TOKEN" ]; then
    write_conf "$CURRENT_TOKEN"
    nginx -s reload
    LAST_TOKEN="$CURRENT_TOKEN"
  fi
done

wait "$NGINX_PID"
