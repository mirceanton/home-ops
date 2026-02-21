#!/usr/bin/env bash
set -euo pipefail

APP="$1"
NS="$2"
TRIGGER="$3"

echo "[1/2] Triggering backup for ${APP} in ${NS} (trigger=${TRIGGER})..."
kubectl patch replicationsource "${APP}" -n "${NS}" --type merge \
    -p "{\"spec\":{\"trigger\":{\"manual\":\"${TRIGGER}\"}}}"

echo "[2/2] Waiting for backup to complete..."
until [ "$(kubectl get replicationsource "${APP}" -n "${NS}" \
    -o jsonpath='{.status.lastManualSync}' 2>/dev/null)" = "${TRIGGER}" ]; do
    REASON=$(kubectl get replicationsource "${APP}" -n "${NS}" \
        -o jsonpath='{.status.conditions[?(@.type=="Synchronizing")].reason}' 2>/dev/null)
    echo "  status: ${REASON:-Pending}"
    sleep 5
done

RESULT=$(kubectl get replicationsource "${APP}" -n "${NS}" \
    -o jsonpath='{.status.latestMoverStatus.result}')
echo "  result: ${RESULT}"
if [ "${RESULT}" != "Successful" ]; then
    echo "ERROR: Backup failed. Mover logs:"
    kubectl get replicationsource "${APP}" -n "${NS}" \
        -o jsonpath='{.status.latestMoverStatus.logs}'
    exit 1
fi
