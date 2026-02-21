#!/usr/bin/env bash
set -euo pipefail

APP="$1"
NS="$2"

kubectl run volsync-snapshots-${APP} --restart=Never \
    --image=restic/restic:latest \
    -n "${NS}" \
    --overrides="{
      \"spec\": {
        \"containers\": [{
          \"name\": \"restic\",
          \"image\": \"restic/restic:latest\",
          \"args\": [\"snapshots\"],
          \"envFrom\": [{\"secretRef\": {\"name\": \"${APP}-volsync-secret\"}}]
        }]
      }
    }" &>/dev/null

# Wait for pod to finish, checking every 2s for bad states (timeout 60s)
for i in $(seq 1 30); do
    PHASE=$(kubectl get pod/volsync-snapshots-${APP} -n "${NS}" \
        -o jsonpath='{.status.phase}' 2>/dev/null)
    WAITING=$(kubectl get pod/volsync-snapshots-${APP} -n "${NS}" \
        -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
    if [ "${PHASE}" = "Succeeded" ]; then
        break
    elif [ "${PHASE}" = "Failed" ] || ([ -n "${WAITING}" ] && [ "${WAITING}" != "ContainerCreating" ]); then
        echo "ERROR: Pod failed to start (phase=${PHASE:-Pending}, reason=${WAITING:-unknown})"
        kubectl delete pod/volsync-snapshots-${APP} -n "${NS}" --ignore-not-found &>/dev/null
        exit 1
    fi
    sleep 2
done

kubectl logs pod/volsync-snapshots-${APP} -n "${NS}"
kubectl delete pod/volsync-snapshots-${APP} -n "${NS}" --ignore-not-found &>/dev/null
