# Skill: Deploy an MCP Server as a LiteLLMMCPServer

## Overview

An MCP server is registered on the LiteLLM proxy with a `LiteLLMMCPServer`
(CRD group `litellm.home-operations.com`, short name `llmcp`), installed by the
`litellm-operator` Helm release in namespace `ai`. The operator renders each CR
into the proxy's `mcp_servers` map and rolls the proxy when it changes.

There are two shapes:

| Shape           | Who runs the server                                                                                          | What to use it for                                                                   |
| --------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| `spec.workload` | the operator: it creates a `Deployment` + `Service` named after the CR and derives the URL from that Service | **the default** — every MCP server this repo deploys itself                          |
| `spec.url`      | somebody else (the app itself, a third party)                                                                | an endpoint the app already serves (vikunja's own API, streamarr) or a remote server |

`spec.url` and `spec.workload` are mutually exclusive; a validating webhook
rejects a CR that sets both or neither.

With `spec.workload`, no `HelmRelease`, `OCIRepository`, `oci-repository.yaml`
or separate `mcp/` directory is needed for the MCP server: the CR _is_ the
workload definition, and it lives next to the Helm release of the application
the server fronts.

- Live reference (minimal CR + ExternalSecret, nothing else):
  [`apps/ai/truenas-mcp/app/litellm-mcp-server.yaml`](../../apps/ai/truenas-mcp/app/litellm-mcp-server.yaml)
- Copy-paste template: [`assets/litellm-mcp-server.template.yaml`](assets/litellm-mcp-server.template.yaml)
- Upstream: <https://github.com/home-operations/litellm-operator> (README + `internal/controller/mcpserver_resources.go`)

## Where the files go

The whole point of `spec.workload` is that an MCP server stops being an app of
its own and becomes one more resource in the app it belongs to.

**MCP server for an app this repo already deploys** (`grafana-mcp`,
`home-assistant-mcp`, `navidrome-mcp`, `firefly-mcp`, `affine-mcp`, ...): put
the CR in that app's Kustomize directory, next to the app's `helm-release.yaml`:

```
apps/<namespace>/<app>/
├── app.ks.yaml              # Flux Kustomization (unchanged, keep dependsOn litellm-operator)
├── kustomization.yaml       # top level: ./app.ks.yaml (+ other .ks.yaml of the app)
└── app/
    ├── kustomization.yaml   # add ./litellm-mcp-server.yaml (sorted)
    ├── helm-release.yaml    # the APPLICATION's release — keep it
    ├── external-secret.yaml # add/move the MCP token here
    └── litellm-mcp-server.yaml
```

The old `mcp/` directory and its `mcp.ks.yaml` Flux Kustomization are deleted;
`kustomization.yaml` loses the `./mcp.ks.yaml` entry. Nothing else about the app
changes. Do not create a second Flux Kustomization for one CR — a new
`mcp.ks.yaml` just to render one file is exactly the duplication this pattern
removes.

**MCP server that has no host app** (`github-mcp`, `kubesearch-mcp`,
`truenas-mcp`, `flux-mcp`, the youtube ones): keep it as its own app directory,
but drop the parts the CR replaces:

```
apps/<namespace>/<mcp-name>/
├── app.ks.yaml
├── kustomization.yaml
└── app/
    ├── kustomization.yaml       # ./litellm-mcp-server.yaml + whatever else it needs
    ├── litellm-mcp-server.yaml
    ├── external-secret.yaml     # only if it needs a secret
    ├── service-account.yaml     # only if it needs API access (grafana-mcp precedent)
    └── files/ + configMapGenerator  # only if it mounts a config file
```

`oci-repository.yaml` and the MCP server's `helm-release.yaml` are deleted
(`apps/ai/truenas-mcp/` is the finished example). Keep anything that is not the
MCP workload: the `volsync` component and the PVC it creates stay (mount the
claim from `spec.workload.volumes`), and a `configMapGenerator` + `files/`
directory stays if the server reads a config file.

One app directory may hold several CRs (one per MCP server). Every CR must be in
the same namespace as the Secret its `authTokenRef` and `env` point at, so
render the app directory with the same `targetNamespace` you already use.

## Naming

| Thing                       | Convention                                                                                                                                                                                                                                                                                                                      |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `metadata.name`             | `<app>-mcp` (or `<mcp-name>` for a standalone server). It becomes the Deployment/Service name and the URL host, so it must be a DNS-1123 label. Keep the name the old Service had: pod URLs, `--allowed-hosts` flags and dashboards embed it.                                                                                   |
| `spec.alias`                | the app name in `snake_case`, without the `-mcp` suffix (`grafana`, `home_assistant`, `youtube_public`). It is the `mcp_servers` key and the identifier clients, `LiteLLMTeam.spec.mcpServers` and `LiteLLMVirtualKey.spec.mcpToolsets` use — renaming it is a breaking change for consumers, including Hermes profile entries. |
| `metadata.namespace`        | the app's namespace (Flux `targetNamespace`).                                                                                                                                                                                                                                                                                   |
| Comments / schema directive | keep the `# yaml-language-server: $schema=https://k8s-schemas.mirceanton.com/litellm.home-operations.com/litellmmcpserver_v1alpha1.json` first line, like every other manifest in the repo.                                                                                                                                     |

The operator labels and selects the generated pod itself
(`app.kubernetes.io/name`, `app.kubernetes.io/managed-by: litellm-operator`,
`app.kubernetes.io/component: mcp-server`) — do not add those by hand, and note
that `workload.podLabels` cannot override them.

## The fields that matter

`metadata.name`, `spec.alias`, `spec.proxyRef` + `spec.proxyNamespace`,
`spec.transport`, `spec.authType` + `spec.authTokenRef`, `spec.workload`,
`spec.params`.

- `proxyRef: litellm` / `proxyNamespace: ai` — the proxy lives in `ai`, every CR
  in this repo is elsewhere, so both fields are always set.
- `transport` — `http` (streamable HTTP, the default with a workload), `sse`
  (server-sent events, used by grafana-mcp and firefly-mcp) or `stdio` (the
  operator can only dial HTTP, so stdio servers cannot use `spec.workload`).
- `authType` + `authTokenRef` — how the gateway authenticates to the server
  (`bearer_token` is what this repo uses; the field is a free string). The
  referenced Secret must be in the CR's namespace. Rendered as:

  ```yaml
  truenas:
    auth_type: bearer_token
    authentication_token: os.environ/LITELLM_MCPTOKEN_TRUENAS_MCP
    transport: http
    url: http://truenas-mcp.ai.svc.cluster.local:8080/mcp
  ```

- `params` — passthrough for `mcp_servers` keys with no typed field
  (`extra_headers`, `allowed_tools`, `oauth`, ...). Merged under the typed
  fields. Never put credentials here.

`status.resolvedURL` reports the URL the gateway dials: the derived
`http://<name>.<namespace>.svc.cluster.local:<port><path>` for a workload, or
`spec.url`. It is the quickest way to confirm what a CR actually registered.

## What the operator creates

For `spec.workload` the operator owns exactly two objects, both named after the
CR and owned by it (so they are garbage-collected when the CR goes away):

- `Deployment <name>` — one container named `mcp`, one TCP port named `http`
  (`workload.port`), the pod template carrying `podLabels` + `podAnnotations`,
  and a replica set from `workload.replicas` (default 1). **No probes, no
  service links setting, no security context, no defaults** — whatever the CR
  does not declare, the pod does not have.
- `Service <name>` — `ClusterIP`, selecting the operator's labels, port and
  target port both `workload.port`.

```yaml
# kubectl get deploy -n <ns> <name> -o yaml  (fields the operator manages)
metadata.labels:
  app.kubernetes.io/name: <name>
  app.kubernetes.io/managed-by: litellm-operator
  app.kubernetes.io/component: mcp-server
```

The gateway reaches the server at the derived URL, so `<name>`, `<namespace>`,
`port` and `path` are the four things that must be right.

## Mapping an app-template HelmRelease onto `spec.workload`

The MCP workload spec is 20 fields (`image`, `replicas`, `serviceAccountName`,
`automountServiceAccountToken`, `podAnnotations`, `podLabels`, `command`,
`args`, `port`, `path`, `env`, `envFrom`, `resources`, `securityContext`,
`podSecurityContext`, `nodeSelector`, `tolerations`, `affinity`, `volumeMounts`,
`volumes`). Translate the HelmRelease values you are deleting like this:

| app-template HelmRelease                                                       | `spec.workload`                                                                                        |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `controllers.<c>.containers.app.image.repository` + `tag`                      | `image` (one string; keep a `@sha256:` digest if the old value had one)                                |
| `containers.app.command` / `args`                                              | `command` / `args`                                                                                     |
| `containers.app.env` (map)                                                     | `env` (list; `NAME: value` → `{name, value}`, `{valueFrom}` copied as-is)                              |
| `containers.app.envFrom`                                                       | `envFrom`                                                                                              |
| `containers.app.resources.requests/limits`                                     | `resources`                                                                                            |
| `containers.app.securityContext`                                               | `securityContext`                                                                                      |
| `defaultPodOptions.securityContext`                                            | `podSecurityContext`                                                                                   |
| `defaultPodOptions.automountServiceAccountToken`                               | `automountServiceAccountToken`                                                                         |
| `global.createDefaultServiceAccount: false`                                    | nothing (no ServiceAccount is created); set `serviceAccountName` only when the server needs API access |
| `service.app.ports.http.port`                                                  | `port`                                                                                                 |
| `persistence.<x>` (emptyDir / existingClaim)                                   | `volumes` + `volumeMounts` (`emptyDir: {}` / `persistentVolumeClaim.claimName`)                        |
| `nodeSelector` / `tolerations` / `affinity`                                    | same fields                                                                                            |
| `controllers.<c>.annotations` (`reloader.stakater.com/auto`)                   | **not portable** — see pitfalls                                                                        |
| `probes`                                                                       | **not portable** — the operator creates no probes                                                      |
| `initContainers`, `strategy`, `type: statefulset`, `topologySpreadConstraints` | **not portable** — no such field                                                                       |

Anything the CR cannot express has to be moved into the image, into `command` /
`args`, or dropped deliberately — write a comment in the CR when it is dropped,
the way `truenas-mcp` documents its `TRUENAS_MCP_*` env.

## Migration procedure for one app

1. Read the app's `mcp/helm-release.yaml` (every value), its
   `mcp/external-secret.yaml`, `mcp/oci-repository.yaml`, `mcp/kustomization.yaml`
   and `mcp.ks.yaml`, plus the CR (`<app>-mcp`).
2. Draft the new CR from the template, applying the mapping table. Match the old
   `alias`, `transport`, `url` path and port — the URL must stay byte-identical
   to the one the Helm release produced
   (`http://<name>.<ns>.svc.cluster.local:<port><path>`).
3. Move the `ExternalSecret` (and `service-account.yaml`, `files/` +
   `configMapGenerator` if used) into the app's `app/` directory. Do not change
   the Secret name, keys or the 1Password item.
4. Add `litellm-mcp-server.yaml` to the app directory's `kustomization.yaml`
   (keep the list sorted), delete the `./mcp.ks.yaml` line from the app's
   `kustomization.yaml`, and delete the `mcp/` directory and `mcp.ks.yaml`.
5. Make sure the Flux Kustomization that now renders the CR depends on
   `litellm-operator` (namespace `ai`) — without the CRD the apply fails — plus
   `external-secrets-operator` + `1password-connect` (security-system) if it
   carries an `ExternalSecret`, and the app's own Kustomization
   (`grafana-instance`, `home-assistant`, ...) if it needs the app up first.
   `truenas-mcp` also lists `litellm` (namespace `ai`); the operator adopts the
   CR on the proxy's next reconcile either way.
6. Lint: `task lint:check` (prettier + actionlint).
7. Open one PR per app (or one PR for the template and one per migration batch —
   not one PR per field). Verify, then let it merge.

## Verification

Flux reporting `Ready` is not proof the server works: the operator creates no
probe, so a Deployment is `Available` as soon as the container runs, whether or
not anything listens on `port`/`path`.

1. `flux get kustomizations` — the app's Kustomization `Ready`.
2. `kubectl get llmcp -n <ns>` — the CR's `URL` column shows
   `status.resolvedURL`; it must equal the URL the old Service served.
3. `kubectl get deploy <name> -n <ns>` — `1/1` ready, and the pod's image, env,
   volumes and security context match what the HelmRelease had. The operator
   names the container `mcp` and the only port `http`.
4. `kubectl get svc <name> -n <ns>` — ClusterIP on `<port>`.
5. The rendered config: `kubectl get cm litellm-config -n ai -o yaml` — the
   `mcp_servers.<alias>` entry must carry the right `url`, `transport` and
   `auth_type`/`authentication_token` (`os.environ/LITELLM_MCPTOKEN_<NAME>`,
   with the value present in the proxy's environment, never in the ConfigMap).
6. Call a tool through the gateway (a `LiteLLMVirtualKey` with the alias in
   `mcpToolsets`, e.g. what a Hermes profile uses). That is the only check that
   covers the whole path — a wrong `port` or `path` is invisible to 1–4.

## Common pitfalls

- **No probes.** The CRD has no `probes` field; replace `httpGet` liveness and
  startup probes with nothing, and lean on step 6 above. A wrong `port` or
  `path` produces a green rollout and a dead endpoint.
- **No `initContainers`.** A server that needed an init step must do it in its
  entrypoint (or in `command`/`args`). The npm-at-runtime bootstrap pattern
  still works there, but nothing waits for it any more and
  `readOnlyRootFilesystem` must stay `false` for it.
- **kustomize cannot rewrite CRD fields.** `configMapGenerator` /
  `secretGenerator` name hashes are not substituted into `spec.authTokenRef`,
  `spec.workload.volumes` or `env`, because kustomize has no `nameReference`
  config for this CRD. Set `disableNameSuffixHash: true` on the generator and
  reference the stable name (the `github-mcp` ConfigMap does exactly this).
- **Flux `postBuild` substitution eats `${VAR}`.** Any `${FOO}` inside
  `args`, `env` or `command` is a Flux substitution variable and makes the
  Kustomization fail when it is undefined. Escape it as `$${FOO}`, or put the
  script in a ConfigMap annotated
  `kustomize.toolkit.fluxcd.io/substitute: disabled`.
- **Reloader does not cover CRD workloads.** `reloader.stakater.com/auto` is
  read from the workload's own metadata, and `podAnnotations` only reach the pod
  template. A mounted ConfigMap whose contents changed therefore does not roll
  the pod: bump a value in `podAnnotations` when you change it.
- **Secrets and namespaces.** `authTokenRef` and `env.valueFrom` resolve in the
  CR's namespace — the operator copies an out-of-namespace token into a
  proxy-owned `litellm-credentials` Secret for the gateway, and nothing else.
  A Secret that lives in the wrong namespace is a running-but-unauthenticated
  server.
- **Alias collisions.** Two CRs with the same `alias` fight over one
  `mcp_servers` key. Aliases are global to the proxy.
- **Do not define the same workload twice.** After the migration there must be
  no `HelmRelease` left for the MCP server — a leftover Helm release and the CR
  both manage a Deployment of the same name and will flap. The operator only
  ever deletes the Deployment/Service it owns (they carry an owner reference to
  the CR), so the rollback is `git revert` plus a reconcile, not manual cleanup.

## Rollback

Revert the PR and reconcile the app's Kustomization: the CR disappears, the
operator's Deployment and Service are garbage-collected with it, and the
`HelmRelease` comes back in the same commit. The `alias` never changed, so the
gateway config is restored to its previous entry.
