#!/usr/bin/env bash

export DISPLAY="${DISPLAY:-:0}"

WIDTH="${SUNSHINE_CLIENT_WIDTH:-2560}"
HEIGHT="${SUNSHINE_CLIENT_HEIGHT:-1440}"
FPS="${SUNSHINE_CLIENT_FPS:-60}"

OUTPUT=$(xrandr 2>/dev/null | awk '/ connected/{print $1; exit}')
if [ -z "$OUTPUT" ]; then
    echo "no connected xrandr output found, skipping"
    exit 0
fi

MODENAME="${WIDTH}x${HEIGHT}"

# Try an existing mode first (covers most standard resolutions)
if xrandr --output "$OUTPUT" --mode "$MODENAME" 2>/dev/null; then
    echo "set $OUTPUT to existing mode $MODENAME"
    exit 0
fi

# Mode not in driver list — generate via cvt and register it
CVTOUT=$(cvt "$WIDTH" "$HEIGHT" "$FPS" 2>/dev/null) || { echo "cvt failed, skipping"; exit 0; }
NEWNAME=$(echo "$CVTOUT" | awk '/Modeline/{gsub(/"/, "", $2); print $2}')
PARAMS=$(echo "$CVTOUT"  | awk '/Modeline/{$1=$2=""; sub(/^  /, ""); print}')

if [ -z "$NEWNAME" ]; then
    echo "could not parse cvt output, skipping"
    exit 0
fi

xrandr --newmode "$NEWNAME" $PARAMS 2>/dev/null || true
xrandr --addmode "$OUTPUT" "$NEWNAME" 2>/dev/null || true
xrandr --output  "$OUTPUT" --mode "$NEWNAME" 2>/dev/null || echo "could not apply mode $NEWNAME, continuing anyway"

exit 0
