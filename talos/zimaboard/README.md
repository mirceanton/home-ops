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
and is **completely separate** from the talhelper-managed configuration one level
up: `talos/talconfig.yaml` is cluster `home-ops`, this directory is cluster
`zimaboard`, with its own `talstomize.yaml` entrypoint, its own
`talsecret.sops.yaml` bundle and its own `patches/`. Nothing outside this
directory has to change for the cluster, and the talhelper files are untouched.

**Every patch is a local file under `patches/`.** The cluster does not reference
`../patches/` (the home-ops tree) at all: the nine generic patches it uses are
copies kept byte-identical to the home-ops originals, so the `home-ops`-side
reorganisation and the planned talstomize/1.14 migration cannot break this
render, and moving this directory into a multi-cluster layout later is a plain
`git mv`.

> **Still not apply-ready — one external dependency left.** The config renders,
> validates and is accepted by the live node, but building it needs the **NAS
> registry credentials** (`registry_username`/`registry_password`) in the
> environment. The Services VLAN has no internet egress and the NAS pull-through
> registry rejects anonymous pulls, so without them neither the render nor a
> single image pull on the node can succeed. See "Open items".

## Layout

```text
talos/zimaboard/
├── talstomize.yaml       # cluster + node definition, patch layering
├── README.md             # this file
├── talsecret.sops.yaml   # fresh `talosctl gen secrets` bundle, sops-encrypted
└── patches/              # every patch this cluster uses, nothing shared
    ├── admission-control.yaml                 # PodNodeSelector append
    ├── allow-scheduling-on-controlplanes.yaml
    ├── cluster-discovery.yaml
    ├── cni-none.yaml
    ├── disable-kube-proxy.yaml
    ├── disable-search-domain.yaml
    ├── etcd-optane-disk.yaml                  # PCIe Optane -> /var/lib/etcd
    ├── etcd-tuning.yaml
    ├── host-dns.yaml
    ├── install-disk.yaml
    ├── kubeprism.yaml
    ├── kubelet-tuning.yaml
    ├── mutating-admission.yaml
    ├── node-labels.yaml
    ├── registry-mirrors.yaml                  # NAS pull-through mirrors
    ├── zimaboard-bond.yaml                    # bond0 over both NICs
    ├── zimaboard-network.yaml
    └── zimaboard-sysctls.yaml
```

`_out/` (talstomize's default output directory: `<node>.yaml` + `talosconfig`)
is gitignored.

## Usage

```shell
cd talos/zimaboard

# either export the registry credentials, or put them in a gitignored .env
# (talstomize loads ./.env automatically; `.env` is already in .gitignore)
export registry_username=... registry_password=...

mise exec -- talstomize build .                    # -> ./_out/zimaboard.yaml + ./_out/talosconfig
mise exec -- talosctl validate --mode metal -c _out/zimaboard.yaml   # schema check on the render
mise exec -- talosctl apply-config --insecure -n 10.0.10.195 -e 10.0.10.195 --dry-run -f _out/zimaboard.yaml
mise exec -- talstomize apply -f . -- --insecure   # first apply, maintenance mode (DESTRUCTIVE, see below)
```

- `talstomize` shells out to `sops` to decrypt `talsecret.sops.yaml` (it must be
  on `PATH`, with `SOPS_AGE_KEY_FILE` pointing at the age key) and to `talosctl`
  for `apply`/`diff`.
- The installer image is a literal `installer.image`, so `build` needs **no**
  `factory.talos.dev` lookup and no internet access of its own.
- `patches/registry-mirrors.yaml` needs `registry_username` and
  `registry_password` in the environment; the build fails if they are unset.
- `build`/`diff` need a talstomize that understands `contractVersion` (see
  "Talos version and config shape"). The version pinned in the root `.mise.toml`
  still predates it — until a release with `mirceanton/talstomize#22` is tagged,
  build one from a checkout of that project
  (`go build -o ./talstomize ./cmd/talstomize`).

## Target facts (verified on the live board)

- **Board**: IceWhale ZimaBoard2, Intel N150, 16 GB RAM, BIOS 5.27.
- **Talos**: vanilla metal ISO **v1.14.2**, maintenance mode, **no system
  extensions**.
- **NICs**: `enp1s0` `00:e0:4c:69:db:df` and `enp2s0` `00:e0:4c:69:db:e0` (both
  Intel I226-V, 1 Gbps), both plain untagged Services access ports today.
- **Addresses**: both NICs hold their own DHCP lease — `10.0.10.195` on
  `enp1s0`, `10.0.10.196` on `enp2s0` — out of the Services pool
  `10.0.10.195-10.0.10.199`, with no reservation.
- **Install disk**: `/dev/mmcblk0` (eMMC, 62 GB) — still holds a stock CasaOS
  install (destructive).
- **etcd disk**: `/dev/nvme0n1` (Optane, INTEL MEMPEK1J016GAD, EUI
  `5cd2e46433b80100`), 14 GB, empty, no partitions.
- **Network egress**: none from the Services VLAN (there is no `Services→WAN`
  firewall rule) — every image has to come from the NAS.
- **Access**: Talos API on TCP 50000 at `10.0.10.195` (`--insecure` while in
  maintenance mode); no BMC, the JetKVM attachment is unverified.
- **Time**: `TimeStatus.synced=false`; the RTC is ~3 h ahead of real UTC and NTS
  cannot reach `time.cloudflare.com`.

## Networking

Both NICs are enslaved into one **`bond0`** (`patches/zimaboard-bond.yaml`) with
**`mode: active-backup`**, `enp1s0` listed first so the bond takes its MAC and
keeps the address that MAC already holds.

- **LACP (802.3ad) is deliberately deferred.** The matching LAG is a switch-side
  change (`bond5` over `ether11`+`ether12`, untagged Services/PVID 1010) that
  only exists in the unmerged `mikrotik-terraform` PR #160, and an 802.3ad bond
  carries **no traffic at all** without a LACP partner: applying it against the
  current plain access ports would take the board off the network permanently,
  and this board has no out-of-band access.
- `active-backup` needs nothing on the switch side — one active slave carries
  traffic, the other is a live standby for link failover (no aggregation, no
  LACP). When the LAG lands, flipping to 802.3ad is `mode` plus
  `lacpRate`/`xmitHashPolicy`. **Ordering matters: node config over the current
  access ports first, switch LAG second — never the reverse.**
- **`.195` / `.196`**: a bond carries exactly **one** address, so the node keeps
  `10.0.10.195` (the address its `enp1s0` MAC already holds) and **`.196` is
  released**. The `zimaboard` static lease in `mikrotik-terraform`
  (`dhcp/services`, PR #160) pins `.195` to that MAC and publishes
  `zimaboard.svc.h.mirceanton.com` (`match_subdomain`) with it.
- `10.0.10.195`, `zimaboard.svc.h.mirceanton.com` and `127.0.0.1` (KubePrism) are
  certificate SANs. The node IP is _not_ added automatically, and
  `nodes.zimaboard.ip`, `controlPlaneEndpoint` and the SANs must stay in sync.
- **Bond fallback** if the bond itself ever misbehaves: give `enp1s0` its own
  `dhcp: true` entry, drop the `bond0` entry, and leave `enp2s0` unconfigured.

## Patches

Every patch is local to this directory. The nine generic ones are copies of the
home-ops `talos/patches/*` files, kept verbatim so a diff against the home-ops
tree stays reviewable:

- `patches/` (applied to every node): `host-dns.yaml`, `kubeprism.yaml`,
  `registry-mirrors.yaml`.
- `controlplanePatches/` (before the node's own patches):
  `cluster-discovery.yaml`, `kubelet-tuning.yaml`, `etcd-tuning.yaml`,
  `disable-search-domain.yaml`, `mutating-admission.yaml`,
  `disable-kube-proxy.yaml`.
- Node-specific (`nodes.zimaboard.patches`): `zimaboard-bond.yaml`,
  `zimaboard-network.yaml`, `install-disk.yaml`, `node-labels.yaml`,
  `etcd-optane-disk.yaml`.
- ZimaBoard-adapted: `zimaboard-network.yaml` (the home-ops `network-binding.yaml`
  re-pinned from `10.0.0.0/24` to `10.0.10.0/24`), `zimaboard-sysctls.yaml`
  (trimmed: the home-ops `sysctls.yaml` is tuned for the Gaming/Sunshine node),
  `admission-control.yaml` (the home-ops file carries talhelper-only escaping
  that talosctl-style patch decoding rejects; only the `PodNodeSelector` append
  is kept).

The slot split follows the mapping the audit validated for this cluster
(`test/talstomize-migration` keeps the role-exclusivity split instead, i.e. only
genuinely controlplane-only settings — `cluster.etcd`, `cluster.apiServer` — in
`controlplanePatches`). On a controlplane-only node both render identically;
aligning the split is worth doing when a worker node is ever added.

Deliberately **not** carried over:

- `talos-api-access.yaml` — grants Talos API access from the `jobs`/
  `github-actions` namespaces, which only exist on the home-ops cluster. Add a
  local copy listing this cluster's namespaces if that ever changes.
- `nvidia.yaml`, `uinput.yaml`, `zfs.yaml` — kernel-module patches for the
  home-ops node; the ZimaBoard ISO carries no matching extensions.

Other ZimaBoard-local patches:

- `allow-scheduling-on-controlplanes.yaml` — the single controlplane has to run
  workloads.
- `cni-none.yaml` — Cilium comes from the cluster's own bootstrap path. Talos
  installs no CNI and kube-proxy is disabled, so the node stays `NotReady` with
  pending CoreDNS pods until Cilium is up: expected, not a failure.
- `install-disk.yaml` — install target: the eMMC, with `wipe: true` (the disk
  still carries the stock CasaOS install — installing Talos destroys it).
- `node-labels.yaml` — node labels, including the `default-node` label the
  cluster-wide PodNodeSelector depends on.
- `etcd-optane-disk.yaml` — partitions the PCIe Optane for `/var/lib/etcd`,
  pinned by its stable `/dev/disk/by-id/nvme-eui.5cd2e46433b80100` path. It must
  be in the config _before_ the first `talosctl bootstrap`; moving etcd later
  means re-bootstrapping the single-member etcd. Single-node etcd has quorum 1 —
  worth a `talosctl etcd snapshot` habit. (The installer image is pulled before
  the imager touches the disk, so a failed pull leaves the eMMC untouched.)

### `registry-mirrors.yaml` — required, not optional

The node has **no internet egress** (no `Services→WAN` firewall rule; verified
live: NTS to `time.cloudflare.com:4460` times out) and the NAS pull-through
registry `registry.nas.svc.h.mirceanton.com` (10.0.10.245) is on the same VLAN,
so every mirror in that patch is both reachable and the only way installer, CNI
and workload images can be pulled. It is also why the credentials are a hard
requirement: the registry answers `/v2/*` with `401` and rejects the anonymous
token endpoint with `403` (verified against Nexus 3.96.4), and every mirror is
`skipFallback: true`, so a failed pull fails hard instead of falling back to an
upstream that is unreachable anyway.

## Talos version and config shape

The node runs **Talos v1.14.2** — the latest release, and the vanilla metal ISO
it boots with no extensions — and the installer image is pinned to the matching
vanilla `ghcr.io/siderolabs/installer:v1.14.2`.

Every patch in this directory is classic `v1alpha1`-shaped, the shape Talos
≤ v1.13 emits. Talos ≥ v1.14 _reads_ that shape fine but rejects a config that
carries both shapes at once, and a renderer that follows the installer version
emits the v1.14 multi-document base (`KubeletConfig`, `KubePrismConfig`, …) on
top of those patches — 14 `talosctl validate` errors such as `.machine.kubelet
... is already set in v1alpha1 config`. That was the original blocker; it is
resolved by pinning the config shape independently:

```yaml
contractVersion: v1.13.10 # classic shape, keeps the patch tree valid
installer:
  image: ghcr.io/siderolabs/installer:v1.14.2 # the version the node runs
```

`contractVersion` defaults to `installer.talosVersion` (and, when that is unset,
to the renderer's own machinery), which is exactly why it has to be set
explicitly here: a 1.14.2 node reads a 1.13-shaped config, but this patch tree
cannot be handed the 1.14 shape.

## Open items

- **Registry credentials — hard requirement, unresolved.** The build needs
  `registry_username`/`registry_password` in the environment (or a gitignored
  `.env` / `op run --env-file`), and the node needs the matching
  `machine.registries.config` auth, to pull the installer image, the Kubernetes
  images and every workload image. Without them the install fails at the first
  pull; nothing was applied to the board.
- **Node clock.** The RTC is ~3 h ahead and NTP cannot sync without egress
  (`TimeStatus.synced=false`), so `talosctl` TLS verification fails (hence
  `--insecure`) and every certificate is issued with the skewed clock. Fix the
  RTC, or point `machine.time.servers` at a local source once one exists.
- **No out-of-band access.** No BMC; the rack JetKVM's attachment to this board
  is unverified, so a bad network config needs physical intervention.
- **Cilium bootstrap.** `cni: none` plus a disabled kube-proxy need a bootstrap
  path for this cluster (kube-proxy replacement); the repo's `bootstrap/`
  (Cilium + flux-operator + flux-instance) targets home-ops only. Until it
  exists the node stays `NotReady` after bootstrap — separate work, separate PR.
- **Switch LAG (LACP).** `ether11`+`ether12` LAG (`bond5`) and the `10.0.10.195`
  static lease for `zimaboard` live in `mikrotik-terraform` PR #160 — open, needs
  a maintenance window. Deliberately deferred here: the node runs
  `active-backup` until then.
- **eMMC contents.** The stock CasaOS install is destroyed by the install
  (`wipe: true`). Confirm nothing on it matters.
- **`default-node` selector.** Kept for consistency with home-ops; on a
  single-node cluster it only adds a way to make nothing schedule. Drop it
  together with the label if unwanted.
- **`maxPods: 200`.** Inherited from the home-ops `kubelet-tuning.yaml`; 110 is
  the kubelet default and may suit this board better.
- **Public (DMZ) placement.** Not implemented: needs the
  `feat/dmz-vlan-port-forward` branch merged (VLAN 666, firewall, `WAN:443` →
  `10.0.20.250`) and this directory re-pinned to `10.0.20.0/24`.

## Validation

- `talstomize build .` (a build of `mirceanton/talstomize@960d653`, the
  `contractVersion` fix) plus `talosctl validate --mode metal` (v1.14.2):
  **valid for metal mode**. The render carries `endpoint:
https://10.0.10.195:6443`, SANs `.195`/FQDN/`127.0.0.1`, `interfaces: [bond0,
active-backup, dhcp]`, `disks: /dev/disk/by-id/nvme-eui.… → /var/lib/etcd`,
  `install: {disk: /dev/mmcblk0, wipe: true, image: …/installer:v1.14.2}`,
  `cni.name: none`, `proxy.disabled: true`, `allowSchedulingOnControlPlanes:
true`, kubelet `nodeIP.validSubnets: 10.0.10.0/24` and etcd
  `advertisedSubnets: 10.0.10.0/24`.
- `talosctl apply-config --insecure --dry-run -n 10.0.10.195 -f
_out/zimaboard.yaml`: **accepted by the live node** (maintenance mode, exit 0)
  — the rendered config is decoded and validated by the real v1.14.2 machine,
  not just by the offline validator.
- `mise exec -- task lint:check` (prettier + actionlint, the repo's CI job):
  passes.

Both of the first two were run with a **disposable** secrets bundle and
placeholder registry credentials: they prove the render and decode path, not an
apply-ready artifact. The disposable material was generated in a scratch
directory outside the repo and deleted afterwards.

## Related work

- `test/talstomize-migration` — the PoC branch that migrates the **home-ops**
  cluster's own config from talhelper to a `base/` + `clusters/<name>/` layout.
  This directory follows the same patch conventions but stays at
  `talos/zimaboard/` until that layout lands; because every patch here is local
  the move is a plain `git mv`.
- `mirceanton/talstomize` PR #22 — the `contractVersion` support this directory
  relies on.
- `mirceanton/mikrotik-terraform` PR #160 — the CRS326 LAG plus the `zimaboard`
  DHCP lease. (PR #158, the DMZ VLAN/port-forward, belongs to the unmerged public
  placement.)
- `mirceanton/home-ops` PR #1221 (public `envoy-public` Gateway) and PR #1222
  (blog/links workloads) are the cluster-side counterparts of that public
  placement.
