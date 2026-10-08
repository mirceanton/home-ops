# talos/zimaboard — ZimaBoard single-node cluster (Talstomize)

Machine configuration for the **ZimaBoard cluster**: a single-node,
controlplane-only Talos cluster running on the board in the test lab, on the
**Services VLAN 1010 (`10.0.10.0/24`, `svc.h.mirceanton.com`)**.

The eventual public placement — **DMZ VLAN 666 (`10.0.20.0/24`)** fronting the
public services (`mirceanton.com`) — is _not_ implemented here: the DMZ VLAN,
its firewall rules and the `WAN:443` port-forward exist only on the unmerged
`mikrotik-terraform` branch `feat/dmz-vlan-port-forward`. Everything below
describes the lab target.

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

Nothing outside this directory has to change for the cluster, and the talhelper
files are untouched (`git status -- talos` shows no changes to them).

> **Still not apply-ready.** The config below is complete and validates clean,
> but applying it depends on two things _outside_ the repo: the CRS326 LAG over
> `ether11`+`ether12` (mikrotik-terraform PR #160, open, needs a maintenance
> window) and the `zimaboard` static DHCP lease that comes with it. See
> "Open items" before running `talstomize apply`.

## Layout

```text
talos/zimaboard/
├── talstomize.yaml       # cluster + node definition, patch layering
├── README.md             # this file
├── talsecret.sops.yaml   # fresh `talosctl gen secrets` bundle, sops-encrypted
└── patches/              # ZimaBoard-only patches (new files)
    ├── allow-scheduling-on-controlplanes.yaml
    ├── cni-none.yaml
    ├── zimaboard-bond.yaml      # 802.3ad bond0 over both NICs
    ├── zimaboard-network.yaml
    ├── zimaboard-sysctls.yaml
    ├── install-disk.yaml
    ├── node-labels.yaml
    ├── admission-control.yaml
    └── etcd-optane-disk.yaml    # PCIe Optane -> /var/lib/etcd
```

`_out/` (talstomize's default output directory: `<node>.yaml` + `talosconfig`)
is gitignored.

## Usage

The tool is pinned in the repository's `.mise.toml`
(`github:mirceanton/talstomize`, with the matching `mise.lock` entry), so:

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
mise exec -- talosctl validate --mode metal -c _out/zimaboard.yaml   # schema check on the render
mise exec -- talstomize diff -f .                  # needs the age key + a reachable node
mise exec -- talstomize apply -f . -- --insecure   # first apply, maintenance mode
```

Notes:

- `talstomize` shells out to `sops` to decrypt `talsecret.sops.yaml` (it must be
  on `PATH`, and `SOPS_AGE_KEY_FILE` must point at the age key) and to `talosctl`
  for `apply`/`diff`. Under mise both come from the repo's `.mise.toml`.
- The installer image is a literal `installer.image`, so `build` needs **no**
  `factory.talos.dev` lookup. It does not need internet access for that reason,
  but the `../patches/registry-mirrors.yaml` env vars below do have to be set.
- The shared `../patches/registry-mirrors.yaml` needs `registry_username` and
  `registry_password` in the environment; the build fails if they are unset.
  That file **is** used here (see below).
- `talstomize build`/`talstomize diff` need a talstomize that understands
  `contractVersion` (see "Talos version and config shape"). The pinned release
  may predate that; check `talstomize version` against the repo pin.

## Target facts (verified on the live board)

| Item           | Value                                                                                                         |
| -------------- | ------------------------------------------------------------------------------------------------------------- |
| Board          | IceWhale ZimaBoard2, Intel N150, 16 GB RAM, BIOS 5.27                                                         |
| Talos          | vanilla metal ISO **v1.14.2**, maintenance mode, **no system extensions**                                     |
| NICs           | `enp1s0` `00:e0:4c:69:db:df` + `enp2s0` `00:e0:4c:69:db:e0` (both Intel I226-V, 1 Gbps)                       |
| Addressing     | bonded `bond0`, DHCP, static lease `10.0.10.195` = `zimaboard` in `dhcp/services`                             |
| Install disk   | `/dev/mmcblk0` (eMMC, 62 GB) — currently holds a stock CasaOS install (destructive)                           |
| etcd disk      | `/dev/nvme0n1` (Optane, INTEL MEMPEK1J016GAD, EUI `5cd2e46433b80100`), 14 GB, empty                           |
| Network egress | **none** from the Services VLAN (no Services→WAN firewall rule) — images come from the NAS                    |
| Access         | Talos API over TCP 50000 on `10.0.10.195` (`--insecure` while in maintenance mode); no BMC, JetKVM unverified |

## Networking

Both NICs are enslaved into one **802.3ad (LACP)** `bond0`
(`patches/zimaboard-bond.yaml`), `enp1s0` first so the bond takes its MAC and
matches the static DHCP lease:

- Switch side: a LAG over `ether11`+`ether12`, untagged Services/PVID 1010
  (mikrotik-terraform `switch-crs326`, PR #160). The module cannot set
  `lacp-rate=1sec`, so the node's `lacpRate: fast` is never matched —
  aggregation still forms, failover detection is slower.
- **Ordering:** apply the node config over the _current_ access ports first,
  and have the switch LAG merged/pushed _after_. An 802.3ad bond carries no
  traffic until the switch side is a LAG, and once those ports are LAG members
  a maintenance-mode ISO is unreachable (no out-of-band access on this board).
- **Fallback** if no switch LAG can be created: `mode: active-backup` (link
  failover, no aggregation, works on two separate access ports) and drop
  `lacpRate`/`xmitHashPolicy`, or leave the NICs unbonded. Either way the "LACP
  group" requirement is not met until the LAG exists.
- **`10.0.10.195` / `10.0.10.196`:** these were the two NICs' individual DHCP
  leases. After bonding there is exactly **one** interface and its address is
  `.195` (the static lease); **`.196` is released**. Both were inside the live
  pool `10.0.10.195-10.0.10.199` with no reservation before this change, which
  is why the `zimaboard` static lease is part of the switch-side PR.
- `zimaboard.svc.h.mirceanton.com` is published from that static lease
  (`match_subdomain`) and is a certificate SAN, together with `10.0.10.195` and
  `127.0.0.1` (KubePrism). The node IP is _not_ added to the SANs
  automatically, and `nodes.zimaboard.ip`, `controlPlaneEndpoint` and the SANs
  must stay in sync.

## Reused patches

These come from `../patches/` unchanged, referenced as `../patches/<file>.yaml`
(paths are resolved relative to `talstomize.yaml`):

| Shared patch                 | Slot                  | Effect                                       |
| ---------------------------- | --------------------- | -------------------------------------------- |
| `host-dns.yaml`              | `patches`             | host DNS, no kube-DNS forwarding             |
| `kubeprism.yaml`             | `patches`             | KubePrism on 7445                            |
| `registry-mirrors.yaml`      | `patches`             | pull every image from the NAS registry       |
| `cluster-discovery.yaml`     | `controlplanePatches` | Kubernetes-registry discovery + node RBAC    |
| `kubelet-tuning.yaml`        | `controlplanePatches` | `maxPods: 200`, `serializeImagePulls: false` |
| `etcd-tuning.yaml`           | `controlplanePatches` | etcd backend batch interval                  |
| `disable-search-domain.yaml` | `controlplanePatches` | `machine.network.disableSearchDomain`        |
| `mutating-admission.yaml`    | `controlplanePatches` | apiserver feature gates                      |
| `disable-kube-proxy.yaml`    | `controlplanePatches` | Cilium replaces kube-proxy                   |

The slot split follows the mapping the audit validated for this cluster
(`test/talstomize-migration` keeps the role-exclusivity split instead, i.e. only
genuinely controlplane-only settings — `cluster.etcd`, `cluster.apiServer` — in
`controlplanePatches`). On a controlplane-only node both render identically.

### Deliberately not reused

- **`talos-api-access.yaml`** — grants Talos API access from the
  `jobs`/`github-actions` namespaces, which only exist on the home-ops cluster.
  Nothing on this node needs it; add a local copy (listing namespaces this
  cluster really has) if that changes.
- **`admission-control.yaml`** — carries talhelper-only escaping (`$$patch:
delete`) that talosctl-style patch decoding rejects, and its delete target
  does not exist in a `talosctl gen config` base. `patches/admission-control.yaml`
  keeps only the `PodNodeSelector` append.
- **`network-binding.yaml`** — pinned to `10.0.0.0/24`; this node is on
  `10.0.10.0/24`. `patches/zimaboard-network.yaml` is the re-pinned copy.
- **`sysctls.yaml`** — renders fine, but is tuned for the home-ops
  Gaming/Sunshine node. `patches/zimaboard-sysctls.yaml` is the trimmed variant.
- **`nvidia.yaml` / `uinput.yaml` / `zfs.yaml`** — kernel-module patches for the
  home-ops node; the ZimaBoard ISO carries no matching extensions.

### `registry-mirrors.yaml` — required, not optional

The node has **no internet egress** (the Services VLAN has no `Services→WAN`
firewall rule; verified live: NTS to `time.cloudflare.com:4460` times out). The
NAS pull-through registry `registry.nas.svc.h.mirceanton.com` (10.0.10.245) is
on the same VLAN, so every mirror in that patch is both reachable and the only
way the installer/CNI/workload images can be pulled. It needs
`registry_username`/`registry_password` in the environment (or a gitignored
`.env`), and every mirror is `skipFallback: true`, so a NAS outage fails pulls
hard instead of silently falling back upstream.

## Added patches

- `allow-scheduling-on-controlplanes.yaml` — the single controlplane node has to
  run workloads.
- `cni-none.yaml` — Cilium comes from the cluster's own bootstrap path (Talos
  installs no CNI and kube-proxy is disabled; the node stays `NotReady` with
  pending CoreDNS pods until Cilium is up — that is expected, not a failure).
- `zimaboard-bond.yaml` — 802.3ad `bond0` over `enp1s0`+`enp2s0`, DHCP.
- `zimaboard-network.yaml` — kubelet/etcd subnet binding + control-plane metrics
  bind addresses (the re-pinned `network-binding.yaml`).
- `zimaboard-sysctls.yaml` — trimmed sysctls.
- `install-disk.yaml` — install target: the eMMC, with `wipe: true` (the disk
  still carries the stock CasaOS install — installing Talos destroys it).
- `node-labels.yaml` — node labels, including the `default-node` label the
  cluster-wide PodNodeSelector depends on.
- `admission-control.yaml` — adapted `PodNodeSelector` append.
- `etcd-optane-disk.yaml` — partitions the PCIe Optane for `/var/lib/etcd`,
  pinned by its stable `/dev/disk/by-id/nvme-eui.5cd2e46433b80100` path. It must
  be in the config _before_ the first `talosctl bootstrap`; moving etcd later
  means re-bootstrapping the single-member etcd. Single-node etcd has quorum 1 —
  worth a `talosctl etcd snapshot` habit.

## Talos version and config shape

The node runs **Talos v1.14.2** (the vanilla metal ISO it boots, no extensions),
and the installer image is pinned to the matching vanilla
`ghcr.io/siderolabs/installer:v1.14.2`.

Every patch in this directory — and the shared `../patches/*` it reuses — is
classic `v1alpha1`-shaped, the shape Talos ≤ v1.13 emits. Talos ≥ v1.14 _reads_
that shape fine but rejects a config that carries both shapes at once, and a
renderer that follows the installer version emits the v1.14 multi-document base
(`KubeletConfig`, `KubePrismConfig`, …) on top of those patches — 14
`talosctl validate` errors such as `.machine.kubelet ... is already set in
v1alpha1 config`. That was the original blocker; it is resolved by pinning the
config shape independently:

```yaml
contractVersion: v1.13.10 # classic shape, keeps ../patches/* valid
installer:
  image: ghcr.io/siderolabs/installer:v1.14.2 # the version the node runs
```

`contractVersion` defaults to `installer.talosVersion` (and, when that is unset,
to the renderer's own machinery), which is exactly why it has to be set
explicitly here: a 1.14.2 node reads a 1.13-shaped config, but the repo's patch
tree cannot be handed the 1.14 shape.

## Open items

| Item                    | State / what is left                                                                                                                                                                                                              |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Switch LAG              | `ether11`+`ether12` LAG (`bond5`) + the `10.0.10.195` static lease for `zimaboard` live in `mikrotik-terraform` PR #160 — open, needs a window.                                                                                   |
| No out-of-band access   | No BMC; the rack JetKVM's attachment to this board is unverified — a bad network config needs physical intervention.                                                                                                              |
| Node clock              | The board's RTC is ~2 h ahead and NTP cannot sync without egress, so `talosctl` TLS verification fails (hence `--insecure`). Fix the RTC or point `machine.time.servers` at a local source before relying on TLS after bootstrap. |
| eMMC contents           | The stock CasaOS install is destroyed by the install (`wipe: true`). Confirm nothing on it matters.                                                                                                                               |
| `default-node` selector | Kept for consistency with home-ops; on a single-node cluster it only adds a way to make nothing schedule. Drop it and the label together if unwanted.                                                                             |
| `maxPods: 200`          | Inherited from the shared `kubelet-tuning.yaml`; 110 is the kubelet default and may suit this board better.                                                                                                                       |
| Cilium bootstrap        | `cni: none` + disabled kube-proxy need a bootstrap path for this cluster (kube-proxy replacement); `bootstrap/` in this repo targets home-ops.                                                                                    |
| Public (DMZ) placement  | Not implemented: needs the `feat/dmz-vlan-port-forward` branch merged (VLAN 666, firewall, `WAN:443` → `10.0.20.250`) and this directory re-pinned to `10.0.20.0/24`.                                                             |

## Validation

| Check                                                                      | Result                                                                                                                                                                                                                                                                                                                                                                                      |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `talstomize build .` (+`talosctl validate --mode metal`, talosctl v1.14.2) | **valid for metal mode** — render carries `endpoint: https://10.0.10.195:6443`, SANs `.195`/FQDN/`127.0.0.1`, `interfaces: [bond0, 802.3ad, dhcp]`, `disks: /dev/disk/by-id/nvme-eui.… → /var/lib/etcd`, `wipe: true`, `cni.name: none`, `allowSchedulingOnControlPlanes: true`, `hostname: zimaboard`, kubelet `nodeIP.validSubnets: 10.0.10.0/24`, etcd `advertisedSubnets: 10.0.10.0/24` |
| `mise exec -- task lint:check` (prettier + actionlint, the repo's CI job)  | passes                                                                                                                                                                                                                                                                                                                                                                                      |

## Related work

- `test/talstomize-migration` — the PoC branch that migrates the **home-ops**
  cluster's own config from talhelper to a `base/` + `clusters/<name>/` layout,
  built against a Talos-version-matched machinery. This directory keeps the same
  role-split and patch conventions but leaves the current `talos/patches/` tree
  in place, per the task that added it.
- `mirceanton/talstomize` PR #22 — the `contractVersion` support this directory
  relies on.
- `mirceanton/mikrotik-terraform` PR #160 — the CRS326 LAG + `zimaboard` DHCP
  lease. (PR #158, the DMZ VLAN/port-forward, belongs to the unmerged public
  placement.)
- `mirceanton/home-ops` PR #1221 (public `envoy-public` Gateway) and PR #1222
  (blog/links workloads) are the cluster-side counterparts of that public
  placement.
