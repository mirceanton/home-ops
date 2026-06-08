#!/usr/bin/env bash

export DISPLAY="${DISPLAY:-:0}"

WIDTH="${DISPLAY_SIZEW:-2560}"
HEIGHT="${DISPLAY_SIZEH:-1440}"

OUTPUT=$(xrandr 2>/dev/null | awk '/ connected/{print $1; exit}')
if [ -z "$OUTPUT" ]; then
    echo "no connected xrandr output found, skipping"
    exit 0
fi

xrandr --output "$OUTPUT" --mode "${WIDTH}x${HEIGHT}" 2>/dev/null || echo "could not restore mode ${WIDTH}x${HEIGHT}, continuing anyway"

exit 0
