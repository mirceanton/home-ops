# Skill: Deploy a New Application

## Overview

This skill guides you through adding a new application deployment to the cluster using FluxCD + Helm. The default chart is **bjw-s-labs app-template** (`oci://ghcr.io/bjw-s-labs/helm/app-template`). Only use an official/first-party chart when the app provides one **and** it requires resources that app-template cannot model (e.g., CRDs, ClusterRoles, Webhooks for operators).

---

## Step 1: Gather Requirements

> **STOP. Do not create any files until every question below has been answered by the user.** Do not infer or assume answers — ask explicitly, even if an answer seems obvious from context.

Before creating any files, ask the user for:

| Question                    | Notes                                                                                                                                                                                                |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Container image**         | Full image reference, e.g. `ghcr.io/foo/bar:1.2.3`. Check existing apps for the tag format (plain semver vs digest).                                                                                 |
| **Namespace**               | Must be one of the existing namespace directories under `apps/`. If a new namespace is needed, that is a separate task — first create the namespace dir, `namespace.yaml`, and `kustomization.yaml`. |
| **App name**                | Kebab-case slug, used as the directory name and Kubernetes resource name.                                                                                                                            |
| **Exposed port**            | The port the container listens on.                                                                                                                                                                   |
| **HTTP route needed?**      | `envoy-internal` for LAN-only, `envoy-tailscale` for Tailscale, both if required.                                                                                                                    |
| **Persistent data needed?** | If yes, ask capacity (e.g. `5Gi`). Stateful apps use volsync; ephemeral scratch space uses `emptyDir`.                                                                                               |
| **Secrets needed?**         | If yes, ask which 1Password item to pull from (ClusterSecretStore `onepassword`).                                                                                                                    |

### Optional: search for prior art

If the kubesearch MCP server is available (tool name `mcp__kubesearch__search` or similar), search for the app name to find how other home-ops repos deploy it. Otherwise use `WebSearch` to query `site:github.com home-ops <app-name> helm-release.yaml` for inspiration. Adapt findings to the patterns below — do not copy verbatim.

---

## Step 2: Understand the File Structure

Every app follows this layout:

```bash
apps/<namespace>/<app-name>/
├── kustomization.yaml          # top-level: just references ./app.ks.yaml
├── app.ks.yaml                 # Flux Kustomization resource
└── app/
    ├── kustomization.yaml      # lists resources in this directory
    ├── oci-repository.yaml     # OCIRepository for the helm chart
    ├── helm-release.yaml       # HelmRelease with all values
    ├── external-secret.yaml    # (optional) ExternalSecret for 1Password secrets
    └── <name>.pvc.yaml         # (optional) standalone PVC if not using volsync
```

---

## Step 3: Create the Files

### 3a. `apps/<namespace>/<app-name>/kustomization.yaml`

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./app.ks.yaml
```

### 3b. `apps/<namespace>/<app-name>/app.ks.yaml`

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.mirceanton.com/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app <app-name>
spec:
  interval: 10m
  prune: true
  wait: true
  timeout: 15m
  targetNamespace: <namespace>

  path: ./apps/<namespace>/<app-name>/app
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system

  postBuild:
    substitute:
      APP: *app
      # Add VOLSYNC_CAPACITY, VOLSYNC_PUID, VOLSYNC_PGID here if using volsync

  decryption: { provider: sops }
  dependsOn: []
```

**When to add `components` and `dependsOn`:**

- **Persistent data with backup** → add `components: [../../../../components/volsync/]` and add `dependsOn` entries for `1password-connect` (security-system), `volsync` (storage-system), and `openebs` (storage-system).
- **Secrets via ExternalSecret** → add `dependsOn` for `external-secrets-operator` (security-system) and `1password-connect` (security-system).
- **CNPG Postgres** → add `components: [../../../../components/cnpg/]` and relevant deps.
- **If no substitutions** → use `postBuild: substitute: {}`.

### 3c. `apps/<namespace>/<app-name>/app/oci-repository.yaml`

Always use app-template unless the upstream chart is required (see Overview).

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.mirceanton.com/source.toolkit.fluxcd.io/ocirepository_v1.json
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: <app-name>
spec:
  interval: 15m
  url: oci://ghcr.io/bjw-s-labs/helm/app-template
  ref:
    tag: 5.0.1

  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
```

If using an official chart that does NOT publish an OCI Artifact, use a `HelmRepository` source instead and reference it accordingly.

### 3d. `apps/<namespace>/<app-name>/app/helm-release.yaml`

Start from this minimal secure template and expand only as needed:

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.mirceanton.com/helm.toolkit.fluxcd.io/helmrelease_v2.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: &app <app-name>
spec:
  interval: 30m
  chartRef:
    kind: OCIRepository
    name: <app-name>

  values:
    global:
      createDefaultServiceAccount: false

    controllers:
      <app-name>:
        annotations:
          reloader.stakater.com/auto: "true" # remove if no configmaps/secrets
        containers:
          app:
            image:
              repository: <image-repo>
              tag: <image-tag>

            probes:
              liveness:
                enabled: true
              readiness:
                enabled: true
              startup:
                enabled: true
                spec:
                  failureThreshold: 30
                  periodSeconds: 5

            resources:
              requests:
                cpu: 10m
                memory: 64Mi
              limits:
                memory: 256Mi # tune based on app; NEVER set limits.cpu

            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true # start with true; relax only if proven necessary
              capabilities: { drop: ["ALL"] }

    defaultPodOptions:
      automountServiceAccountToken: false
      enableServiceLinks: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        fsGroupChangePolicy: OnRootMismatch

    service:
      app:
        controller: <app-name>
        ports:
          http:
            port: <port>

    route:
      home:
        hostnames: ["<app-name>.home.mirceanton.com"]
        parentRefs:
          - name: envoy-internal
            namespace: network-system
```

**Common additions to expand on the template:**

**`readOnlyRootFilesystem: true` with writable paths** — mount `emptyDir` for any path the app needs to write:

```yaml
persistence:
  tmp:
    type: emptyDir
    globalMounts:
      - path: /tmp
  cache:
    type: emptyDir
    globalMounts:
      - path: /app/cache
```

**Persistent volume via volsync** — reference the claim created by the component:

```yaml
persistence:
  config:
    existingClaim: ${APP}
    globalMounts:
      - path: /config
```

**Secret from ExternalSecret** — reference the Kubernetes Secret by name:

```yaml
env:
  SOME_VAR:
    valueFrom:
      secretKeyRef:
        name: <app-name>-secret
        key: SOME_VAR
```

**Non-standard UID** — if the upstream image runs as a specific UID (check with `kubectl exec` or image docs), adjust `runAsUser`/`runAsGroup`/`fsGroup` accordingly. Use `568` for apps that follow the home-operations convention.

**Tailscale route** — add a second entry alongside the internal one:

```yaml
tailscale:
  hostnames: ["<app-name>.ts.mirceanton.com"]
  parentRefs:
    - name: envoy-tailscale
      namespace: network-system
```

**StatefulSet with inline VolumeClaimTemplate** — for message brokers, databases, etc. that manage their own storage lifecycle:

```yaml
controllers:
  <app-name>:
    type: statefulset
    statefulset:
      volumeClaimTemplates:
        - name: data
          storageClass: openebs-zfs
          accessMode: ReadWriteOnce
          size: 5Gi
```

### 3e. `apps/<namespace>/<app-name>/app/kustomization.yaml`

List every file in the `app/` directory:

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ./oci-repository.yaml
  - ./helm-release.yaml
  # - ./external-secret.yaml
  # - ./<name>.pvc.yaml
```

### 3f. `apps/<namespace>/<app-name>/app/external-secret.yaml` (optional)

Only create this if the app needs secrets from 1Password:

```yaml
---
# yaml-language-server: $schema=https://k8s-schemas.mirceanton.com/external-secrets.io/externalsecret_v1.json
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: &name <app-name>-secret
spec:
  refreshInterval: 1h

  secretStoreRef:
    name: onepassword
    kind: ClusterSecretStore

  target:
    name: *name
    creationPolicy: Owner

  data:
    - secretKey: <KEY_NAME>
      remoteRef:
        key: "<1Password item title>"
        property: <field name>
```

---

## Step 4: Register the App in the Namespace Kustomization

Open `apps/<namespace>/kustomization.yaml` and add the new app directory to the `resources` list (maintain alphabetical order):

```yaml
resources:
  - ./namespace.yaml
  - ./<existing-app-1>
  - ./<new-app-name> # add here
  - ./<existing-app-2>
```

---

## Step 5: Security Checklist

Before finishing, verify every item:

- [ ] `runAsNonRoot: true` in `defaultPodOptions.securityContext`
- [ ] `runAsUser` / `runAsGroup` / `fsGroup` are set to a specific non-zero UID (not `0`)
- [ ] `allowPrivilegeEscalation: false` in container `securityContext`
- [ ] `capabilities: { drop: ["ALL"] }` in container `securityContext`
- [ ] `readOnlyRootFilesystem: true` attempted first; only `false` if the app genuinely cannot run otherwise (document why with a comment)
- [ ] `automountServiceAccountToken: false` in `defaultPodOptions`
- [ ] `enableServiceLinks: false` in `defaultPodOptions`
- [ ] `global.createDefaultServiceAccount: false`
- [ ] Resource `limits.cpu` is **not set** — only `requests.cpu` and `limits.memory`
- [ ] Secrets are in ExternalSecret (1Password), never hardcoded in the HelmRelease

---

## Step 6: Lint

Run `task lint:check` to verify YAML formatting before committing. Run `task lint` to auto-fix.

---

## Common Pitfalls

- **Shell variables in ConfigMaps**: If a ConfigMap contains shell scripts with `${VAR}` syntax, add the annotation `kustomize.toolkit.fluxcd.io/substitute: disabled` to that ConfigMap to prevent Flux from mangling the variable references.
- **Missing reloader annotation**: If the app reads a ConfigMap or Secret at startup, add `reloader.stakater.com/auto: "true"` to the controller so it restarts on changes.
- **Wrong UID**: Some images (nginx, etc.) run as a specific non-1000 UID. Verify with `kubectl exec` or by checking the image docs rather than assuming 1000.
- **`drawio` not in tools kustomization**: The namespace-level `kustomization.yaml` is the source of truth for what Flux actually deploys. If a directory exists but is not listed there, it will not be deployed.
