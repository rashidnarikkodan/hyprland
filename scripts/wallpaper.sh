#!/usr/bin/env bash

# ==============================================================================
# Dynamic Wallpaper Management System for Hyprland (Wayland)
# - Fully compatible with Hyprpaper v0.8+ (per-monitor IPC)
# - Extracts dynamic vibrant color palettes via ImageMagick
# - Real-time theming for Hyprland borders, Waybar, Kitty, Hyprlock, Mako
# - Integrates with fuzzel dmenu, fzf terminal picker, and CLI commands
# ==============================================================================

# Wallpaper directory (supports both ~/Pictures/wallpapers and ~/pictures/wallpapers)
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
if [ ! -d "$WALLPAPER_DIR" ] && [ -d "$HOME/pictures/wallpapers" ]; then
    WALLPAPER_DIR="$HOME/pictures/wallpapers"
fi

CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"
COLORS_FILE="$HOME/.config/hypr/config/colors.conf"
COLORS_CSS="$HOME/.config/hypr/config/colors.css"
KITTY_COLORS="$HOME/.config/kitty/colors-kitty.conf"
LOCK_FILE="$HOME/.config/hypr/hyprlock.conf"
PID_FILE="/tmp/hypr_wallpaper_daemon.pid"

# Ensure directories exist
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$(dirname "$COLORS_FILE")"
mkdir -p "$(dirname "$KITTY_COLORS")"

# Discover wallpapers (supported formats: png, jpg, jpeg, webp)
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "Error: No wallpapers found in $WALLPAPER_DIR" >&2
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Wallpaper System" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Ensure hyprpaper daemon is active
ensure_hyprpaper() {
    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
        hyprpaper >/dev/null 2>&1 &
        sleep 0.4
    fi
}

# Query all connected monitor names
get_monitors() {
    local mons=""
    if command -v jq >/dev/null 2>&1; then
        mons=$(hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null)
    fi
    if [ -z "$mons" ]; then
        mons=$(hyprctl monitors 2>/dev/null | awk '/Monitor/{print $2}')
    fi
    echo "$mons"
}

# Function to brighten a color for readable terminal text contrast
brighten_color() {
    local col="$1"
    local r=$((16#${col:0:2}))
    local g=$((16#${col:2:2}))
    local b=$((16#${col:4:2}))
    local max=$r; [ $g -gt $max ] && max=$g; [ $b -gt $max ] && max=$b
    if [ $max -eq 0 ]; then
        echo "e0e0e0"
        return
    fi
    local target_max=220
    if [ $max -lt $target_max ]; then
        r=$(( r * target_max / max ))
        g=$(( g * target_max / max ))
        b=$(( b * target_max / max ))
        [ $r -gt 255 ] && r=255
        [ $g -gt 255 ] && g=255
        [ $b -gt 255 ] && b=255
    fi
    printf "%02x%02x%02x" $r $g $b
}

# Function to apply wallpaper and color extraction
apply_wallpaper() {
    local wp_path="$1"
    
    if [ ! -f "$wp_path" ]; then
        echo "Error: Wallpaper file does not exist: $wp_path" >&2
        return 1
    fi

    # 1. Ensure hyprpaper is running and set wallpaper on ALL monitors via IPC
    ensure_hyprpaper
    local mons
    mons=$(get_monitors)

    if [ -n "$mons" ]; then
        while IFS= read -r mon; do
            if [ -n "$mon" ]; then
                hyprctl hyprpaper wallpaper "$mon,$wp_path" >/dev/null 2>&1
            fi
        done <<< "$mons"
    else
        hyprctl hyprpaper wallpaper ",$wp_path" >/dev/null 2>&1
    fi

    # 2. Extract dominant colors using ImageMagick thumbnail for high-speed analysis (<150ms)
    local color1=""
    local color2=""
    
    if command -v magick >/dev/null 2>&1; then
        mapfile -t HIST_COLORS < <(magick "$wp_path" -thumbnail 300x300 +dither -colors 16 -format "%c" histogram:info: 2>/dev/null | sort -n -r | awk -F"#" '{print $2}' | awk '{print $1}')
        
        local candidates=()
        for col in "${HIST_COLORS[@]}"; do
            [ -z "$col" ] && continue
            local r=$((16#${col:0:2}))
            local g=$((16#${col:2:2}))
            local b=$((16#${col:4:2}))
            
            local min=$r
            [ $g -lt $min ] && min=$g
            [ $b -lt $min ] && min=$b
            
            local max=$r
            [ $g -gt $max ] && max=$g
            [ $b -gt $max ] && max=$b
            
            local sat=$(( max - min ))
            local brightness=$(( r + g + b ))
            
            if [ $sat -gt 40 ] && [ $brightness -gt 200 ] && [ $brightness -lt 660 ]; then
                candidates+=("$sat $col")
            fi
        done
        
        if [ ${#candidates[@]} -gt 0 ]; then
            mapfile -t SORTED_CANDIDATES < <(printf "%s\n" "${candidates[@]}" | sort -n -r | awk '{print $2}')
            color1="${SORTED_CANDIDATES[0]}"
            color2="${SORTED_CANDIDATES[1]}"
        fi
        
        if [ -z "$color1" ] || [ -z "$color2" ]; then
            local candidates2=()
            for col in "${HIST_COLORS[@]}"; do
                [ -z "$col" ] && continue
                local r=$((16#${col:0:2}))
                local g=$((16#${col:2:2}))
                local b=$((16#${col:4:2}))
                local min=$r; [ $g -lt $min ] && min=$g; [ $b -lt $min ] && min=$b
                local max=$r; [ $g -gt $max ] && max=$g; [ $b -gt $max ] && max=$b
                local sat=$(( max - min ))
                local brightness=$(( r + g + b ))
                
                if [ $brightness -gt 150 ] && [ $brightness -lt 720 ]; then
                    candidates2+=("$sat $col")
                fi
            done
            if [ ${#candidates2[@]} -gt 0 ]; then
                mapfile -t SORTED_CANDIDATES2 < <(printf "%s\n" "${candidates2[@]}" | sort -n -r | awk '{print $2}')
                [ -z "$color1" ] && color1="${SORTED_CANDIDATES2[0]}"
                [ -z "$color2" ] && color2="${SORTED_CANDIDATES2[1]}"
            fi
        fi
    fi

    # Fallback default vibrant accents if extraction returned empty
    [ -z "$color1" ] && color1="cba6f7"
    [ -z "$color2" ] && color2="89b4fa"

    # 3. Apply active border colors dynamically in Hyprland
    hyprctl keyword general:col.active_border "rgba(${color1}ee) rgba(${color2}ee) 45deg" >/dev/null 2>&1
    hyprctl keyword general:col.inactive_border "rgba(${color1}33)" >/dev/null 2>&1

    # 4. Persist colors to colors.conf
    cat <<EOF > "$COLORS_FILE"
\$active_border_color_1 = rgba(${color1}ee)
\$active_border_color_2 = rgba(${color2}ee)
\$inactive_border_color = rgba(${color1}33)
EOF

    # 4b. Persist colors as CSS variables for Waybar
    cat <<EOF > "$COLORS_CSS"
@define-color color1 #${color1};
@define-color color2 #${color2};
EOF

    # 4c. Persist colors for Kitty terminal
    local text_color1
    local text_color2
    text_color1=$(brighten_color "$color1")
    text_color2=$(brighten_color "$color2")

    local bg_r=$(( (16#${color1:0:2}) * 8 / 100 + 10 ))
    local bg_g=$(( (16#${color1:2:2}) * 8 / 100 + 8 ))
    local bg_b=$(( (16#${color1:4:2}) * 8 / 100 + 12 ))
    local dark_bg
    dark_bg=$(printf "%02x%02x%02x" $bg_r $bg_g $bg_b)

    cat <<EOF > "$KITTY_COLORS"
# Dynamic Colors (Autogenerated from wallpaper)
background            #${dark_bg}
background_opacity    1.0
foreground            #cdd6f4
selection_background  #${text_color1}
selection_foreground  #${dark_bg}
url_color             #${text_color2}
cursor                #${text_color1}
cursor_text_color     #${dark_bg}

# Tab Bar
active_tab_background   #${text_color1}
active_tab_foreground   #${dark_bg}
inactive_tab_background #${dark_bg}
inactive_tab_foreground #${text_color2}

# Border colors
active_border_color   #${text_color1}
inactive_border_color #${dark_bg}

# Terminal accents
color4  #${text_color2}
color12 #${text_color2}
color5  #${text_color1}
color13 #${text_color1}
color6  #${text_color2}
color14 #${text_color2}
EOF

    # 5. Persist the change to hyprpaper.conf
    cat <<EOF > "$CONFIG_FILE"
splash = false

wallpaper {
    monitor = 
    path = $wp_path
}
EOF

    # 6. Update hyprlock.conf
    cat <<EOF > "$LOCK_FILE"
# Hyprland Lock Screen Configuration (hyprlock)
background {
    monitor =
    path = $wp_path
    blur_size = 4
    blur_passes = 3
}

input-field {
    monitor =
    size = 250, 50
    outline_thickness = 3
    dots_size = 0.2
    dots_spacing = 0.64
    outer_color = rgb($color1)
    inner_color = rgb(1e1e2e)
    font_color = rgb($color2)
    fade_on_empty = false
}
EOF

    # 7. Update Mako notification theme dynamically
    if [ -f "$HOME/.config/mako/config" ]; then
        sed -i "s/^border-color=.*/border-color=#${color1}ee/" "$HOME/.config/mako/config" 2>/dev/null || true
        sed -i "s/^progress-color=.*/progress-color=over #${color2}ee/" "$HOME/.config/mako/config" 2>/dev/null || true
        command -v makoctl >/dev/null 2>&1 && makoctl reload >/dev/null 2>&1 || true
    fi

    # 8. Reload Waybar and Kitty config to apply dynamic theme instantly
    pkill -USR2 waybar >/dev/null 2>&1 || true

    # Apply colors live to all running Kitty instances via socket
    for sock in /tmp/kitty* /tmp/mykitty*; do
        if [ -S "$sock" ]; then
            kitty @ --to "unix:$sock" set-colors --all --configured "$KITTY_COLORS" >/dev/null 2>&1 || true
        fi
    done
    kitty @ set-colors --all --configured "$KITTY_COLORS" >/dev/null 2>&1 || true

    # Touch main config so file watchers trigger and send SIGUSR1 reload signal
    touch "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
    pkill -USR1 kitty >/dev/null 2>&1 || true

    # Notification & Terminal message
    local wp_name
    wp_name=$(basename "$wp_path")
    echo "Applied: $wp_name (Theme: #$color1 / #$color2)"
    command -v notify-send >/dev/null 2>&1 && notify-send -h string:x-canonical-private-synchronous:wallpaper "Wallpaper System" "Applied: $wp_name\nColor Scheme: #$color1 & #$color2"
}

# Get current active wallpaper path
get_current_wallpaper() {
    local cur=""
    if [ -f "$CONFIG_FILE" ]; then
        cur=$(grep -E "^\s*path\s*=" "$CONFIG_FILE" | head -n 1 | cut -d'=' -f2 | xargs)
    fi
    echo "$cur"
}

# Interactive wallpaper picker (Fuzzel GUI / FZF Terminal / Wofi / Rofi)
select_wallpaper() {
    local options=()
    local cur
    cur=$(get_current_wallpaper)
    local cur_name
    cur_name=$(basename "$cur")

    for wp in "${WALLPAPERS[@]}"; do
        local name
        name=$(basename "$wp")
        options+=("$name")
    done
    
    local selected=""

    # 1. Interactive terminal mode (if run inside terminal with fzf)
    if [ -t 0 ] && [ -t 1 ] && command -v fzf >/dev/null 2>&1; then
        selected=$(printf "%s\n" "${options[@]}" | fzf --prompt="󰸉 Select Wallpaper > " --header="Current: $cur_name" --height=45% --reverse)
    # 2. Wayland GUI mode via Walker (modern native high-performance launcher)
    elif command -v walker >/dev/null 2>&1; then
        selected=$(printf "%s\n" "${options[@]}" | walker --dmenu --placeholder "󰸉 Select Wallpaper...")
    # 3. Fallbacks for Fuzzel, Wofi, Rofi
    elif command -v fuzzel >/dev/null 2>&1; then
        local lines="${#options[@]}"
        [ $lines -gt 15 ] && lines=15
        selected=$(printf "%s\n" "${options[@]}" | fuzzel --dmenu --prompt="󰸉 Wallpaper: " --lines="$lines" --width=35)
    elif command -v wofi >/dev/null 2>&1; then
        selected=$(printf "%s\n" "${options[@]}" | wofi --dmenu --prompt "Select Wallpaper" --width 400 --height 350)
    elif command -v rofi >/dev/null 2>&1; then
        selected=$(printf "%s\n" "${options[@]}" | rofi -dmenu -p "Select Wallpaper")
    else
        echo "Available Wallpapers in $WALLPAPER_DIR:"
        for i in "${!options[@]}"; do
            echo "  [$((i+1))] ${options[$i]}"
        done
        read -r -p "Enter number: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            selected="${options[$((choice-1))]}"
        fi
    fi
    
    if [ -n "$selected" ]; then
        for wp in "${WALLPAPERS[@]}"; do
            if [ "$(basename "$wp")" = "$selected" ]; then
                apply_wallpaper "$wp"
                break
            fi
        done
    fi
}

# Cycle to next wallpaper
next_wallpaper() {
    local current_wp
    current_wp=$(get_current_wallpaper)
    
    local index=0
    if [ -n "$current_wp" ]; then
        for i in "${!WALLPAPERS[@]}"; do
            if [ "${WALLPAPERS[$i]}" = "$current_wp" ]; then
                index=$(( (i + 1) % ${#WALLPAPERS[@]} ))
                break
            fi
        done
    fi
    
    apply_wallpaper "${WALLPAPERS[$index]}"
}

# Cycle to previous wallpaper
prev_wallpaper() {
    local current_wp
    current_wp=$(get_current_wallpaper)
    
    local count=${#WALLPAPERS[@]}
    local index=0
    if [ -n "$current_wp" ]; then
        for i in "${!WALLPAPERS[@]}"; do
            if [ "${WALLPAPERS[$i]}" = "$current_wp" ]; then
                index=$(( (i - 1 + count) % count ))
                break
            fi
        done
    fi
    
    apply_wallpaper "${WALLPAPERS[$index]}"
}

# Choose a random wallpaper
random_wallpaper() {
    local count=${#WALLPAPERS[@]}
    local rand_idx=$(( RANDOM % count ))
    apply_wallpaper "${WALLPAPERS[$rand_idx]}"
}

# Set wallpaper directly by name or path
set_wallpaper_by_arg() {
    local target="$1"
    if [ -z "$target" ]; then
        echo "Usage: $(basename "$0") set <filename_or_path>" >&2
        return 1
    fi

    # Direct path
    if [ -f "$target" ]; then
        apply_wallpaper "$(realpath "$target")"
        return 0
    fi

    # Search in wallpaper directory
    if [ -f "$WALLPAPER_DIR/$target" ]; then
        apply_wallpaper "$WALLPAPER_DIR/$target"
        return 0
    fi

    # Match by partial basename
    for wp in "${WALLPAPERS[@]}"; do
        if [[ "$(basename "$wp")" =~ ^"$target" ]] || [[ "$(basename "$wp")" == "$target" ]]; then
            apply_wallpaper "$wp"
            return 0
        fi
    done

    echo "Error: Wallpaper '$target' not found in $WALLPAPER_DIR" >&2
    return 1
}

# List all wallpapers
list_wallpapers() {
    local current_wp
    current_wp=$(get_current_wallpaper)
    
    echo "Wallpapers in $WALLPAPER_DIR (${#WALLPAPERS[@]} total):"
    for wp in "${WALLPAPERS[@]}"; do
        local name
        name=$(basename "$wp")
        if [ "$wp" = "$current_wp" ]; then
            echo "  * $name [ACTIVE]"
        else
            echo "    $name"
        fi
    done
}

# Start slideshow daemon
start_daemon() {
    local interval="${1:-300}"
    stop_daemon quiet
    
    echo "Starting wallpaper slideshow daemon with ${interval}s interval..."
    (
        while true; do
            sleep "$interval"
            next_wallpaper
        done
    ) &
    
    echo $! > "$PID_FILE"
    command -v notify-send >/dev/null 2>&1 && notify-send "Wallpaper System" "Slideshow daemon started (${interval}s interval)"
}

# Stop slideshow daemon
stop_daemon() {
    local quiet="$1"
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
        if [ "$quiet" != "quiet" ]; then
            echo "Slideshow daemon stopped."
            command -v notify-send >/dev/null 2>&1 && notify-send "Wallpaper System" "Slideshow daemon stopped"
        fi
    else
        if [ "$quiet" != "quiet" ]; then
            echo "No slideshow daemon is currently running."
        fi
    fi
}

# Status of wallpaper & daemon
status_daemon() {
    local cur
    cur=$(get_current_wallpaper)
    echo "Current Wallpaper: ${cur:-None configured}"
    
    local mons
    mons=$(get_monitors | tr '\n' ' ')
    echo "Active Monitors:   $mons"

    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
            echo "Slideshow Daemon:  Active (PID: $pid)"
            return 0
        fi
    fi
    echo "Slideshow Daemon:  Inactive"
    return 0
}

# Show help
show_help() {
    cat <<EOF
Wallpaper Management Tool (Hyprland / Wayland)
Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
  (no args)             Open interactive wallpaper picker (Fuzzel GUI or FZF terminal)
  --select, -s          Open interactive wallpaper picker
  --next, -n            Cycle to next wallpaper
  --prev, -p            Cycle to previous wallpaper
  --random, -r          Set a random wallpaper
  --set <file>, set     Set specific wallpaper by name or path
  --list, -l            List all available wallpapers and current active
  --status              Show active wallpaper, monitors, and daemon state
  --daemon [secs]       Start automatic slideshow daemon (default: 300s)
  --toggle-daemon       Toggle automatic slideshow daemon on/off
  --stop                Stop automatic slideshow daemon
  --help, -h            Show this help message

Keybinds in Hyprland:
  Super + Shift + W     Open wallpaper picker
  Super + Ctrl  + W     Next wallpaper
  Super + Alt   + W     Toggle slideshow daemon

Wallpaper Directory:
  $WALLPAPER_DIR
EOF
}

# Parse CLI arguments
case "$1" in
    --next|-n|next)
        next_wallpaper
        ;;
    --prev|-p|prev)
        prev_wallpaper
        ;;
    --random|-r|random)
        random_wallpaper
        ;;
    --set|set)
        set_wallpaper_by_arg "$2"
        ;;
    --list|-l|list)
        list_wallpapers
        ;;
    --status|status)
        status_daemon
        ;;
    --daemon|daemon)
        start_daemon "$2"
        ;;
    --toggle-daemon|toggle)
        if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE" 2>/dev/null)" > /dev/null 2>&1; then
            stop_daemon
        else
            start_daemon "$2"
        fi
        ;;
    --stop|stop)
        stop_daemon
        ;;
    --help|-h|help)
        show_help
        ;;
    --select|-s|select|"")
        select_wallpaper
        ;;
    *)
        # If passed an existing wallpaper directly
        if [ -f "$1" ] || [ -f "$WALLPAPER_DIR/$1" ]; then
            set_wallpaper_by_arg "$1"
        else
            echo "Unknown argument: $1"
            show_help
            exit 1
        fi
        ;;
esac
