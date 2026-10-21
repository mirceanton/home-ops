#!/usr/bin/env bash
# Step 4 — record: mark files only after a successful live tag step.
# Failed or dry runs leave files eligible for a later live run.
set -euo pipefail

PROCESSED_FILE="/var/lib/essentia/processed.txt"
LIST_FILE="/var/lib/essentia/staging/to-process.lst"

if [ "${ESSENTIA_DRY_RUN:-true}" != "false" ]; then
    echo "Dry run complete. Tracking file unchanged so files remain eligible for a live run."
    exit 0
fi

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