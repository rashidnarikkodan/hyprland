# 🧊 Production-Grade Modern Hyprland Architecture

This repository contains a clean, modular, high-performance **Hyprland** configuration built natively using official Hyprlang modules separated by concern and functionality.

---

## 📁 Directory Structure Overview

```text
~/.config/hypr
├── hyprland.conf                 # Main entrypoint sourcing all config modules below
├── hyprpaper.conf                # Wallpaper configuration
├── hyprlock.conf                 # Screen lock configuration
├── hypridle.conf                 # Idle listener configuration
├── hyprsunset.conf               # Blue light / night temperature settings
├── xdg-desktop-portal-hyprland.conf # Desktop portal configuration
│
├── config/                       # Core system settings
│   ├── env.conf                  # Environment variables (toolkit backends, cursors, etc.)
│   ├── monitors.conf             # Display and monitor layout options
│   ├── input.conf                # Keyboard layout, mouse, touchpad, and gesture settings
│   ├── appearance.conf           # Gaps (4/8), border size (2), border colors
│   ├── decorations.conf          # Glassmorphism blur (passes 3, size 6, vibrancy 0.2), shadows
│   ├── animations.conf           # Ultra-smooth springy Bezier animation curves (wind, winIn, winOut)
│   ├── layout.conf               # Layout options (dwindle/master selection and settings)
│   ├── misc.conf                 # Miscellaneous options (swallow, DPMS, VRR, direct scanout)
│   ├── colors.conf               # Active/inactive border color variables
│   └── colors.css                # GTK/Waybar CSS color definitions
│
├── binds/                        # Input shortcut bindings
│   ├── apps.conf                 # Core application launchers & utilities
│   ├── webapps.conf              # All 20+ web application hotkeys (Grok, ChatGPT, DeepSeek, YouTube, etc.)
│   ├── windows.conf              # Window controls (floating, focus, movement, grouping)
│   ├── workspaces.conf           # Workspace navigation 1-10 & special scratchpads (dev_scratch, magic)
│   ├── media.conf                # Media control keys (volume, mic, brightness, playerctl)
│   ├── resize.conf               # Window resizing shortcuts
│   └── screenshots.conf          # Screenshot actions mapped via hyprshot
│
├── rules/                        # Window/workspace rules and assignments
│   ├── windows.conf              # General window management, Picture-in-Picture, dialog rules
│   └── workspaces.conf           # Workspace properties, smart gaps, scratchpad behaviors
│
├── startup/                      # Autostart tasks
│   └── autostart.conf            # Background daemons (waybar, hyprpaper, cliphist)
│
└── scripts/                      # Custom helper shell scripts
    └── wallpaper.sh              # Dynamic wallpaper changer & palette extractor
```

---

## ✏️ Customization Guide

### 1. Keybindings
- Application launching shortcuts: `binds/apps.conf`
- Web apps hotkeys: `binds/webapps.conf`
- Window focus, movement, & controls: `binds/windows.conf`
- Workspaces: `binds/workspaces.conf`
- Media & hardware keys: `binds/media.conf`

### 2. Visual Style & Animations
- Glassmorphism & Opacity: `config/decorations.conf`
- Springy Animations: `config/animations.conf`
- Display layout: `config/monitors.conf`

---

## 🚀 Reloading Hyprland

Hyprland configuration reloads automatically on save. To manually force a reload:
```bash
hyprctl reload
```
