# Skill: Implement KRR Resource Recommendations

## Overview

Implement KRR resource recommendations from a GitHub issue into the repository's Helm manifests, then open (or update) a pull request summarizing what was changed, skipped, and failed.

---

## Step 1 — Find the KRR issue

Search the `mirceanton/home-ops` GitHub repository for the open issue whose title is "KRR Dashboard". Extract the full markdown table of recommendations.

---

## Step 2 — Parse the table

The table has these columns: Severity, Namespace, Workload, Container, CPU req, Mem req, Mem limit.

Cell format rules:

- `~~old~~ → **new**` — this field must be updated to `new`
- `~~unset~~ → **new**` — this field was absent and must be added (only if a `resources:` block already exists for this container)
- plain value with no arrow — this field requires no change; leave it exactly as-is
- a cell value of `—` or empty — skip this field entirely

Parse every row into a structured list before making any file changes.

---

## Step 3 — Prepare the branch

Check whether a branch named `automation/krr-resource-updates` already exists in the repository.

- If it exists: check it out and rebase it onto the latest `main`.
- If it does not exist: create it from `main`.

---

## Step 4 — Locate each manifest

The repository layout is `apps/<namespace>/<app-name>/app/helm-release.yaml`. Most workloads map directly.
If you cannot find a manifest after searching for it: record as **Failed** and move on.

---

## Step 5 — Apply changes

For each row that has at least one field requiring a change:

**Hard rules — no exceptions:**

- Set `resources.requests.cpu` to the new value when the table shows `~~old~~ → **new**`
- Set `resources.requests.memory` to the new value when the table shows `~~old~~ → **new**`
- Set `resources.limits.memory` to the new value when the table shows `~~old~~ → **new**`
- **NEVER set `resources.limits.cpu`.** If the file already contains `limits.cpu`, leave it exactly as-is. Never add it.
- If the container has **no `resources:` block at all** in the file: record as **Skipped** and do not create one.
- If a field shows `~~unset~~ → **new**` and the container already has a `resources:` block, add that specific field.
- If the table shows a plain value (no arrow) for a field: do not touch that field.

Use `yq` to make precise edits. Do not rewrite files, reorder keys, or strip comments.

The container path inside the HelmRelease values for app-template-based releases is:
`values.controllers.<controller-name>.containers.<container-name>.resources`

For operator-deployed workloads (cert-manager, metallb, kube-prometheus-stack, etc.) the path varies — read the file first and locate the resources block before editing.

---

## Step 6 — Commit

Stage all modified files and create a single commit:

```
feat(resources): apply KRR recommendations (<YYYY-MM-DD>)
```

Use today's date. Push to `automation/krr-resource-updates`.

---

## Step 7 — Open or update the pull request

If a PR for `automation/krr-resource-updates` already exists: update its body.
If not: open one targeting `main`.

Title: `feat(resources): apply KRR recommendations (<YYYY-MM-DD>)`

Body format (use this exactly):

```
## KRR Resource Recommendations — <YYYY-MM-DD>

Automated implementation of KRR suggestions from issue #<N>.

### ✅ Updated (<count>)

| Namespace | Workload | Container | CPU req | Mem req | Mem limit |
|---|---|---|---|---|---|
| ai | litellm | app | 10m → 381m | — | 2.0Gi → 1.5Gi |
...

### ⏭️ Skipped — no resources block in git (<count>)

| Namespace | Workload | Container | Reason |
|---|---|---|---|
| storage-system | democratic-csi-controller | external-attacher | No resources block found in helm-release.yaml |
...

### ❌ Failed — manifest not found (<count>)

| Namespace | Workload | Container | Reason |
|---|---|---|---|
...
```

If any list is empty, include the section header followed by "None."

In the Updated table, show only fields that actually changed. Use `—` for fields with no change.

---

## What NOT to do

- Do not close or comment on the KRR issue
- Do not create a `resources:` block where one does not exist
- Do not set `limits.cpu` under any circumstances
- Do not modify any file other than Helm manifests
- Do not edit workloads not present in the KRR table
- Do not proceed if the KRR issue cannot be found — report that clearly instead
