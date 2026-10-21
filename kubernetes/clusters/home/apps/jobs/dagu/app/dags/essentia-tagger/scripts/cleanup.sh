#!/usr/bin/env bash
# Step 5 — cleanup: remove the staging list so the next run starts fresh.
# Wired as both a final step and a failure handler.
set -euo pipefail

STAGING_DIR="/var/lib/essentia/staging"

rm -f "${STAGING_DIR}/to-process.lst"
echo "Staging list removed."
