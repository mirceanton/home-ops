# AGENTS.md

## Environment & Tooling

- **Tool Management**: Use `mise` to manage all tools (kubectl, kustomize, flux, helm, talosctl, task, sops, age, yq, etc.).
- **Secrets**: Managed via **SOPS** + **age**. The key is `age.key`. `SOPS_AGE_KEY_FILE` is set in `.mise.toml`.

## Infrastructure Patterns

- **Managed Components**: Dragonfly and CNPG/Postgres instances are typically injected via Kustomize components in `app.ks.yaml`.
- **Configuration**: Use Flux `postBuild` variables within `app.ks.yaml` to configure these components.

## Key Tasks

- **Linting**: Use `task lint:check` to verify or `task lint` to auto-fix.
- **SOPS**: Use `task sops:encrypt` or `task sops:decrypt` for managing secrets.

## Repository Structure

- `apps/`: FluxCD resources (organized by domain, typically with `kustomization.yaml` and an `app/` sub-directory).
- `bootstrap/`: Cluster bootstrapping (Helmfile).
- `components/`: Reusable Kustomize components.
- `talos/`: Talos Linux cluster configuration.
- `.scripts/`: Operational scripts (SOPS, VolSync).
- `.agents/skills/`: Step-by-step skills for common tasks. Read the relevant skill before starting.

## Skills

- **Deploy a new app**: `.agents/skills/deploy-app.md` — adds a new application to the cluster using the bjw-s-labs app-template chart.
- **Migrate a CNPG cluster**: `.agents/skills/migrate-cnpg-cluster.md` — moves a Postgres cluster's data to a new namespace/name via backup → redeploy → recover (no in-place migration or auto-restore exists in CNPG).
- **Unlock a stuck VolSync backup**: `.agents/skills/volsync-unlock.md` — clears a stale restic repo lock (usually from apiserver flakiness killing the mover pod mid-`forget`) that otherwise loops backup Jobs forever.

## Critical Operational Notes

- **Secrets**: Always ensure secrets are encrypted before committing.
- **Validation**: Run `task lint:check` before submitting changes.
