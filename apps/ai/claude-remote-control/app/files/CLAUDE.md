# Operating context: this is the homelab remote-control pod

You are running as the `claude-remote-control` pod in the `ai` namespace of
Mircea's homelab Kubernetes cluster (Flux-managed GitOps, repo `home-ops`).
This is **not** an ephemeral local session. You are a single always-on
`claude remote-control` server process, reachable as a device from the
Claude mobile app and claude.ai/code, restarted by Kubernetes whenever the
pod restarts (image update, node drain, crash, `kubectl rollout restart`).

## What persists across restarts, and what doesn't

- `~/.claude` (OAuth login, trust map, user-scope MCP servers) -- persistent
  volume, backed up off-cluster via VolSync. Survives restarts and node loss.
- `~/.mise` (mise's data/cache dir -- every tool mise installs) -- persistent
  volume, not backed up (fully rebuildable). Survives restarts, not node loss.
- Everything else under `$HOME`, including `~/workspace` -- ephemeral
  container filesystem. Cloned repos, scratch files, anything you write
  outside the two paths above disappears on restart. Don't treat it as
  durable; if something needs to survive, it belongs in a git remote, not
  this pod's local disk.

## Kubernetes access is real but read-only

`~/.kube/config` is a working kubeconfig for *this* cluster, scoped to the
`claude-remote-control` ServiceAccount bound to the built-in `view`
ClusterRole: cluster-wide `get`/`list`/`watch` on most resources, and
notably **no access to Secrets** and **no write access of any kind** --
`kubectl apply`, `kubectl delete`, `kubectl edit`, `kubectl exec`, `helm
install/upgrade`, etc. will all fail with a 403. Use it freely for reading
cluster state (`kubectl get`, `kubectl describe`, checking Flux
Kustomization/HelmRelease status, reading pod logs) but don't assume you can
change anything through it. If a task needs a change applied to the cluster,
the change goes through this repo (a Flux Kustomization/HelmRelease edit,
committed and pushed) and Flux reconciles it -- not a direct `kubectl`
mutation, which would fail anyway and would bypass GitOps even if it didn't.

This is deliberately the starting point, not the ceiling -- if broader
access turns out to be genuinely needed, that's a decision for Mircea to
make explicitly (edit `app/rbac.yaml` in this app's directory), not
something to route around from in here.

## Tool versions are never baked into this image

The container image (`ghcr.io/mirceanton/claude-remote-control`, built from
the `container-images` repo) intentionally ships almost nothing beyond
Node.js and the `claude` CLI itself. `kubectl`, `helm`, `flux`, `k9s`,
`talosctl`, `go`, and everything else resolve **per-repo**, from that
repo's own `mise.toml`, the moment you `cd` into it -- mise auto-installs
and auto-trusts on directory change (`MISE_YES`/`MISE_TRUSTED_CONFIG_PATHS`
are set for this), so you never need to run `mise trust` or `mise install`
by hand. This means the exact tool version available depends on which repo
you're standing in -- don't assume a version, check that repo's `mise.toml`
if it matters.

## Never point this at the LLM gateway

This cluster runs a LiteLLM/Envoy AI gateway (`litellm.ai.svc.cluster.local`,
`llm.home.mirceanton.com`) that other in-cluster tools use. This pod must
**never** be pointed at it: no `ANTHROPIC_BASE_URL`, no proxying Claude Code's
own traffic through it, in a session, a hook, or anything you write to
`~/.claude/settings.json`. Remote Control requires talking to
`api.anthropic.com` directly and refuses to start otherwise -- the image
sets none of the env vars that would break this
(`ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY`, `CLAUDE_CODE_USE_BEDROCK`,
`CLAUDE_CODE_USE_VERTEX`, `DISABLE_TELEMETRY`, `DO_NOT_TRACK`,
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, `DISABLE_GROWTHBOOK`), and a
`CiliumNetworkPolicy` on this pod backs that up at the network level. Treat
all of that as invariant, not configuration to "fix" if something seems
inconvenient.

## MCP servers

Configured out-of-band (mounted into `~/.claude.json` at boot from a
ConfigMap/Secret in this app's directory), not by you editing MCP config by
hand -- changes belong in that file in git, not in a live `claude mcp add`.

---

## Mircea: fill this in

<!--
Repos this pod typically works in (so it knows where to look without being
told each time), and any cluster conventions that aren't obvious purely
from the RBAC scope above -- Flux reconciliation expectations (e.g. "don't
wait on `flux reconcile`, it happens automatically within N minutes"),
naming patterns for new apps, which namespaces are safe to poke around in
vs. off-limits, where to look first when something's broken, anything else
you'd want a new teammate to know on day one.
-->
