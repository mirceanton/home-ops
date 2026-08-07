# talstomize PoC

A test migration of `../talos` (Talhelper) to
[`talstomize`](https://github.com/mirceanton/talstomize), to see how the tool
holds up against a real cluster config. Not wired into any CI/bootstrap yet -
`../talos` is still the source of truth.

## Layout

A kustomize-flavored base/overlay split, one directory per cluster so a
second cluster could reuse the same base patches later:

```
talos-talstomize/
├── base/                    # patches with nothing cluster-specific in them
└── clusters/
    └── home/                # this cluster
        ├── talstomize.yaml
        ├── talsecret.sops.yaml
        └── patches/         # cluster-specific patches
            └── home-ops/    # this node's own patches (e.g. its NIC/bond/VLAN config)
```

`base/` patches are referenced from `clusters/home/talstomize.yaml` as
`../../base/<name>.yaml`; cluster-specific ones as `./patches/<name>.yaml`.
The split isn't always obvious - e.g. `base/nvidia.yaml`/`base/zfs.yaml`
(kernel modules for a GPU/ZFS-having node) sit in `base/` because another
cluster's node with the same hardware would want the identical patch, even
though only `home-ops` uses them today. `patches/sysctls.yaml` stayed
cluster-specific because some of its tuning (Sunshine streaming port
reservations, GameGuard/Steam-related settings) really is specific to this
machine's actual workload, not generically reusable.

## Try it

> [!NOTE]
> Needs a talstomize build from the `feat/init` branch (envsubst, sops,
> https-URL patches, the machinery v1.13.8 bump, plus the `patches`/
> `additionalSubjectAltNames`/`dnsDomain`/`talosconfig`/`installer` fields
> this PoC now uses) - none of it is in a tagged release yet. Build from a
> local checkout until it lands upstream. `sops` itself must also be on
> `PATH` (it's how `clusters/home/talsecret.sops.yaml` gets decrypted), and
> `factory.talos.dev` must be reachable (the node's `installer.schematic`
> gets resolved there at build time now).

```shell
export registry_username=... registry_password=...           # or: op run --env-file=.env -- ...
go run ./cmd/talstomize build /path/to/this/dir/clusters/home # from a talstomize checkout
```

`clusters/home/talsecret.sops.yaml` is the secrets bundle - the exact same
`talosctl gen secrets` shaped file as `../talos/talsecret.sops.yaml` (same
content, even; talstomize's secrets bundle format is byte-compatible with
Talhelper's), just encrypted for the same age recipient and committed here
directly. talstomize auto-detects the `sops:` metadata and decrypts it
transparently at build time - no separate decrypt-to-disk step needed, and
nothing plaintext ever touches disk or git.

`build` also writes a `talosconfig` (talosctl client config) into the
output dir now, alongside `home-ops.yaml` - Talhelper's own `genconfig`
always did this, talstomize didn't used to.

## Native fields adopted since the initial migration

talstomize grew a few more `talosctl gen config` flag equivalents; this
PoC now uses them instead of the raw-patch workarounds noted below at the
time:

- **`additionalSubjectAltNames`** (top-level) replaces the hand-written
  `machine.certSANs` + `cluster.apiServer.certSANs` block that used to
  live in a patch - same values (`--additional-sans` sets both from a
  single list).
- **`patches`** (top-level, cluster-wide - applied before
  `controlplanePatches`/`workerPatches`, regardless of role). Everything
  here used to sit in `controlplanePatches` only, because talstomize had
  no "every node" list - harmless on this controlplane-only cluster, but
  would've been silently wrong on a multi-role one (workers never getting
  their kubelet tuning, KubePrism, host DNS, ...). `controlplanePatches`
  got re-audited down to only what's genuinely controlplane-exclusive:
  `cluster.etcd`/`cluster.apiServer`/`cluster.controllerManager`/
  `cluster.scheduler` settings, since etcd and the K8s control plane
  components only ever run there. Everything else - `cluster.discovery`
  (every node participates), `machine.kubelet.*` (kubelet runs
  everywhere, including the nodeIP subnet binding split out of
  `network-binding.yaml` into its own `kubelet-node-ip.yaml`),
  `machine.features.kubePrism`/`hostDNS`/`kubernetesTalosAPIAccess`
  (per-node features), `machine.network.disableSearchDomain`, `cni: none`,
  `allowSchedulingOnControlPlanes`, sysctls, registry mirrors - moved to
  `patches`.
- **`nodes.home-ops.installer.schematic` + top-level `installer.talosVersion`**
  replace the hand-computed `machine.install.image` that used to live in a
  patch - the exact same `extraKernelArgs`/`systemExtensions` block as
  `../talos/talconfig.yaml`'s own `schematic:`, now resolved against
  factory.talos.dev by talstomize itself at build time instead of by hand
  once via `curl`. Nested under `installer` (alongside `installer.image`,
  unused here) to mirror `machine.install`'s own shape rather than flat
  top-level fields. Reproduces the identical schematic ID
  (`66c39682a29d82028c3bc829bcb2a2f450ee7a4e3d16a3d2b952b546c292a38e`)
  every time, since the Factory hashes the customization deterministically.

## Known gaps vs. the Talhelper config

- **`base/registry-mirrors.yaml` uses `${registry_username}` /
  `${registry_password}`**, resolved by talstomize's envsubst support from
  the process environment at build time - same values as
  `../talos/talenv.sops.yaml`, just sourced differently (no
  `talstomize`-native secrets-file templating exists, so export them or run
  through `op run`/similar before building).
- **`base/apiserver-admission-pod-security-disable.yaml` uses
  `$patch: delete`** (single `$`), not Talhelper's `$$patch: delete`.
  talstomize patches go straight through upstream Talos machinery's own
  patcher, which only recognizes the single-`$` form.

## Bugs found in talstomize while testing this

Both fixed on talstomize's `feat/init` branch:

- **Stale `machinery` dependency** (`v1.9.5`, vs. Talos `v1.13.8` pinned in
  talstomize's own `.mise.toml`) didn't recognize the `BondConfig` /
  `VLANConfig` / `DHCPv4Config` document kinds this node's bonded+VLAN
  network config needs, so it couldn't even render. Bumped the dependency.
- That bump then exposed a real conflict: the base config now ships a
  default `HostnameConfig{auto: stable}` document, which Talos rejects
  alongside talstomize's static-hostname patch (`machine.network.hostname`).
  `talosctl validate` failed with `static hostname is already set in
  v1alpha1 config` until `internal/talos/engine.go` was fixed to delete that
  document when applying the hostname.
- `kubernetesVersion: v1.36.3` (Talhelper-style, with the `v`) silently
  produced `vv1.36.3` image tags. talstomize now strips a leading `v`.
- Building this node's real `schematic:` against the live Factory (not a
  synthetic test) caught two more bugs in talstomize's schematic support
  on its first real-world exercise: the Factory returns `201 Created` on
  success, not `200` (every request was being treated as an error despite
  succeeding), and the schematic field was `*yaml.Node` (pointer) -
  decoding into a `*yaml.Node` field allocates the pointer but never
  populates its content, so every schematic silently resolved to an empty
  customization. Both fixed on `feat/init` (now squashed into the single
  `installer.image`/`installer.schematic` commit).

Not a bug, but a deliberate design call worth noting: talstomize's sops
support shells out to the `sops` CLI rather than embedding it as a Go
library. Embedding pulls in ~340 transitive packages (the full AWS/GCP/
Azure/Vault SDKs, unconditionally) just to support KMS backends this setup
doesn't use - shelling out keeps `talstomize build` dependency-free unless
a secrets file is actually encrypted, same trade-off `apply` already makes
for `talosctl`.

## Verification done

Rendered with a local `talstomize` build (with the fixes above, real
registry credentials via envsubst, the native fields adopted above -
including a live resolution of this node's real `schematic:` against
factory.talos.dev, not a stubbed/offline one - and the current
`base`/`clusters` layout) and diffed (structurally, ignoring comments)
against `../talos/clusterconfig/home-ops-home-ops.yaml` (regenerated fresh
via `talhelper genconfig`, not a stale cached copy). The only remaining
differences: the HostnameConfig document being replaced by the equivalent
legacy field (see above), harmless newer-machinery defaults
(`extraManifests: []`, the `exclude-from-external-load-balancers` node
label), and kernel module list *order* (same 7 modules, just reordered to
match whatever order `base/nvidia.yaml`/`base/zfs.yaml`/`patches/uinput.yaml`
happen to be listed in the node's `patches:` now vs. the original
`nvidia, uinput, zfs` - cosmetic, module load order doesn't affect
anything since modprobe resolves dependencies regardless of declaration
order). Also passed `talosctl validate --mode metal` offline. Never
applied to the real node.

While rewiring the paths after the `base`/`clusters` reorg, one of the
node's `nodeLabels` had been accidentally renamed from
`k8s.mirceanton.com/default-node` to `k8s.mirceanton.com/controlplane-node`
- silently breaking default pod scheduling, since
`patches/apiserver-admission-pod-node-selector.yaml`'s `PodNodeSelector`
still targets `default-node=true` as every unscheduled pod's default
selector, and the real `../talos/talconfig.yaml` still uses `default-node`
too. Reverted to keep it matching.
