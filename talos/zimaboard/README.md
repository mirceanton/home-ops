# talos/zimaboard — ZimaBoard single-node cluster (Talstomize)

Machine configuration for the **ZimaBoard "public" cluster**: a single-node,
controlplane-only Talos cluster that lives in the **DMZ VLAN 666
(`10.0.20.0/24`)** and fronts the public services (`mirceanton.com`).

This directory is rendered by [talstomize](https://github.com/mirceanton/talstomize)
and is **completely separate** from the talhelper-managed configuration one
level up:

|                | `talos/` (root)       | `talos/zimaboard/` (this directory)           |
| -------------- | --------------------- | --------------------------------------------- |
| Tool           | talhelper             | talstomize                                    |
| Cluster        | `home-ops`            | `zimaboard`                                   |
| Entrypoint     | `talconfig.yaml`      | `talstomize.yaml`                             |
| Secrets        | `talsecret.sops.yaml` | `talsecret.sops.yaml` (own bundle)            |
| Shared patches | `patches/`            | reused read-only via `../patches/<name>.yaml` |

Nothing outside this directory had to change to add the cluster, and the
talhelper files are untouched (`git status -- talos` shows no changes to them).

> **This is not apply-ready yet.** Two things have to be decided first: the
> placeholder values in "Placeholders that need a decision", and the Talos
> version / patch-shape question in "Blocker: Talos version vs patch shape" —
> which as rendered today makes the config unusable by any node. Both are
> documented with their evidence below.

## Layout

```text
talos/zimaboard/
├── talstomize.yaml       # cluster + node definition, patch layering
├── README.md             # this file
├── talsecret.sops.yaml   # fresh `talosctl gen secrets` bundle, sops-encrypted
└── patches/              # ZimaBoard-only patches (new files)
    ├── allow-scheduling-on-controlplanes.yaml
    ├── cni-none.yaml
    ├── zimaboard-network.yaml
    ├── zimaboard-sysctls.yaml
    ├── install-disk.yaml
    ├── node-labels.yaml
    ├── admission-control.yaml
    └── etcd-optane-disk.yaml   # opt-in, not referenced yet
```

`_out/` (talstomize's default output directory: `<node>.yaml` + `talosconfig`)
is gitignored.

## Usage

The tool is pinned in the repository's `.mise.toml`
(`github:mirceanton/talstomize` → `v0.1.0-rc.2`, with the matching `mise.lock`
entry), so:

```shell
mise exec -- talstomize --help
```

`build` renders without touching a node, `diff` compares against the live node
and `apply` writes the rendered config to it:

```shell
cd talos/zimaboard

# either export the registry credentials, or put them in a gitignored .env
# (talstomize loads ./.env automatically; `.env` is already in .gitignore)
export registry_username=... registry_password=...

mise exec -- talstomize build .                    # -> ./_out/zimaboard.yaml + ./_out/talosconfig
mise exec -- talstomize diff -f .                  # needs the age key + a reachable node
mise exec -- talstomize apply -f . -- --insecure   # first apply, maintenance mode
```

Notes:

- `talstomize` shells out to `sops` to decrypt `talsecret.sops.yaml` (it must be
  on `PATH`, and `SOPS_AGE_KEY_FILE` must point at the age key) and to `talosctl`
  for `apply`/`diff`. Under mise both come from the repo's `.mise.toml`.
- `build` resolves `installer.schematic` against `factory.talos.dev`, so it needs
  network access. Setting `installer.image` instead avoids that.
- The shared `../patches/registry-mirrors.yaml` needs `registry_username` and
  `registry_password` in the environment; the build fails if they are unset.
  That file is **not** used here (see below), but keep the habit for the
  home-ops cluster.

## Secrets

`talsecret.sops.yaml` is a **fresh bundle for this cluster** — `talosctl gen
secrets` output encrypted with the repository's age recipient, exactly like the
home-ops one. It must never be replaced by `../talsecret.sops.yaml`: that is the
home-ops cluster's key material.

To rotate/regenerate:

```shell
cd talos/zimaboard
talosctl gen secrets -o talsecret.yaml
sops --encrypt talsecret.yaml > talsecret.sops.yaml   # .sops.yaml rule matches by path
rm talsecret.yaml
```

## Reused patches

These come from `../patches/` unchanged, referenced as `../patches/<file>.yaml`
(paths are resolved relative to `talstomize.yaml`):

| Shared patch                 | Slot                  | Effect                                       |
| ---------------------------- | --------------------- | -------------------------------------------- |
| `cluster-discovery.yaml`     | `patches`             | Kubernetes-registry discovery + node RBAC    |
| `kubelet-tuning.yaml`        | `patches`             | `maxPods: 200`, `serializeImagePulls: false` |
| `disable-search-domain.yaml` | `patches`             | `machine.network.disableSearchDomain`        |
| `host-dns.yaml`              | `patches`             | host DNS, no kube-DNS forwarding             |
| `kubeprism.yaml`             | `patches`             | KubePrism on 7445                            |
| `disable-kube-proxy.yaml`    | `patches`             | Cilium replaces kube-proxy                   |
| `talos-api-access.yaml`      | `patches`             | Talos API access for `os:admin`              |
| `etcd-tuning.yaml`           | `controlplanePatches` | etcd backend batch interval                  |
| `mutating-admission.yaml`    | `controlplanePatches` | apiserver feature gates                      |

Patches are placed by role-exclusivity, the same split the
`test/talstomize-migration` branch uses: only genuinely controlplane-only
settings (`cluster.etcd`, `cluster.apiServer`) sit in `controlplanePatches`,
everything a worker would also need sits in `patches`. On this
controlplane-only cluster the rendered result is the same either way, but it
stays correct if a worker is ever added.

### Deliberately not reused

- **`registry-mirrors.yaml`** — every mirror points at
  `registry.nas.svc.h.mirceanton.com` (Services VLAN) with `skipFallback: true`.
  The DMZ is isolated from all other VLANs, so the mirror is unreachable and
  image pulls would fail _instead of_ falling back to the upstream registries.
  The node pulls straight from the internet instead.
- **`network-binding.yaml`** — pinned to `10.0.0.0/24`; this node is on
  `10.0.20.0/24`. `patches/zimaboard-network.yaml` is the re-pinned copy.
- **`admission-control.yaml`** — carries talhelper-only escaping (`$$patch:
delete`) that talosctl-style patch decoding rejects, and its delete target
  does not exist in a `talosctl gen config` base. `patches/admission-control.yaml`
  keeps only the `PodNodeSelector` append.
- **`sysctls.yaml`** — renders fine, but is tuned for the home-ops
  Gaming/Sunshine node. `patches/zimaboard-sysctls.yaml` is the trimmed variant.
- **`nvidia.yaml` / `uinput.yaml` / `zfs.yaml`** — kernel-module patches for the
  home-ops node; only relevant if the matching Image Factory extensions are
  installed here.

## Added patches

- `allow-scheduling-on-controlplanes.yaml` — the single controlplane node has to
  run workloads.
- `cni-none.yaml` — Cilium comes from the bootstrap helmfile.
- `zimaboard-network.yaml` — kubelet/etcd subnet binding + control-plane metrics
  bind addresses (the re-pinned `network-binding.yaml`).
- `zimaboard-sysctls.yaml` — trimmed sysctls.
- `install-disk.yaml` — install target (eMMC).
- `node-labels.yaml` — node labels, including the `default-node` label the
  cluster-wide PodNodeSelector depends on.
- `admission-control.yaml` — adapted `PodNodeSelector` append.
- `etcd-optane-disk.yaml` — **opt-in, not referenced yet**: partitions the PCIe
  Optane SSD for `/var/lib/etcd`, mirroring the home-ops node. Enable it in
  `talstomize.yaml` once the disk is installed and the device name confirmed.

## Placeholders that need a decision

Every value below renders as-is but must be confirmed before the config is
applied to real hardware:

| Value                | Currently                        | Evidence / what to decide                                                                                                                                                                                                                               |
| -------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Subnet               | `10.0.20.0/24`                   | DMZ VLAN 666 in `mikrotik-terraform` (`dhcp/dmz`, `globals.hcl`)                                                                                                                                                                                        |
| Node IP / endpoint   | `10.0.20.195`                    | Node takes a DMZ **DHCP** address (pool `.195-.249`). Reserve a static lease — like `home-ops` at `10.0.0.15` — and keep `nodes.zimaboard.ip`, `controlPlaneEndpoint` and the SANs in sync. `.250` is the `envoy-public` LoadBalancer IP, not the node. |
| FQDN                 | `zimaboard.dmz.h.mirceanton.com` | DOMAIN of the DMZ DHCP server. Needs a named lease/DNS record to resolve.                                                                                                                                                                               |
| Install disk         | `/dev/mmcblk0`                   | eMMC. The board also has dual SATA + a PCIe slot; the planned layout keeps Talos on the eMMC and uses those for etcd/PVs.                                                                                                                               |
| Extensions           | `iscsi-tools`, `zfs`             | ZimaBoard's own driver set; drop the block for a plain `installer.image` if no extension is needed.                                                                                                                                                     |
| `default-node` label | enabled                          | Required while `patches/admission-control.yaml` sets the cluster-wide selector — without it nothing schedules. Drop both together if the selector is not wanted here.                                                                                   |
| `maxPods`            | `200`                            | Inherited from the shared `kubelet-tuning.yaml`; 110 is the kubelet default and might suit this board better.                                                                                                                                           |
| Extra NICs / VLANs   | none                             | The node DHCPs onto its NIC, so the DMZ port must be an untagged access port. A bond/VLAN setup would need a `machine.network.interfaces` patch (talstomize has no `networkInterfaces` field).                                                          |
| Talos version        | `v1.13.10`                       | `installer.talosVersion` only tags the installer image — it does **not** change the config schema the generator emits. See the blocker below.                                                                                                           |

## Blocker: Talos version vs patch shape

Reproduced while adding this directory (talstomize `0.1.0-rc.2`, talosctl
`v1.14.2` and `v1.13.10`):

1. The released talstomize binary is built against Talos machinery **v1.14.0**
   (its build metadata names `github.com/siderolabs/talos/pkg/machinery
v1.14.0`), so the base config it generates has the **v1.14 shape**: the
   Kubernetes settings live in documents of their own (`KubeletConfig`,
   `KubeNetworkConfig`, `KubeFlannelCNIConfig`, `KubeProxyConfig`,
   `KubePrismConfig`, `KubeAPIServerConfig`, `KubeAdmissionControlConfig`, ...).
2. The shared `../patches/*` files — like the whole talhelper configuration they
   belong to — are **v1alpha1-field shaped**, which is what Talos **≤ v1.13**
   expects. Talos **≥ v1.14 rejects a config that carries both shapes** for the
   same setting.
3. Both halves of that mismatch show up on the rendered `_out/zimaboard.yaml`:

```text
talosctl v1.14.2 validate --mode metal -> 14 errors occurred:
  * discovery service is already configured in .cluster.discovery of the v1alpha1 config
  * .machine.network.disableSearchDomain is already set in v1alpha1 config
  * .cluster.allowSchedulingOnControlPlanes is already set in v1alpha1 config
  * kubelet config is already set in v1alpha1 config (.machine.kubelet)
  * cluster network config is already set in the v1alpha1 config ... use only the new KubeNetworkConfig document
  * KubePrism config in v1alpha1 config (.machine.features.kubePrism) can't be used with KubePrismConfig document
  * admission control plugin config is already set in v1alpha1 config (x3)
  * kube-apiserver / kube-controller-manager / kube-scheduler config is already set in v1alpha1 config
  * cluster proxy config in v1alpha1 config (.machine.cluster.proxy) can't be used with KubeProxyConfig document
  * cluster network config in v1alpha1 config (.machine.cluster.network) can't be used with KubeFlannelCNIConfig document

talosctl v1.13.10 validate --mode metal -> error decoding document
  v1alpha1/DiscoveryServiceConfig/default: "DiscoveryServiceConfig" "v1alpha1": not registered
```

As rendered today the config is refused by a v1.14 node and cannot even be
decoded by a v1.13 node. Two ways out, and the choice is a human decision:

1. **Stay on Talos v1.13.x** (consistent with the home-ops cluster) and render
   with a talstomize built against machinery v1.13.10 — which is what
   `test/talstomize-migration` does (a local build against v1.13.8). The
   `../patches/*` references in this directory then work unchanged and nothing
   else here needs to change.
2. **Move this node to Talos ≥ v1.14** and restate the patches in document form.
   Upstream's v1.14 patch examples for the settings involved:

   ```yaml
   apiVersion: v1alpha1
   kind: KubeFlannelCNIConfig # replaces cluster.network.cni.name: none
   $patch: delete
   ---
   apiVersion: v1alpha1
   kind: KubeProxyConfig # replaces cluster.proxy.disabled
   enabled: false
   ---
   apiVersion: v1alpha1
   kind: KubeNodeConfig # replaces machine.kubelet.nodeIP
   nodeIP:
     validSubnets:
       - 10.0.20.0/24
   ---
   apiVersion: v1alpha1
   kind: KubeletConfig # replaces machine.kubelet.extraConfig
   extraConfig:
     maxPods: 200
   ---
   apiVersion: v1alpha1
   kind: KubeNetworkConfig # replaces cluster.network / cluster.discovery
   dnsDomain: cluster.local
   ```

   plus the matching documents for the remaining entries in the error list
   (`KubePrismConfig`, `KubeAPIServerConfig`, `KubeControllerManagerConfig`,
   `KubeSchedulerConfig`, `KubeAdmissionControlConfig`, discovery) and
   `installer.talosVersion` bumped to the same v1.14.x.

Until one of those is chosen: **do not `talstomize apply` this directory**, and
do not build an ISO from the rendered config either.

## Validation

What was actually run while adding this directory:

| Check                                                                           | Result                                                                                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `talstomize build .` on a copy of these files, shared patches included          | renders `_out/zimaboard.yaml` + `_out/talosconfig`; schematic resolves to `factory.talos.dev/metal-installer/98c912e2…:v1.13.10`                                                                                                                                                       |
| sops round trip through talstomize's own decrypt path (disposable test age key) | decrypts and renders — the bundle format and the `secrets:` wiring are correct                                                                                                                                                                                                         |
| Rendered config spot checks                                                     | `cni.name: none`, `allowSchedulingOnControlPlanes: true`, `kubelet.nodeIP.validSubnets`, `install.disk` + factory image, `sysctls`, `nodeLabels` (incl. `default-node`), `etcd.advertisedSubnets`, PodNodeSelector append, `hostname: zimaboard`, `endpoint: https://10.0.20.195:6443` |
| `talosctl validate --mode metal` (v1.14.2 and v1.13.10)                         | **fails** — see "Blocker" above                                                                                                                                                                                                                                                        |
| `mise exec -- task lint:check` (prettier + actionlint, the repo's CI job)       | passes                                                                                                                                                                                                                                                                                 |

## Related work

- `test/talstomize-migration` — the PoC branch that migrates the **home-ops**
  cluster's own config from talhelper to a `base/` + `clusters/<name>/` layout,
  built against a Talos-version-matched machinery. This directory keeps the same
  role-split and patch conventions but leaves the current `talos/patches/` tree
  in place, per the task that added it.
- `mirceanton/home-ops` PR #1221 (public `envoy-public` Gateway on the DMZ) and
  PR #1222 (blog/links workloads) are the cluster-side counterparts;
  `mirceanton/mikrotik-terraform` PR #158 created the DMZ VLAN and the single
  WAN `443` port-forward to `10.0.20.250`.
