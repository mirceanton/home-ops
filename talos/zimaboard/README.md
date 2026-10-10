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
`../patches/` (the home-ops tree) at all: the generic patches it uses are copies
kept byte-identical to the home-ops originals, so the `home-ops`-side
reorganisation and the planned talstomize/1.14 migration cannot break this
render, and moving this directory into a multi-cluster layout later is a plain
`git mv`.

> **Not apply-ready — three external dependencies left.**
>
> 1. **NAS registry credentials.** The config renders, validates and is accepted
>    by the live node, but building it needs `registry_username` /
>    `registry_password` in the environment (the Services VLAN has no internet
>    egress and the NAS pull-through registry rejects anonymous pulls), so
>    without them neither the render nor a single image pull on the node can
>    succeed. See "Open items".
> 2. **A `factory.talos.dev` pull-through repo on the NAS registry.** Talos
>    stopped publishing the plain installer for 1.14 (no `v1.14.x` tag exists on
>    `ghcr.io/siderolabs/installer`), so the installer now comes from the Image
>    Factory and the node has to reach `factory.talos.dev` through the NAS. Until
>    that repo exists the install stops at the first pull.
> 3. **Booting the board into the ISO.** The board currently boots its stock
>    ZimaOS install from the eMMC; the Talos USB stick has to be booted again
>    (boot order / one-time boot menu, i.e. KVM or physical access) before
>    anything can be applied.
>
> **The install cannot complete as configured.** At ~06:50 the board was in Talos
> maintenance mode on the ISO (`install-watch.log`: `tcp/50000` up, the port
> refused an unauthenticated TLS poll) and `apply-config --insecure --dry-run`
> accepted this config; the board then went back to booting its stock ZimaOS, so
> **nothing was ever written to the eMMC** (`wipe: true` has never run). The
> installer image this directory pinned does not exist upstream — verified
> `2026-10-10`: `ghcr.io/siderolabs/installer` answers `404` for `v1.14.0`,
> `v1.14.1` and `v1.14.2` (its last tag is `v1.13.10`), so the install stops at
> the first pull. `factory.talos.dev/metal-installer/<default schematic>:v1.14.2`
> answers `200` for the same tag. That is the fix this PR is about.

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
    ├── zimaboard-sysctls.yaml
    └── zimaboard-time.yaml                    # machine.time.servers
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
  `factory.talos.dev` lookup and no internet access of its own. The **node**, on
  the other hand, has to _pull_ that image through the NAS — see
  `patches/registry-mirrors.yaml`.
- `patches/registry-mirrors.yaml` needs `registry_username` and
  `registry_password` in the environment; the build fails if they are unset.
- `build`/`diff` need a talstomize that understands `contractVersion` (see
  "Talos version and config shape"). The version pinned in the root `.mise.toml`
  still predates it (no release after `v0.1.0-rc.2` has been tagged, so the pin
  cannot simply be bumped) — until a release with
  `mirceanton/talstomize#22` is tagged, build one from a checkout of that project
  (`go build -o ./talstomize ./cmd/talstomize`).

## Target facts (verified on the live board)

- **Board**: IceWhale ZimaBoard2, Intel N150, 16 GB RAM, BIOS 5.27.
- **Talos**: vanilla metal ISO **v1.14.2**, maintenance mode when booted from the
  USB stick, **no system extensions**. The board currently boots its stock
  ZimaOS install from the eMMC instead (its web UI answers on `:80` at both
  `10.0.10.195` and `10.0.10.196`, `Server: Caddy`, `Via: ZimaOS-Gateway`), so
  `tcp/50000` is closed right now: the ISO has to be booted again before an
  install can be attempted.
- **NICs**: `enp1s0` `00:e0:4c:69:db:df` and `enp2s0` `00:e0:4c:69:db:e0` (both
  Intel I226-V, 1 Gbps), both plain untagged Services access ports today.
- **Addresses**: both NICs hold their own DHCP lease — `10.0.10.195` on
  `enp1s0`, `10.0.10.196` on `enp2s0` — out of the Services pool
  `10.0.10.195-10.0.10.199`, **with no reservation yet**: the `zimaboard` static
  lease is still only in `mikrotik-terraform` PR #160, and (verified
  `2026-10-10`) the RB5009's lease export lists no `zimaboard` entry while
  `zimaboard.svc.h.mirceanton.com` does not resolve, unlike
  `nas.svc.h.mirceanton.com`. Both facts change when #160 lands.
- **Install disk**: `/dev/mmcblk0` (eMMC, 62 GB) — still holds the stock ZimaOS
  install (destructive). No install has run, so the disk is untouched.
- **etcd disk**: `/dev/nvme0n1` (Optane, INTEL MEMPEK1J016GAD, EUI
  `5cd2e46433b80100`), 14 GB, empty, no partitions.
- **Network egress**: none from the Services VLAN (there is no `Services→WAN`
  firewall rule) — every image has to come from the NAS.
- **Access**: Talos API on TCP 50000 at `10.0.10.195` (`--insecure` while in
  maintenance mode); no BMC. The rack JetKVM (`10.0.0.9`) is reachable and set up
  without a password (`/device` → `{"authMode":"noPassword"}`, `/device/status`
  → `{"isSetup":true}`), but **its attachment to this board is still unverified**
  — do not assume it can be used to power-cycle the board.
- **Time**: `TimeStatus.synced=false`; the RTC is ~3 h ahead of real UTC (the
  ZimaOS `Date:` header was ~2 h 49 m ahead while the board booted it, which is
  the same skew) and NTP cannot reach `time.cloudflare.com` without egress.

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
  `zimaboard.svc.h.mirceanton.com` (`match_subdomain`) with it — not live yet,
  see "Target facts".
- `10.0.10.195`, `zimaboard.svc.h.mirceanton.com` and `127.0.0.1` (KubePrism) are
  certificate SANs. The node IP is _not_ added automatically, and
  `nodes.zimaboard.ip`, `controlPlaneEndpoint` and the SANs must stay in sync.
- **Bond fallback** if the bond itself ever misbehaves: give `enp1s0` its own
  `dhcp: true` entry, drop the `bond0` entry, and leave `enp2s0` unconfigured.

## Patches

Every patch is local to this directory. The generic ones are copies of the
home-ops `talos/patches/*` files, kept verbatim so a diff against the home-ops
tree stays reviewable:

- `patches/` (applied to every node): `host-dns.yaml`, `kubeprism.yaml`,
  `registry-mirrors.yaml`.
- `controlplanePatches/` (before the node's own patches):
  `cluster-discovery.yaml`, `kubelet-tuning.yaml`, `etcd-tuning.yaml`,
  `disable-search-domain.yaml`, `mutating-admission.yaml`,
  `disable-kube-proxy.yaml`.
- Node-specific (`nodes.zimaboard.patches`): `zimaboard-bond.yaml`,
  `zimaboard-network.yaml`, `zimaboard-time.yaml`, `install-disk.yaml`,
  `node-labels.yaml`, `etcd-optane-disk.yaml`.
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
  still carries the stock ZimaOS install — installing Talos destroys it).
- `node-labels.yaml` — node labels, including the `default-node` label the
  cluster-wide PodNodeSelector depends on.
- `etcd-optane-disk.yaml` — partitions the PCIe Optane for `/var/lib/etcd`,
  pinned by its stable `/dev/disk/by-id/nvme-eui.5cd2e46433b80100` path. It must
  be in the config _before_ the first `talosctl bootstrap`; moving etcd later
  means re-bootstrapping the single-member etcd. Single-node etcd has quorum 1 —
  worth a `talosctl etcd snapshot` habit. (The installer image is pulled before
  the imager touches the disk, so a failed pull leaves the eMMC untouched.)
- `zimaboard-time.yaml` — `machine.time.servers: [10.0.10.1]`. The board has no
  battery-backed clock and the VLAN has no NTP reachable, so this points it at
  the lab's own NTP source. It is the **Talos half of a two-sided fix**: the
  RB5009 has an NTP _server_ stanza but it is not enabled and its input chain has
  no UDP/123 accept for the Services VLAN (both live in `mikrotik-terraform`,
  not here), so until that half lands the node keeps the RTC time and every API
  call has to use `--insecure`.

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

The `factory.talos.dev` entry is the newest one and needs a matching **proxy repo
on the NAS Nexus** (`docker-factory`, `remoteUrl https://factory.talos.dev`).
Nexus 3.96.4 has proxies for `ghcr.io`, `docker.io`, `quay.io`, `gcr.io`,
`registry.k8s.io` and `oci.external-secrets.io` but none for the factory host
(verified: `/v2/factory.talos.dev/*` and `/v2/docker-factory/*` → `404`).

## Talos version and config shape

The node runs **Talos v1.14.2** — the latest release, and the vanilla metal ISO
it boots with no extensions. The installer image is the _same_ vanilla installer,
taken from the Image Factory because that is the only place it exists for 1.14:

```yaml
contractVersion: v1.13.10 # classic shape, keeps the patch tree valid
installer:
  image: factory.talos.dev/metal-installer/<default schematic>:v1.14.2
```

Every patch in this directory is classic `v1alpha1`-shaped, the shape Talos
≤ v1.13 emits. Talos ≥ v1.14 _reads_ that shape fine but rejects a config that
carries both shapes at once, and a renderer that follows the installer version
emits the v1.14 multi-document base (`KubeletConfig`, `KubePrismConfig`, …) on
top of those patches — 14 `talosctl validate` errors such as `.machine.kubelet
... is already set in v1alpha1 config`. That was the original blocker; it is
resolved by pinning the config shape independently:

`contractVersion` defaults to `installer.talosVersion` (and, when that is unset,
to the renderer's own machinery), which is exactly why it has to be set
explicitly here: a 1.14.2 node reads a 1.13-shaped config, but this patch tree
cannot be handed the 1.14 shape.

The other 1.14 change is the installer: `ghcr.io/siderolabs/installer` has no
`v1.14.x` tag (its last tag is `v1.13.10`, verified `2026-10-10`), so from 1.14 on
the only published installer is
`factory.talos.dev/metal-installer/<schematic>:<tag>`. The schematic used here is
the Image Factory's default (empty) one — the contents of the vanilla ISO — so
nothing about the installed system changes.

## Open items

- **Registry credentials — hard requirement, unresolved.** The build needs
  `registry_username`/`registry_password` in the environment (or a gitignored
  `.env` / `op run --env-file`), and the node needs the matching
  `machine.registries.config` auth, to pull the installer image, the Kubernetes
  images and every workload image. Without them the install fails at the first
  pull; nothing was applied to the board.
- **`factory.talos.dev` proxy repo on the NAS Nexus — unresolved.** Add a docker
  proxy repository (`docker-factory`, `remoteUrl https://factory.talos.dev`,
  `dockerHub: false`, online) so the `factory.talos.dev` mirror in
  `registry-mirrors.yaml` can serve the installer. The alternative, if that is
  unwanted, is to pin `ghcr.io/siderolabs/installer:v1.13.10` (the last version
  published on ghcr.io) and let the node install **1.13.10** rather than 1.14.2 —
  one line in `talstomize.yaml`, with the plan to upgrade the node to 1.14.2 once
  the factory mirror exists.
- **Boot the ISO.** The board boots ZimaOS from the eMMC right now; it has to be
  booted from the Talos USB stick again (boot order / one-time boot menu, i.e.
  KVM or physical access) before `apply-config`/`bootstrap` can run.
- **Node clock.** The RTC is ~3 h ahead and NTP cannot sync without egress
  (`TimeStatus.synced=false`), so `talosctl` TLS verification fails (hence
  `--insecure`) and every certificate is issued with the skewed clock. The Talos
  half is `patches/zimaboard-time.yaml`; the router half (enable the RB5009's NTP
  server, accept UDP/123 from the Services VLAN) is still open.
- **No out-of-band access.** No BMC; the rack JetKVM's attachment to this board
  is unverified, so a bad network config needs physical intervention.
- **Cilium bootstrap.** `cni: none` plus a disabled kube-proxy need a bootstrap
  path for this cluster (kube-proxy replacement). That path is
  `kubernetes/clusters/public/` (Cilium + flux-operator + flux-instance + the
  Envoy/KPS CRDs), added to this repo in a separate PR; until it is merged and
  run the node stays `NotReady` after bootstrap.
- **Switch LAG (LACP).** `ether11`+`ether12` LAG (`bond5`) and the `10.0.10.195`
  static lease for `zimaboard` live in `mikrotik-terraform` PR #160 — open, needs
  a maintenance window. Deliberately deferred here: the node runs
  `active-backup` until then.
- **eMMC contents.** The stock ZimaOS install is destroyed by the install
  (`wipe: true`). Confirm nothing on it matters — the board still boots it today.
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
https://10.0.10.195:6443`, SANs `.195`/FQDN/`127.0.0.1`, `machine.time.servers:
[10.0.10.1]`, `disks: by-id Optane → /var/lib/etcd`,
  `install: {disk: /dev/mmcblk0, wipe: true, image:
factory.talos.dev/metal-installer/…:v1.14.2}`, `cni.name: none`,
  `proxy.disabled: true`, `allowSchedulingOnControlPlanes: true`, kubelet
  `nodeIP.validSubnets: 10.0.10.0/24`, etcd `advertisedSubnets: 10.0.10.0/24`
  and `machine.registries.mirrors` keys `docker.io`, `factory.talos.dev`,
  `gcr.io`, `ghcr.io`, `oci.external-secrets.io`, `quay.io`,
  `registry-1.docker.io`, `registry.k8s.io`.
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

- `kubernetes/clusters/public/` — the bootstrap path for this cluster (Cilium +
  flux-operator + flux-instance + the Envoy/KPS CRDs), separate PR.
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
