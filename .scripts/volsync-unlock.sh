#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NS="${1:-}"

echo -e "${CYAN}Scanning for VolSync source pods stuck on a stale restic lock...${NC}"

if [ -n "${NS}" ]; then
    PODS=$(kubectl get pods -n "${NS}" --no-headers 2>/dev/null | awk -v ns="${NS}" '{print ns, $1}' | grep ' volsync-src-' || true)
else
    PODS=$(kubectl get pods -A --no-headers 2>/dev/null | awk '{print $1, $2}' | grep ' volsync-src-' || true)
fi

# One "ns app job image" line per locked app (deduplicated below).
LOCKED=""
while read -r POD_NS POD_NAME; do
    [ -z "${POD_NAME}" ] && continue
    LOG=$(kubectl logs -n "${POD_NS}" "${POD_NAME}" -c restic --tail=20 2>/dev/null || true)
    if grep -q "unable to create lock in backend" <<<"${LOG}"; then
        JOB_NAME=$(kubectl get pod -n "${POD_NS}" "${POD_NAME}" -o jsonpath='{.metadata.labels.job-name}' 2>/dev/null || true)
        APP="${JOB_NAME#volsync-src-}"
        [ -z "${APP}" ] && continue
        IMAGE=$(kubectl get pod -n "${POD_NS}" "${POD_NAME}" -o jsonpath='{.spec.containers[?(@.name=="restic")].image}' 2>/dev/null)
        LOCKED="${LOCKED}${POD_NS} ${APP} ${JOB_NAME} ${IMAGE:-quay.io/backube/volsync:0.16.0}
"
    fi
done <<< "${PODS}"

LOCKED=$(echo "${LOCKED}" | sort -u | sed '/^$/d')

if [ -z "${LOCKED}" ]; then
    echo -e "${GREEN}No stale restic locks found.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found stale locks for:${NC}"
echo "${LOCKED}" | while read -r APP_NS APP _ _; do
    echo "  - ${APP_NS}/${APP}"
done

echo "${LOCKED}" | while read -r APP_NS APP JOB_NAME IMAGE; do
    [ -z "${APP_NS}" ] && continue
    UNLOCK_POD="volsync-unlock-${APP}"

    echo -e "${CYAN}[${APP_NS}/${APP}] removing stale lock...${NC}"
    kubectl run "${UNLOCK_POD}" --image="${IMAGE}" --restart=Never -n "${APP_NS}" \
        --overrides="{\"spec\":{\"containers\":[{\"name\":\"unlock\",\"image\":\"${IMAGE}\",\"command\":[\"restic\",\"unlock\",\"--remove-all\"],\"envFrom\":[{\"secretRef\":{\"name\":\"${APP}-volsync-secret\"}}]}]}}" \
        &>/dev/null

    for _ in $(seq 1 30); do
        PHASE=$(kubectl get pod "${UNLOCK_POD}" -n "${APP_NS}" -o jsonpath='{.status.phase}' 2>/dev/null)
        { [ "${PHASE}" = "Succeeded" ] || [ "${PHASE}" = "Failed" ]; } && break
        sleep 2
    done

    kubectl logs "${UNLOCK_POD}" -n "${APP_NS}" 2>&1 | sed "s/^/  /"
    kubectl delete pod "${UNLOCK_POD}" -n "${APP_NS}" --ignore-not-found &>/dev/null

    echo -e "${CYAN}[${APP_NS}/${APP}] deleting stuck job to force a fresh sync...${NC}"
    kubectl delete job "${JOB_NAME}" -n "${APP_NS}" --ignore-not-found &>/dev/null
done

echo -e "${GREEN}Done. VolSync will recreate jobs for the affected apps on its next reconcile.${NC}"
echo -e "${CYAN}Verify with: kubectl get replicationsource -A${NC}"
