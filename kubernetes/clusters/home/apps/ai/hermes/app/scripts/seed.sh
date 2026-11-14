#!/bin/sh
set -eu

# =================================================================================================
# Seed Policy — CONFIG IS MANUAL (PVC-managed)
# =================================================================================================
# config.yaml and SOUL.md are NO LONGER seeded from the repo. They live only on the PVC and are
# edited by hand (or by Hermes at runtime); container restarts and rollouts leave them untouched.
# This init container now renders SECRETS ONLY.
#
# .env is re-rendered on every boot because it carries secrets that must be refreshed from the
# cluster Secret. The root .env gets LITELLM_API_KEY; each profile .env is rendered from its
# .env.template via `flux envsubst`.
#
# To bring config back under GitOps later, re-add the config.yaml/SOUL.md files to the hermes-config
# ConfigMap and restore a seed step here. Until then the repo intentionally does not manage runtime
# config — a fresh PVC will start from Hermes' built-in defaults and must be configured manually.

# =================================================================================================
# Default Profile — secrets only
# =================================================================================================
# .env is always re-rendered and never preserved: it carries secrets and has to be refreshed
# from the Secret on every boot.
touch /opt/data/.env
sed -i '/^DISCORD_/d; /^LITELLM_/d' /opt/data/.env

# The launch profile's own config declares `providers.litellm.key_env: LITELLM_API_KEY`, and under
# multiplexing a profile-scoped lookup miss returns "" instead of falling back to os.environ — so
# without this the aux/vision client resolves no key on every gateway start. Write it from the
# init container's env, which the HelmRelease already sources from the hermes-litellm-key secret.
printf 'LITELLM_API_KEY=%s\n' "$LITELLM_API_KEY" >> /opt/data/.env
chmod 600 /opt/data/.env

# =================================================================================================
# Per-Profile Setup — secrets only
# =================================================================================================
# Discover profiles by their .env.template (the only per-profile file still shipped in the
# ConfigMap). config.yaml/SOUL.md are managed manually on the PVC and are not touched here.
for f in /seed/profiles.*.env.template; do
  name=$(basename "$f" .env.template | sed 's/^profiles\.//')
  echo "Rendering secrets for profile: $name"

  mkdir -p "/opt/data/profiles/$name"

  # Per-profile .env is always re-rendered from its template, same secrets rule as the default .env.
  flux envsubst --strict < "/seed/profiles.$name.env.template" > "/opt/data/profiles/$name/.env"
  chmod 600 "/opt/data/profiles/$name/.env"
done

# =================================================================================================
# Tooling Setup
# =================================================================================================
mkdir -p /opt/data/.local/bin
ln -sfn /opt/mise/mise /opt/data/.local/bin/mise
