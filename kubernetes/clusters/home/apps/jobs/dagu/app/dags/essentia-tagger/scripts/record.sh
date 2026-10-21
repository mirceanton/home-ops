#!/usr/bin/env bash
# Step 4 — record: mark every file from the scan step's list as processed
# in the tracking file. Only runs after the tag step succeeds, so a failed
# run leaves the files untracked and they get retried next time.
set -euo pipefail

PROCESSED_FILE="/var/lib/essentia/processed.txt"
LIST_FILE="/var/lib/essentia/staging/to-process.lst"

if [ ! -s "$LIST_FILE" ]; then
    echo "Nothing was processed. Tracking file unchanged."
    exit 0
fi

count=$(tr -cd '\0' < "$LIST_FILE" | wc -c)
while IFS= read -r -d '' rel; do
    echo "$rel" >> "$PROCESSED_FILE"
done < "$LIST_FILE"

# Deduplicate (files added by concurrent runs or aborted previous run)
sort -u -o "$PROCESSED_FILE" "$PROCESSED_FILE"
echo "Marked ${count} file(s) as processed."
