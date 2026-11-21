#!/usr/bin/env bash
# Script to manage hyprexpose overview reliably

ACTION="${1:-toggle}"

is_open() {
    hyprctl layers 2>/dev/null | grep -q "namespace: hyprexpose"
}

is_running() {
    pgrep -x hyprexpose >/dev/null
}

case "$ACTION" in
    open)
        if ! is_open; then
            if is_running; then
                pkill -SIGUSR1 hyprexpose
            else
                hyprexpose --allow-mouse &
            fi
        fi
        ;;
    close)
        if is_open; then
            pkill -SIGUSR1 hyprexpose
        fi
        ;;
    toggle)
        if is_running; then
            pkill -SIGUSR1 hyprexpose
        else
            hyprexpose --allow-mouse &
        fi
        ;;
    *)
        echo "Usage: $0 {open|close|toggle}" >&2
        exit 1
        ;;
esac
