#!/usr/bin/env bash
set -euo pipefail

WIDTH="${SUNSHINE_CLIENT_WIDTH:-2560}"
HEIGHT="${SUNSHINE_CLIENT_HEIGHT:-1440}"
FPS="${SUNSHINE_CLIENT_FPS:-60}"

OUTPUT=$(xrandr | awk '/ connected/{print $1; exit}')
MODENAME="${WIDTH}x${HEIGHT}"

# Try a mode that already exists (common resolutions are pre-built into the driver)
if xrandr --output "$OUTPUT" --mode "$MODENAME" 2>/dev/null; then
    echo "set $OUTPUT to existing mode $MODENAME"
    exit 0
fi

# Mode not available — generate a modeline with cvt and register it
CVTOUT=$(cvt "$WIDTH" "$HEIGHT" "$FPS")
NEWNAME=$(echo "$CVTOUT" | awk '/Modeline/{gsub(/"/, "", $2); print $2}')
PARAMS=$(echo "$CVTOUT"  | awk '/Modeline/{$1=$2=""; sub(/^  /, ""); print}')

xrandr --newmode "$NEWNAME" $PARAMS 2>/dev/null || true
xrandr --addmode "$OUTPUT" "$NEWNAME"
xrandr --output "$OUTPUT" --mode "$NEWNAME"
echo "added and set $OUTPUT to $NEWNAME"
