#!/usr/bin/env bash
# Step 3 — tag: symlink the unprocessed files (from the scan step's list)
# into a local temp dir and run the essentia entrypoint over it.
# ESSENTIA_DRY_RUN=false enables actual tag writing; anything else
# (including unset) stays in dry-run mode.
set -euo pipefail

MUSIC_DIR="/music"
TEMP_DIR="/tmp/to-process"
LIST_FILE="/var/lib/essentia/staging/to-process.lst"

if [ ! -s "$LIST_FILE" ]; then
    echo "No unprocessed files found. Nothing to do."
    exit 0
fi

count=$(tr -cd '\0' < "$LIST_FILE" | wc -c)
echo "Staging ${count} file(s) for analysis..."
mkdir -p "$TEMP_DIR"
while IFS= read -r -d '' rel; do
    target="$TEMP_DIR/$rel"
    mkdir -p "$(dirname "$target")"
    ln -s "$MUSIC_DIR/$rel" "$target"
done < "$LIST_FILE"

if [ "${ESSENTIA_DRY_RUN:-true}" = "false" ]; then
    DRY_RUN_FLAG=""
    echo "MODE: live (tags will be written to files)"
else
    DRY_RUN_FLAG="--dry-run"
    echo "MODE: dry-run (analyze only, no tags written)"
fi

echo "Running Essentia analysis. Arguments: $*"
exec python /app/docker-entrypoint.py \
    --model-dir /app/essentia_models \
    "$TEMP_DIR" \
    --auto \
    ${DRY_RUN_FLAG:+"$DRY_RUN_FLAG"} \
    "$@"
