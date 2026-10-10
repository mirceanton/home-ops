# kubernetes/clusters/public

Bootstrap and Flux resources for the **`public` cluster** — the DMZ cluster that
will front the public services (`mirceanton.com`). `home` is the other cluster in
this repo; both follow the same layout (`bootstrap/` + `apps/`), and
`kubernetes/components/` is shared.

The cluster is brought up **from `talos/zimaboard/`** today: that directory holds
the machine configuration for the single-node lab board that runs this cluster
while the DMZ VLAN (`10.0.20.0/24`, `mikrotik-terraform` branch
`feat/dmz-vlan-port-forward`) is not merged yet.

## Bootstrapping a fresh cluster

1. Install Talos on the node and run `talosctl bootstrap` (see
   `talos/zimaboard/README.md`), then fetch a kubeconfig:
   `talosctl kubeconfig --nodes 10.0.10.195`.
2. Install the CRDs the cluster's apps reference, because Flux cannot apply the
   custom resources before their definitions exist:

   ```shell
   cd kubernetes/clusters/public/bootstrap/crds
   helmfile template -q | yq ea 'select(.kind == "CustomResourceDefinition")' - \
     | kubectl apply --server-side --force-conflicts -f -
   ```

3. Install Cilium, the Flux Operator and the Flux instance:

   ```shell
   cd kubernetes/clusters/public/bootstrap
   helmfile apply
   ```

   `helmfile` reads each release's values straight out of the matching
   `HelmRelease` (`templates/values.yaml.gotmpl`), so the bootstrap and the
   Flux-managed release cannot drift.

4. The Flux instance is pointed at `kubernetes/clusters/public/apps/`
   (`sync.path` in `apps/flux-system/flux-instance/app/helm-release.yaml`), so
   from here on the cluster reconciles itself: `kubectl -n flux-system get
kustomizations` should end up with `cilium`, `flux-operator` and
   `flux-instance` ready and no other sources.

## What is here

- `bootstrap/` — the one-time Helmfile: Cilium (kube-proxy replacement, LB IPAM
  and L2 announcements enabled, no gateway API), Flux Operator and the Flux
  instance. `bootstrap/crds/` extracts CRDs only (Envoy Gateway, so `HTTPRoute`s
  can be applied later, and kube-prometheus-stack, so `PodMonitor`s and
  `PrometheusRule`s are accepted) and is never used with `helmfile apply`.
- `apps/kube-system/` — the CNI.
- `apps/flux-system/` — Flux itself.

## Deliberately not here (yet)

- **The Envoy Gateway controller, the monitoring stack, the LB IP pool and any
  `HTTPRoute`.** The CRDs are installed, but the workloads that use them are not:
  `home`'s Cilium app also carries an `http-route.yaml` (to its `envoy-admin`
  gateway) and `lb-ipam.yaml` (its `10.0.10.250-253` / `10.0.0.250` pools). Both
  are omitted on purpose — this cluster has no gateway yet, and reusing `home`'s
  addresses would announce the same IPs from two clusters on one L2 segment. Add
  a pool for the DMZ subnet once that VLAN exists.
- **`grafana-dashboards.yaml`** (as in `home`'s `flux-instance` app): it needs
  the Grafana Operator CRDs, which this bootstrap does not install.
- **Any workload app.** This cluster is empty apart from Cilium and Flux until
  the DMZ placement lands.

## Prerequisites and open items

- The `sops-age` Secret does not exist in a fresh cluster, but
  `flux-instance` starts `kustomize-controller` with
  `--sops-age-secret=sops-age`. That is inert until the first SOPS-encrypted
  resource lands in `apps/`; create the Secret (from the repo's `age.key`) before
  adding one.
- The Talos side (installer image, NAS registry mirrors, node clock) is described
  in `talos/zimaboard/README.md` — the node needs the NAS `factory.talos.dev`
  pull-through repo before it can install at all.

## Rollback

Nothing here is shared with `home`: to undo the bootstrap, delete the
`flux-system` and `kube-system` Flux `Kustomization`s (or wipe the node),
then remove `kubernetes/clusters/public/`. Reverting the commit is enough for
anything Flux manages; `bootstrap/` itself only touches Cilium and Flux.
