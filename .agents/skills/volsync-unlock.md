# Skill: Unlock a Stuck VolSync Backup (Stale Restic Lock)

## Overview

VolSync's restic mover does two things per sync: `backup` (snapshot), then
`forget`/`prune` (retention cleanup) against a shared restic repo — one S3
bucket per app, credentials in `<app>-volsync-secret` in the app's namespace
(`RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`).

If the mover pod is killed mid-`forget` — apiserver flakiness, a node reboot,
an evicted pod, `kubectl delete pod` at the wrong moment — restic leaves a
**lock object in the repo** that is never released. Every subsequent sync then
fails instantly at the forget step with the same error, forever, until someone
clears the lock:

```
repo already locked, waiting up to 0s for the lock
unable to create lock in backend: repository is already locked by PID 43 on volsync-src-<app>-xxxxx by  (UID 0, GID 0)
lock was created at <timestamp>
```

The backup snapshot itself still succeeds (visible in the logs above the lock
error) — only forget/prune fails. The Job retries via `backoffLimit` (8),
exhausts it, VolSync recreates a fresh Job on the next reconcile, and it hits
the same stale lock again. This is a self-sustaining loop; it does not resolve
on its own, and it will not go away by waiting or by retriggering a manual
backup.

Use this skill whenever: volsync-src pods are in `Error`/`CrashLoopBackOff`,
a `ReplicationSource` has been stuck in `Synchronizing`/`SyncInProgress` far
longer than its usual duration, or right after any apiserver flakiness/node
reboot/mass pod eviction (the usual triggers).

---

## Step 1: Scan

```bash
task volsync:unlock
```

This runs `.scripts/volsync-unlock.sh` (no args = all namespaces; pass
`NS=<namespace>` to scope it). It:

1. Finds all `volsync-src-*` pods cluster-wide (or in the given namespace)
2. Greps each pod's `restic` container logs for `unable to create lock in backend`
3. Reports every `namespace/app` currently stuck

To just look without fixing anything:

```bash
kubectl get pods -A | grep volsync-src   # Error / CrashLoopBackOff / stuck Init
kubectl get replicationsource -A         # a LAST SYNC older than the last Kestra backup round is the tell
```

## Step 2: Unlock

`task volsync:unlock` unlocks every locked app it finds automatically. For one
app, run the `homelab.backups/volsync-unlock` flow in Kestra (pick the
`namespace/app` target) — it unlocks and deletes the stuck Job. By hand:

```bash
APP=<app>; NS=<namespace>
IMAGE=quay.io/backube/volsync:0.16.0   # match the version already running in the cluster if unsure

kubectl run volsync-unlock-${APP} --image="${IMAGE}" --restart=Never -n "${NS}" \
  --overrides="{\"spec\":{\"containers\":[{\"name\":\"unlock\",\"image\":\"${IMAGE}\",\"command\":[\"restic\",\"unlock\",\"--remove-all\"],\"envFrom\":[{\"secretRef\":{\"name\":\"${APP}-volsync-secret\"}}]}]}}"

kubectl logs volsync-unlock-${APP} -n "${NS}"   # expect: "successfully removed 1 locks"
kubectl delete pod volsync-unlock-${APP} -n "${NS}"

kubectl delete job volsync-src-${APP} -n "${NS}"  # forces a fresh Job immediately instead of waiting for backoffLimit
```

`--remove-all` is safe here: the repo is per-app and only ever written by that
one ReplicationSource's mover pods, so there's no other process legitimately
holding the lock.

## Step 3: Verify

```bash
kubectl get pods -n <namespace> | grep volsync-src   # should reach Completed
kubectl get replicationsource <app> -n <namespace> -o jsonpath='{.status.latestMoverStatus.result}'
```

`latestMoverStatus` can show a stale `"Failed"` from the _previous_ (locked)
attempt even while a fresh, healthy job is currently running — don't trust it
until the current pod (check `kubectl get pods`) has reached `Completed`.

---

## Common Pitfalls

- Backups are no longer self-scheduled by the `ReplicationSource`s (their cron
  never fires); Kestra's `homelab.backups/volsync-backup-all` triggers them via
  `spec.trigger.manual` at 04:00/16:00, 5 at a time. A failed round shows up as
  a failed Kestra execution, with the mover logs in the per-source
  `volsync-backup` subflow.
- Don't delete the PVC/snapshot or edit `spec.trigger` by hand — the fix is entirely
  at the restic-repo level; nothing in the `ReplicationSource` CR itself is
  wrong.
- If `restic unlock` fails with an auth/network error rather than
  "successfully removed N locks", the underlying S3 endpoint (Garage) may be
  down — check that before assuming the lock logic is the issue.
