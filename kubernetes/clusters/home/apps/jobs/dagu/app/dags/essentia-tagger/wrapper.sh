#!/bin/bash
# Wrapper that processes only audio files not yet recorded in the tracking
# file. Set ESSENTIA_FORCE=true to clear the tracking file and re-process
# the entire library.
#
# Usage:
#   /bin/bash /scripts/wrapper.sh [--dry-run] [--genres N] [--overwrite] ...
#
# The MUSIC_DIR is expected at /music (NFS mount).
# The state file lives at /var/lib/essentia/processed.txt (PVC).

set -euo pipefail

PROCESSED_FILE="/var/lib/essentia/processed.txt"
MUSIC_DIR="/music"
TEMP_DIR="/tmp/to-process"
LOG_DIR="/var/log/essentia"

# --- force re-process -------------------------------------------------
if [ "${ESSENTIA_FORCE:-false}" = "true" ]; then
    echo "FORCE MODE: clearing processed-file to re-process entire library"
    : > "$PROCESSED_FILE"
fi

# --- ensure state file exists -----------------------------------------
mkdir -p "$(dirname "$PROCESSED_FILE")"
touch "$PROCESSED_FILE"

# --- collect unprocessed files ----------------------------------------
echo "Scanning for unprocessed audio files..."
mkdir -p "$TEMP_DIR"

count=0
while IFS= read -r -d '' file; do
    rel="${file#$MUSIC_DIR/}"
    if ! grep -qxF "$rel" "$PROCESSED_FILE" 2>/dev/null; then
        target="$TEMP_DIR/$rel"
        mkdir -p "$(dirname "$target")"
        ln -s "$file" "$target"
        count=$((count + 1))
    fi
done < <(find "$MUSIC_DIR" -type f \
    \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.ogg' -o -iname '*.oga' \
    -o -iname '*.opus' -o -iname '*.m4a' -o -iname '*.m4b' -o -iname '*.mp4' \
    -o -iname '*.aac' -o -iname '*.wav' -o -iname '*.aiff' -o -iname '*.aif' \
    -o -iname '*.wma' -o -iname '*.wv' -o -iname '*.ape' -o -iname '*.mpc' \
    -o -iname '*.mp+' -o -iname '*.dsf' \) -print0 2>/dev/null)

if [ "$count" -eq 0 ]; then
    echo "No unprocessed files found. Nothing to do."
    exit 0
fi

# --- run essentia on the temp directory --------------------------------
echo "Found ${count} unprocessed file(s). Running Essentia analysis..."
echo "Arguments: $*"

python /app/docker-entrypoint.py \
    --model-dir /app/essentia_models \
    "$TEMP_DIR" \
    --auto \
    "$@"

exit_code=$?

# --- update tracking file on success ----------------------------------
if [ "$exit_code" -eq 0 ]; then
    while IFS= read -r -d '' file; do
        rel="${file#$MUSIC_DIR/}"
        echo "$rel" >> "$PROCESSED_FILE"
    done < <(find "$TEMP_DIR" -type l -print0 2>/dev/null)

    # Deduplicate (files added by concurrent runs or aborted previous run)
    sort -u -o "$PROCESSED_FILE" "$PROCESSED_FILE"
    echo "Marked ${count} file(s) as processed."

    # Log what was written
    if [ -f "$LOG_DIR"/*.log ]; then
        echo "--- Essentia log follows ---"
        cat "$LOG_DIR"/*.log
    fi
fi

# --- cleanup -----------------------------------------------------------
rm -rf "$TEMP_DIR"
echo "Done (exit code ${exit_code})."
exit "$exit_code"
