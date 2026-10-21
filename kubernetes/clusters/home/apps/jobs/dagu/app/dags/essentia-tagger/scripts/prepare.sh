#!/usr/bin/env bash
# Step 1 — prepare: make sure the tracking file exists. When the Force
# checkbox is set, truncate it so every file in the library is treated
# as unprocessed by the scan step.
set -euo pipefail

STATE_DIR="/var/lib/essentia"
PROCESSED_FILE="${STATE_DIR}/processed.txt"

mkdir -p "${STATE_DIR}/staging"

if [ "${ESSENTIA_FORCE:-false}" = "true" ]; then
    echo "FORCE MODE: clearing tracking file to re-process entire library"
    : > "$PROCESSED_FILE"
else
    touch "$PROCESSED_FILE"
    echo "Tracking file ready ($(wc -l < "$PROCESSED_FILE") entries)."
fi
