#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  Independent Dual-Monitor Workspace Dispatcher
# ──────────────────────────────────────────────────────────────
set -euo pipefail

ACTION="${1:-}"
NUM="${2:-}"

if [[ -z "$ACTION" || -z "$NUM" ]]; then
    echo "Usage: $0 <switch|move> <0-9>" >&2
    exit 1
fi

if ! [[ "$NUM" =~ ^[0-9]$ ]]; then
    echo "Error: Invalid workspace number '$NUM'. Must be a single digit 0-9." >&2
    exit 1
fi

# Detect currently focused monitor
FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

if [[ -z "$FOCUSED_MONITOR" || "$FOCUSED_MONITOR" == "null" ]]; then
    echo "Error: Could not determine focused monitor." >&2
    exit 1
fi

# Map 0 to 10th slot
if [[ "$NUM" -eq 0 ]]; then
    SLOT=10
else
    SLOT="$NUM"
fi

# Monitor A (eDP-1) -> 1..10, Monitor B (HDMI-A-2) -> 11..20
case "$FOCUSED_MONITOR" in
    "eDP-1")
        TARGET_WS="$SLOT"
        ;;
    "HDMI-A-2")
        TARGET_WS=$(( 10 + SLOT ))
        ;;
    *)
        echo "Error: Unknown monitor '$FOCUSED_MONITOR'." >&2
        exit 1
        ;;
esac

case "$ACTION" in
    switch)
        hyprctl dispatch workspace "$TARGET_WS"
        ;;
    move)
        hyprctl dispatch movetoworkspace "$TARGET_WS"
        ;;
    *)
        echo "Error: Unknown action '$ACTION'. Supported actions: switch, move." >&2
        exit 1
        ;;
esac
