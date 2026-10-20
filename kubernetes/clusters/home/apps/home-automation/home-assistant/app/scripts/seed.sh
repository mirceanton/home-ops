#!/bin/sh
set -eu

# Seeds the git-managed Home Assistant config fragments into the /config PVC.
#
# Layout:
#   ${SEED_DIR}/seed.sh                    - this script (ConfigMap)
#   ${SEED_DIR}/gitops.<name>.yaml         - config fragments managed in git (ConfigMap)
#   ${CONFIG_DIR}/configuration.yaml       - HA main config, UI-managed (PVC)
#   ${CONFIG_DIR}/gitops/<name>.yaml       - fragments copied here at every start
#   ${CONFIG_DIR}/gitops/secrets.yaml      - rendered here at every start from
#                                            Kubernetes Secrets (never in git)
#
# HA resolves !secret relative to the folder of the referencing file first, so
# fragments in gitops/ pick up gitops/secrets.yaml and the PVC's own
# /config/secrets.yaml (if any) is never touched.
CONFIG_DIR="${CONFIG_DIR:-/config}"
SEED_DIR="${SEED_DIR:-/seed}"

GITOPS_DIR="${CONFIG_DIR}/gitops"
CONFIG_YAML="${CONFIG_DIR}/configuration.yaml"

echo "Seeding git-managed config fragments into ${GITOPS_DIR}"
mkdir -p "${GITOPS_DIR}"

# 1. Copy the git-managed fragments (kustomize flattens the ConfigMap keys to
#    gitops.<name>.yaml, dots replacing directories).
for f in "${SEED_DIR}"/gitops.*.yaml; do
  [ -e "${f}" ] || continue
  name=$(basename "${f}" | sed 's/^gitops\.//')
  echo "  Installing fragment: ${name}"
  cp "${f}" "${GITOPS_DIR}/${name}"
done

# 2. Render gitops/secrets.yaml from Kubernetes Secrets mounted as env vars.
#    Single-quoted YAML with '' escaping so any secret value stays literal.
umask 077
render_secret() {
  key="$1"
  value="$2"
  escaped=$(printf '%s' "${value}" | sed "s/'/''/g")
  printf "%s: '%s'\n" "${key}" "${escaped}"
}
{
  render_secret oidc_client_id "${OIDC_CLIENT_ID}"
  render_secret oidc_client_secret "${OIDC_CLIENT_SECRET}"
} >"${GITOPS_DIR}/secrets.yaml"
chmod 600 "${GITOPS_DIR}/secrets.yaml"
echo "  Rendered secrets.yaml"

# 3. Idempotently wire the fragments into the main configuration.yaml. The PVC
#    file stays authoritative for everything the HA UI manages; we only ever
#    append missing top-level include lines.
if [ ! -f "${CONFIG_YAML}" ]; then
  echo "  No configuration.yaml found, creating a minimal one"
  printf '# Created by the home-ops config seed\ndefault_config:\n' >"${CONFIG_YAML}"
fi

ensure_include() {
  key="$1"
  include="$2"
  if ! grep -Eq "^${key}:" "${CONFIG_YAML}"; then
    echo "  Adding '${key}: !include ${include}' to configuration.yaml"
    printf '\n%s: !include %s\n' "${key}" "${include}" >>"${CONFIG_YAML}"
  fi
}

ensure_include auth_oidc gitops/auth_oidc.yaml

echo "Seed complete"
