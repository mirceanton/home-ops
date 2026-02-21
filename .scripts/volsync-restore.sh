#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

APP="$1"
NS="$2"
TRIGGER="$3"
TS="${4:-}"

echo -e "${CYAN}[1/5] Suspending ${APP} HelmRelease in ${NS}...${NC}"
flux suspend helmrelease "${APP}" -n "${NS}"

echo -e "${CYAN}[2/5] Scaling down application pods for ${APP} in ${NS}...${NC}"
kubectl scale deployment -l "app.kubernetes.io/instance=${APP}" -n "${NS}" --replicas=0
kubectl wait pod -l "app.kubernetes.io/instance=${APP}" -n "${NS}" \
    --for=delete --timeout=120s 2>/dev/null || true

echo -e "${CYAN}[3/5] Patching ReplicationDestination (trigger=${TRIGGER})...${NC}"
PATCH="{\"spec\":{\"trigger\":{\"manual\":\"${TRIGGER}\"},\"restic\":{"
if [ -n "${TS}" ]; then
    PATCH="${PATCH}\"restoreAsOf\":\"${TS}\"}}}"
else
    PATCH="${PATCH}\"restoreAsOf\":null}}}"
fi
kubectl patch replicationdestination "${APP}-dst" -n "${NS}" --type merge -p "${PATCH}"

echo -e "${CYAN}[4/5] Waiting for restore to complete...${NC}"
until [ "$(kubectl get replicationdestination "${APP}-dst" -n "${NS}" \
    -o jsonpath='{.status.lastManualSync}' 2>/dev/null)" = "${TRIGGER}" ]; do
    REASON=$(kubectl get replicationdestination "${APP}-dst" -n "${NS}" \
        -o jsonpath='{.status.conditions[?(@.type=="Synchronizing")].reason}' 2>/dev/null)
    echo "  status: ${REASON:-Pending}"
    sleep 5
done

RESULT=$(kubectl get replicationdestination "${APP}-dst" -n "${NS}" -o jsonpath='{.status.latestMoverStatus.result}')
echo "  result: ${RESULT}"
if [ "${RESULT}" != "Successful" ]; then
    echo -e "${RED}ERROR: Restore failed. Mover logs:${NC}"
    kubectl get replicationdestination "${APP}-dst" -n "${NS}" \
        -o jsonpath='{.status.latestMoverStatus.logs}'
    exit 1
fi

echo -e "${CYAN}[5/5] Resuming HelmRelease ${APP}...${NC}"
flux resume helmrelease "${APP}" -n "${NS}"
flux reconcile helmrelease "${APP}" -n "${NS}" --with-source --force
