#!/usr/bin/env bash
set -euo pipefail

APP="$1"
NS="$2"
TRIGGER="$3"
TS="${4:-}"

echo "[1/5] Suspending ${APP} HelmRelease in ${NS}..."
flux suspend helmrelease "${APP}" -n "${NS}"

echo "[2/5] Scaling down application pods for ${APP} in ${NS}..."
kubectl scale deployment -l "app.kubernetes.io/instance=${APP}" -n "${NS}" --replicas=0
kubectl wait pod -l "app.kubernetes.io/instance=${APP}" -n "${NS}" \
    --for=delete --timeout=120s 2>/dev/null || true

echo "[3/5] Patching ReplicationDestination (trigger=${TRIGGER})..."
PATCH="{\"spec\":{\"trigger\":{\"manual\":\"${TRIGGER}\"},\"restic\":{"
if [ -n "${TS}" ]; then
    PATCH="${PATCH}\"restoreAsOf\":\"${TS}\"}}}"
else
    PATCH="${PATCH}\"restoreAsOf\":null}}}"
fi
kubectl patch replicationdestination "${APP}-dst" -n "${NS}" --type merge -p "${PATCH}"

echo "[4/5] Waiting for restore to complete..."
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
    echo "ERROR: Restore failed. Mover logs:"
    kubectl get replicationdestination "${APP}-dst" -n "${NS}" \
        -o jsonpath='{.status.latestMoverStatus.logs}'
    exit 1
fi

echo "[5/5] Resuming HelmRelease ${APP}..."
flux resume helmrelease "${APP}" -n "${NS}"
flux reconcile helmrelease "${APP}" -n "${NS}" --with-source --force
