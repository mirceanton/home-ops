# Skill: Migrate a CNPG-Backed App to a New Namespace

## Overview

CNPG has no in-place migration and no auto-restore-on-bootstrap (unlike VolSync, whose PVC
`dataSourceRef` populator restores automatically on PVC creation). Moving an app's Postgres data
to a new namespace always means: **freeze writes → take a final backup → in one commit, move the
manifests AND configure the new cluster to recover from that backup from its very first
reconcile → push → verify → clean up.**

This was validated end-to-end by migrating `sparkyfitness` from `default` to a dedicated `fitness`
namespace. Two things about that run matter more than anything below: **a suspended Flux
Kustomization does not cascade-prune its resources when deleted**, and **CNPG's `bootstrap` field
is permanently immutable post-creation, not just "don't touch it during recovery."** Both bit us
for real; see Common Pitfalls.

Applies to any app using the shared `components/cnpg` (and, if stateful data beyond the DB exists,
`components/volsync`) pattern.

---

## Step 0: Know what actually needs handling

Check what the app's `${APP}-postgres` `ObjectStore` and (if present) VolSync `ExternalSecret`
point at:

```bash
kubectl get objectstore <app>-postgres-backup -n <src-ns> -o jsonpath='{.spec.configuration.destinationPath}'
```

In this repo, both are keyed **only by `${APP}`, never by namespace** — `s3://.../cnpg/${APP}` and
`s3://.../volsync/${APP}` respectively. That has a real consequence: a freshly-instantiated
`components/cnpg`/`components/volsync` pair in the _new_ namespace automatically points at the
exact same backup history as the old one, with zero extra manifests to write. Confirm this holds
for your setup before assuming it — if it doesn't, you'll need to hand-author matching
`ObjectStore`/`ExternalSecret` resources in the target namespace pointing at the old path.

If the app only touches VolSync-backed storage (no CNPG), you're mostly done: a new
`ReplicationDestination` in the new namespace restores automatically via the PVC populator. The
manual work below is entirely about the CNPG piece.

---

## Step 1: Freeze writes and capture a baseline

```bash
kubectl scale deployment <app-deployments...> -n <src-ns> --replicas=0
```

While pods are down, capture something to diff against later — row counts on a few tables, not
just "pod is Ready":

```bash
kubectl exec -n <src-ns> <app>-postgres-1 -c postgres -- psql -U postgres -d <app> -t -c \
  "SELECT 'sometable', count(*) FROM sometable;"
```

---

## Step 2: Suspend the app's Kustomization, and remember to resume it

```bash
flux suspend kustomization <app> -n <src-ns>
```

**This is the single most important thing to get right in this whole procedure.** You suspend it
so Flux doesn't fight your manual scale-down while you're still working. But when the commit that
moves the manifests lands and the root `flux-system` Kustomization reconciles, it will delete this
Kustomization CR (since it's no longer in the desired resource set for `<src-ns>`) — and in our
run, **that deletion happened while the CR was still suspended, and the finalizer-driven cascade
prune of everything the CR managed (Cluster, HelmRelease, PVCs, ObjectStore, ScheduledBackup,
ExternalSecrets...) simply did not run.** Nothing broke — the old cluster kept running happily,
orphaned — but Flux stopped managing all of it silently, and we only caught it by explicitly
checking `kubectl get cluster -n default` after the "migration" appeared to succeed.

**Resume the Kustomization before or immediately after pushing the move commit**, not after:

```bash
flux resume kustomization <app> -n <src-ns>
```

If you push and reconcile before resuming, check immediately afterward whether the old
Kustomization CR still exists (`flux get kustomization -n <src-ns>`) — if it's already gone, don't
assume its resources were cleaned up. Verify explicitly (Step 6).

---

## Step 3: Take the final backup and wait for it to actually land

```bash
kubectl cnpg backup <app>-postgres -n <src-ns> \
  --backup-name <app>-postgres-migration-final \
  --method=plugin --plugin-name=barman-cloud.cloudnative-pg.io

kubectl get backup <app>-postgres-migration-final -n <src-ns> -w   # wait for phase: completed
```

Then confirm WAL archiving is fully caught up — `kubectl cnpg status <app>-postgres -n <src-ns>`
should show 0 WALs waiting. This backup and everything since the last checkpoint is now durably in
S3, independent of the source PVC's lifecycle — once this is true, the old PVC is disposable no
matter what happens to it next.

If there's a VolSync-backed PVC too, force a fresh sync rather than trusting the schedule:

```bash
kubectl patch replicationsource <app> -n <src-ns> --type merge \
  -p '{"spec":{"trigger":{"manual":"migration-'"$(date +%s)"'"}}}'
# poll status.lastManualSync until it matches what you just set
```

---

## Step 4: Scaffold the new namespace (if it doesn't exist)

Mirror an existing namespace's structure exactly — `apps/<ns>/namespace.yaml` (the `name: _`
placeholder gets rewritten by the sibling `kustomization.yaml`'s top-level `namespace:` field) and
`apps/<ns>/kustomization.yaml` listing `./namespace.yaml` plus the app directory.

---

## Step 5: Move the manifests and configure recovery — in one commit

```bash
git mv apps/<src-ns>/<app> apps/<new-ns>/<app>
```

Update `app.ks.yaml`'s `targetNamespace` and `path`, remove the app from
`apps/<src-ns>/kustomization.yaml`, add it to `apps/<new-ns>/kustomization.yaml`.

In the app's `patches/cnpg.yaml`, override the component's default `bootstrap.initdb` with
`bootstrap.recovery`. This must be present in the **very first** manifest that creates the new
`Cluster` — you cannot create it empty and patch recovery in afterward; `bootstrap` mode is fixed
at creation and CNPG never re-runs it. Use `externalClusters` (not `bootstrap.recovery.backup.name`
— that only works for a `Backup` object in the _same_ namespace, which won't be true here) pointing
directly at the S3 backup catalog by server name:

```yaml
spec:
  bootstrap:
    initdb: null # strategic-merge patches on CRDs use JSON-merge semantics — null deletes the key
    recovery:
      source: origin
      database: ${APP} # defaults to "app"/"app" if omitted — always set explicitly
      owner: ${APP}
  externalClusters:
    - name: origin
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: ${APP}-postgres-backup # the NEW namespace's ObjectStore — same S3 path
          serverName: ${APP}-postgres # the source cluster's name in barman's catalog

  managed:
    roles:
      - name: ${APP}
        ensure: present
        login: true
```

Leave the component's own `plugins:` block alone — it already configures ongoing WAL
archiving/backups for the new cluster against the same `ObjectStore`; `bootstrap.recovery` only
performs the one-time restore.

---

## Step 6: Dry-run render before pushing anything

`kubectl kustomize`/`kustomize build` on the app's `app/` directory **will not work** — the CNPG
and VolSync resources only get included via `components:` at the Flux `Kustomization` level, and
`${APP}` substitution happens through `postBuild.substitute`, not raw Kustomize. Use the real
thing instead:

```bash
flux build kustomization <app> \
  --path ./apps/<new-ns>/<app>/app \
  --kustomization-file ./apps/<new-ns>/<app>/app.ks.yaml \
  --dry-run > /tmp/rendered.yaml

yq eval-all 'select(.kind == "Cluster")' /tmp/rendered.yaml
```

Confirm `bootstrap.initdb` is genuinely absent (not merged alongside `recovery` — CNPG rejects
having both), and that `ObjectStore`'s rendered `destinationPath` matches what Step 0 found for the
source cluster.

Run `task lint:check` too.

---

## Step 7: Commit, push, reconcile, resume

```bash
git add -A && git commit -m "..." && git push
flux reconcile source git flux-system
flux resume kustomization <app> -n <src-ns>   # if not already done in Step 2
```

Watch the new cluster come up:

```bash
kubectl cnpg status <app>-postgres -n <new-ns>
```

A pod named `<app>-postgres-1-full-recovery-...` appearing briefly is CNPG actually running the
recovery job — that's the signal it's working, not a fresh `initdb`.

---

## Step 8: Verify — don't trust "Ready", check data

```bash
kubectl exec -n <new-ns> <app>-postgres-1 -c postgres -- psql -U postgres -d <app> -t -c \
  "SELECT 'sometable', count(*) FROM sometable;"
```

Compare against Step 1's baseline exactly. Also confirm the role has no `superuser` (re-declaring
`managed.roles` is easy to accidentally regress on) and that app pods are actually serving, not
just `Running` — hit a real endpoint, not just readiness.

---

## Step 9: Explicitly check for and clean up orphaned resources in the old namespace

Don't assume pruning worked — verify:

```bash
for kind in cluster database objectstore scheduledbackup externalsecret \
            replicationsource replicationdestination persistentvolumeclaim \
            deployment service helmrelease backup; do
  kubectl get $kind -n <src-ns> 2>&1 | grep -i <app>
done
```

If anything's still there (see Step 2 for why this happens), delete it explicitly in this order —
`HelmRelease` first (cascades to Deployments/Services via helm uninstall), then VolSync objects,
then the `Cluster` (drops its PVCs), then `Database`/`ObjectStore`/`ScheduledBackup`, then
`ExternalSecret`s, then check for leftover PVCs by hand. **The app's own VolSync-backed data PVC
has `kustomize.toolkit.fluxcd.io/prune: disabled` and is never auto-pruned by Flux even when
everything else works correctly** — it always needs an explicit `kubectl delete pvc`, migration or
not.

Deleting the old `ObjectStore` K8s object does not touch the underlying S3 data — the new
cluster's `ObjectStore` (same `destinationPath`) already owns that backup history going forward.

---

## Step 10: Permanently suppress the component's default bootstrap — don't plan to remove it

Once the recovered cluster is verified, you might be tempted to delete the
`bootstrap`/`externalClusters` override, since recovery already happened and won't re-run. **Don't
— test first.** We verified via `kubectl apply --dry-run=server` against the live cluster:

- Reverting to the component's default `bootstrap.initdb` is **rejected**: `The Cluster "..." is
invalid: spec.bootstrap: Forbidden: Only one bootstrap method can be specified at a time`.
- Omitting `bootstrap` entirely (rather than reverting to a different populated value) **is
  accepted**.

So the fix is to keep `bootstrap: null` and `externalClusters: null` in the patch **permanently**,
not as a temporary block to delete later — nulling suppresses the component's `initdb` default for
good, since the field is otherwise unconditionally set upstream. Deleting your override patch
outright would silently reintroduce the forbidden transition the next time Flux reconciles.

Before committing any change like this to an already-bootstrapped cluster, dry-run it against the
live object first:

```bash
kubectl get cluster <app>-postgres -n <new-ns> -o json > /tmp/current.json
# edit /tmp/current.json to match your intended patch result
kubectl apply --dry-run=server -f /tmp/current.json
```

---

## Common Pitfalls

- **Suspending the Kustomization and forgetting to resume it before/around the cutover commit** —
  the finalizer-driven prune of everything it managed does not run while suspended, silently
  orphaning the old namespace's resources. This is the single most consequential mistake possible
  in this procedure — it doesn't fail loudly, it just leaves stale infrastructure running.
- **Trying to patch `bootstrap.recovery` onto an already-`initdb`'d cluster** — rejected, and more
  fundamentally pointless, since CNPG never re-runs bootstrap after creation. The recovery config
  must exist in the manifest from the cluster's very first apply.
- **Assuming you can later delete the recovery override** — you can't just delete it; the
  component's default `bootstrap.initdb` will reassert itself and get rejected by CNPG's webhook.
  Null it out permanently instead.
- **Using `bootstrap.recovery.backup.name`** instead of `externalClusters` — the former needs a
  `Backup` object in the _same namespace_ as the new cluster, which doesn't exist when you're
  migrating namespaces. Use `externalClusters` + `serverName` to read the S3 catalog directly.
- **Forgetting `bootstrap.recovery.database`/`owner`** — defaults to `app`/`app`, not your actual
  database name.
- **`kubectl kustomize` on the app directory alone** — fails or silently omits the CNPG/VolSync
  resources, since those only get wired in via `components:` at the Flux Kustomization level. Use
  `flux build kustomization --dry-run` instead.
- **The app's data PVC (`kustomize.toolkit.fluxcd.io/prune: disabled`)** never gets auto-pruned by
  Flux, migration or not — always requires an explicit manual `kubectl delete pvc` once you're
  certain the new copy is good.
