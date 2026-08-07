#!/usr/bin/env bash

# Wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"
COLORS_FILE="$HOME/.config/hypr/config/colors.conf"
LOCK_FILE="$HOME/.config/hypr/hyprlock.conf"
PID_FILE="/tmp/hypr_wallpaper_daemon.pid"

# Ensure wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir -p "$WALLPAPER_DIR"
fi

# Get list of wallpapers (supported formats: png, jpg, jpeg, webp)
mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send "Wallpaper System" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Function to apply wallpaper and color extraction
apply_wallpaper() {
    local wp_path="$1"
    
    # 1. Set the new wallpaper dynamically on all monitors
    hyprctl hyprpaper wallpaper ",$wp_path"
    
    # 2. Extract dominant colors using ImageMagick histogram & sort by vibrancy (saturation)
    local color1 color2
    
    # Extract top 16 colors from the histogram
    mapfile -t HIST_COLORS < <(magick "$wp_path" +dither -colors 16 -format "%c" histogram:info: 2>/dev/null | sort -n -r | awk -F"#" '{print $2}' | awk '{print $1}')
    
    # Filter and rank by saturation and brightness
    local candidates=()
    for col in "${HIST_COLORS[@]}"; do
        [ -z "$col" ] && continue
        # Extract RGB hex
        local r=$((16#${col:0:2}))
        local g=$((16#${col:2:2}))
        local b=$((16#${col:4:2}))
        
        # Calculate saturation: max(R,G,B) - min(R,G,B)
        local min=$r
        [ $g -lt $min ] && min=$g
        [ $b -lt $min ] && min=$b
        
        local max=$r
        [ $g -gt $max ] && max=$g
        [ $b -gt $max ] && max=$b
        
        local sat=$(( max - min ))
        local brightness=$(( r + g + b ))
        
        # Filter: Saturation > 40, brightness between 200 and 660
        if [ $sat -gt 40 ] && [ $brightness -gt 200 ] && [ $brightness -lt 660 ]; then
            candidates+=("$sat $col")
        fi
    done
    
    # Sort candidates by saturation descending
    if [ ${#candidates[@]} -gt 0 ]; then
        mapfile -t SORTED_CANDIDATES < <(printf "%s\n" "${candidates[@]}" | sort -n -r | awk '{print $2}')
        color1="${SORTED_CANDIDATES[0]}"
        color2="${SORTED_CANDIDATES[1]}"
    fi
    
    # Fallback if less than 2 candidates found, try lower constraints
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
    
    # Final fallback if still empty
    if [ -z "$color1" ]; then color1="cba6f7"; fi
    if [ -z "$color2" ]; then color2="89b4fa"; fi
    
    # 3. Apply active border colors instantly via IPC (smooth transition)
    hyprctl keyword general:col.active_border "rgba(${color1}ee) rgba(${color2}ee) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(${color1}33)"
    
    # 4. Persist colors to colors.conf for future reloads
    cat <<EOF > "$COLORS_FILE"
\$active_border_color_1 = rgba(${color1}ee)
\$active_border_color_2 = rgba(${color2}ee)
\$inactive_border_color = rgba(${color1}33)
EOF

    # 4b. Persist colors as CSS variables for GTK/Waybar/Wofi
    cat <<EOF > "$HOME/.config/hypr/config/colors.css"
@define-color color1 #${color1};
@define-color color2 #${color2};
EOF

    # 4c. Persist colors for Kitty terminal
    # Function to brighten a color for maximum readability and contrast in terminal text
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

    local text_color1=$(brighten_color "$color1")
    local text_color2=$(brighten_color "$color2")

    local bg_r=$(( (16#${color1:0:2}) * 8 / 100 + 10 ))
    local bg_g=$(( (16#${color1:2:2}) * 8 / 100 + 8 ))
    local bg_b=$(( (16#${color1:4:2}) * 8 / 100 + 12 ))
    local dark_bg=$(printf "%02x%02x%02x" $bg_r $bg_g $bg_b)

    cat <<EOF > "$HOME/.config/kitty/colors-kitty.conf"
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

# Terminal accents (Blue/Light Blue, Magenta/Light Magenta, Cyan/Light Cyan)
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

    # 6. Update hyprlock.conf with matching background and border/text colors
    cat <<EOF > "$LOCK_FILE"
# Hyprland Lock Screen Configuration (hyprlock)
# Official Docs: https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/

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
        sed -i "s/^border-color=.*/border-color=#${color1}ee/" "$HOME/.config/mako/config"
        sed -i "s/^progress-color=.*/progress-color=over #${color2}ee/" "$HOME/.config/mako/config"
        makoctl reload >/dev/null 2>&1 || true
    fi

    # 8. Reload Waybar and Kitty config to apply dynamic theme instantly
    pkill -USR2 waybar >/dev/null 2>&1 || true
    pkill -USR1 kitty >/dev/null 2>&1 || true

    notify-send -h string:x-canonical-private-synchronous:wallpaper "Wallpaper System" "Applied $(basename "$wp_path")\nColor Scheme: #$color1 & #$color2"
}

# Function to select wallpaper via wofi
select_wallpaper() {
    local options=()
    for wp in "${WALLPAPERS[@]}"; do
        options+=("$(basename "$wp")")
    done
    
    # Show wofi menu
    local selected
    selected=$(printf "%s\n" "${options[@]}" | wofi --dmenu --prompt "Select Wallpaper" --width 400 --height 350)
    
    if [ -n "$selected" ]; then
        # Find the full path of the selected wallpaper
        for wp in "${WALLPAPERS[@]}"; do
            if [ "$(basename "$wp")" = "$selected" ]; then
                apply_wallpaper "$wp"
                break
            fi
        done
    fi
}

# Function to cycle to the next wallpaper
next_wallpaper() {
    local current_wp
    if [ -f "$CONFIG_FILE" ]; then
        current_wp=$(grep -E "^\s*path\s*=" "$CONFIG_FILE" | cut -d'=' -f2 | xargs)
    fi
    
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

# Function to start the slideshow daemon
start_daemon() {
    local interval="$1"
    if [ -z "$interval" ]; then
        interval=300 # Default to 5 minutes (300 seconds)
    fi
    
    # Kill any existing daemon
    stop_daemon quiet
    
    echo "Starting wallpaper slideshow daemon with ${interval}s interval..."
    (
        while true; do
            sleep "$interval"
            next_wallpaper
        done
    ) &
    
    echo $! > "$PID_FILE"
    notify-send "Wallpaper System" "Slideshow daemon started (Interval: ${interval}s)"
}

# Function to stop the slideshow daemon
stop_daemon() {
    local quiet="$1"
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            kill "$pid"
        fi
        rm -f "$PID_FILE"
        if [ "$quiet" != "quiet" ]; then
            notify-send "Wallpaper System" "Slideshow daemon stopped"
        fi
    else
        if [ "$quiet" != "quiet" ]; then
            notify-send "Wallpaper System" "No daemon currently running"
        fi
    fi
}

# Function to show status
status_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "Wallpaper daemon is running (PID: $pid)"
            notify-send "Wallpaper System" "Slideshow daemon is active (PID: $pid)"
            return 0
        fi
    fi
    echo "Wallpaper daemon is not running"
    notify-send "Wallpaper System" "Slideshow daemon is inactive"
    return 1
}

# Parse argument
case "$1" in
    --next)
        next_wallpaper
        ;;
    --daemon)
        start_daemon "$2"
        ;;
    --toggle-daemon)
        if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
            stop_daemon
        else
            start_daemon "$2"
        fi
        ;;
    --stop)
        stop_daemon
        ;;
    --status)
        status_daemon
        ;;
    *)
        select_wallpaper
        ;;
esac
