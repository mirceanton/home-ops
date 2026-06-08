#!/usr/bin/env bash
set -euo pipefail

WIDTH="${DISPLAY_SIZEW:-2560}"
HEIGHT="${DISPLAY_SIZEH:-1440}"

OUTPUT=$(xrandr | awk '/ connected/{print $1; exit}')

xrandr --output "$OUTPUT" --mode "${WIDTH}x${HEIGHT}" 2>/dev/null || true
echo "restored $OUTPUT to ${WIDTH}x${HEIGHT}"
