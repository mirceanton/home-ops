#!/usr/bin/env bash
# Step 2 — scan: compare the library against the tracking file and write
# the list of unprocessed files (NUL-separated relative paths) to the
# state PVC, where the tag step picks it up. Symlinks cannot be created
# here: each Dagu step is its own pod, so the staging tree must be built
# inside the tag pod's emptyDir.
set -euo pipefail

MUSIC_DIR="/music"
PROCESSED_FILE="/var/lib/essentia/processed.txt"
LIST_FILE="/var/lib/essentia/staging/to-process.lst"

echo "Scanning ${MUSIC_DIR} for unprocessed audio files..."

mkdir -p "$(dirname "$LIST_FILE")"
: > "$LIST_FILE"
count=0
while IFS= read -r -d '' file; do
    rel="${file#"$MUSIC_DIR"/}"
    if ! grep -qxF "$rel" "$PROCESSED_FILE" 2>/dev/null; then
        printf '%s\0' "$rel" >> "$LIST_FILE"
        count=$((count + 1))
    fi
done < <(find "$MUSIC_DIR" -type f \
    \( -iname '*.flac' -o -iname '*.mp3' -o -iname '*.ogg' -o -iname '*.oga' \
    -o -iname '*.opus' -o -iname '*.m4a' -o -iname '*.m4b' -o -iname '*.mp4' \
    -o -iname '*.aac' -o -iname '*.wav' -o -iname '*.aiff' -o -iname '*.aif' \
    -o -iname '*.wma' -o -iname '*.wv' -o -iname '*.ape' -o -iname '*.mpc' \
    -o -iname '*.mp+' -o -iname '*.dsf' \) -print0 2>/dev/null)

echo "Found ${count} unprocessed file(s). List written to ${LIST_FILE}."
