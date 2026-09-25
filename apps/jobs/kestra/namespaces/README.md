# Kestra flows (Git-owned)

Everything under this directory is applied into Kestra by the `system.git-sync` flow
(`io.kestra.plugin.git.NamespaceSync`, `sourceOfTruth: GIT`, `whenMissingInSource: DELETE`),
defined in [`../app/flows/git-sync.yaml`](../app/flows/git-sync.yaml). Flux does **not** apply
these files.

Layout is fixed by NamespaceSync — one folder per Kestra namespace, named literally (dots are
not nested paths):

```text
namespaces/
├── homelab/
│   ├── flows/<flow-id>.yaml   # flow `namespace:` must be `homelab`
│   └── files/...              # namespace files (scripts, SQL, ...)
└── homelab.maintenance/
    └── flows/<flow-id>.yaml   # flow `namespace:` must be `homelab.maintenance`
```

- Change flows via PR/commit here. UI edits in `homelab.*` are overwritten (or the flow deleted)
  on the next sync, every 5 minutes.
- Kestra 2.0 removed `pluginDefaults`; repeat task settings inline.
- Run container steps with `io.kestra.plugin.kubernetes.core.PodCreate` in the `jobs` namespace
  (the Kubernetes task runner and Docker-in-Docker are not used).
