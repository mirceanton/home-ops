#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

NS="${1:-}"
TRIGGER="backup-$(date +%Y%m%d-%H%M%S)"

# Discover all ReplicationSources
if [ -n "${NS}" ]; then
    SOURCES=$(kubectl get replicationsource -n "${NS}" \
        -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.namespace}{"\n"}{end}')
else
    SOURCES=$(kubectl get replicationsource -A \
        -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.namespace}{"\n"}{end}')
fi

if [ -z "${SOURCES}" ]; then
    echo -e "${RED}ERROR: No ReplicationSources found${NC}"
    exit 1
fi

echo -e "${CYAN}Triggering backups (trigger=${TRIGGER})...${NC}"

# Launch all backups in parallel
declare -A PIDS
while IFS=' ' read -r APP APP_NS; do
    [ -z "${APP}" ] && continue
    echo "  → ${APP} (${APP_NS})"
    bash "$(dirname "$0")/volsync-backup.sh" "${APP}" "${APP_NS}" "${TRIGGER}" &
    PIDS["${APP}/${APP_NS}"]=$!
done <<< "${SOURCES}"

# Wait and collect results
FAILED=()
for KEY in "${!PIDS[@]}"; do
    if ! wait "${PIDS[$KEY]}"; then
        FAILED+=("${KEY}")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "${RED}Failed backups:${NC}"
    printf '  %s\n' "${FAILED[@]}"
    exit 1
fi

echo -e "${GREEN}All backups completed successfully.${NC}"
