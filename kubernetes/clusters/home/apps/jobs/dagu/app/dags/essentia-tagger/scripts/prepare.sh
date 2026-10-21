#!/usr/bin/env bash
# Step 1 — prepare: make sure the tracking file exists. Force truncates
# it only for a live run; a dry run must not discard prior progress.
set -euo pipefail

STATE_DIR="/var/lib/essentia"
PROCESSED_FILE="${STATE_DIR}/processed.txt"

mkdir -p "${STATE_DIR}/staging"

if [ "${ESSENTIA_FORCE:-false}" = "true" ] && [ "${ESSENTIA_DRY_RUN:-true}" = "false" ]; then
    echo "FORCE MODE: clearing tracking file to re-process entire library"
    : > "$PROCESSED_FILE"
else
    touch "$PROCESSED_FILE"
    echo "Tracking file ready ($(wc -l < "$PROCESSED_FILE") entries)."
fi