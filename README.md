# 🧊 Production-Grade Modular Hyprland Config

This repository contains a modular, maintainable, and clean Hyprland configuration structure, separated cleanly by concern and functionality.

---

## 📁 Directory Structure Overview

```text
~/.config/hypr
├── hyprland.conf          # Main entrypoint sourcing all configs below
├── hyprpaper.conf         # Wallpaper configuration
├── hyprshot.conf          # Screenshot tool wrapper config
├── hyprlock.conf          # Screen lock configuration
├── hypridle.conf          # Idle listener configuration
├── hyprsunset.conf        # Blue light / night temperature settings
│
├── config/                # Core system settings
│   ├── env.conf           # Environment variables (toolkit backends, cursors, etc.)
│   ├── monitors.conf      # Display and monitor layout options
│   ├── input.conf         # Keyboard layout, mouse, and touchpad settings
│   ├── variables.conf     # Reusable variables (terminal, browser, launcher, etc.)
│   ├── appearance.conf    # Gaps, border sizing, and border colors
│   ├── decorations.conf   # Rounding, active/inactive opacity, shadows, and blur
│   ├── animations.conf    # Animation parameters and toggle
│   ├── layout.conf        # Layout options (dwindle/master selection and settings)
│   ├── misc.conf          # Miscellaneous options (swallow, DPMS, VRR, etc.)
│   └── debug.conf         # Performance and rendering options (direct scanout)
│
├── binds/                 # Input shortcut bindings
│   ├── apps.conf          # Application launching shortcuts and webapps
│   ├── windows.conf       # Window controls (floating, focus, movement, grouping)
│   ├── workspaces.conf    # Workspace navigation and dropdown scratchpad binds
│   ├── media.conf         # Media control keys (volume, mic, brightness, playerctl)
│   ├── mouse.conf         # Mouse click/drag window actions and workspace scrolling
│   ├── resize.conf        # Windows resizing shortcuts
│   └── screenshots.conf   # Screenshot actions mapped via hyprshot
│
├── rules/                 # Window/workspace rules and assignments
│   ├── windows.conf       # General window management and class routing
│   ├── floating.conf      # Window float overrides, helper rules, XWayland drag fixes
│   ├── workspaces.conf    # Workspace properties and smart gaps behavior
│   └── layers.conf        # Desktop widget, panel, and waybar rules
│
├── startup/               # Autostart tasks
│   ├── services.conf      # Background daemons (waybar, hyprpaper, etc.)
│   └── applications.conf  # Foreground applications launched on startup
│
├── scripts/               # Custom helper shell scripts
│
└── README.md              # Documentation
```

---

## ✏️ Customization Guide

### 1. How to Add New Keybindings
Depending on the type of keybinding you want to define, open the relevant file in the `binds/` directory:
- To add a new keyboard shortcut for a program, edit `binds/apps.conf`.
- To add focus or control binds, edit `binds/windows.conf`.
- To add media/hardware keys, edit `binds/media.conf`.

**Syntax:**
```ini
bind = MOD, KEY, exec, COMMAND
```
*Example (launching VS Code with SUPER + C):*
```ini
bind = $mainMod, C, exec, code
```

### 2. How to Add Startup Applications
To launch applications or startup processes automatically when Hyprland starts:
- Services/daemons (like waybar, polkit agents, notifications): Add to `startup/services.conf`.
- Standard user applications (browsers, chat clients): Add to `startup/applications.conf`.

**Syntax:**
```ini
exec-once = COMMAND
```
*Example (launching Discord on startup):*
```ini
exec-once = discord --minimized
```

### 3. How to Add Window Rules
To control window sizing, floating behavior, or assign workspaces:
- Regular window behavior: Add to `rules/windows.conf`.
- Sizing/floating rules: Add to `rules/floating.conf`.

**Syntax:**
```ini
windowrule = RULE, match_regex
# Or modern format:
windowrulev2 = RULE, class:^(regex)$, title:^(regex)$
```
*Example (forcing Chromium to open in floating mode):*
```ini
windowrulev2 = float, class:^(Chromium)$
```

### 4. How to Add Monitor Profiles
Display and layout properties can be customized in `config/monitors.conf`.

**Syntax:**
```ini
monitor = NAME, RESOLUTION@REFRESH, POSITION, SCALE
```
*Example (setting primary screen and secondary monitor on top):*
```ini
monitor = eDP-1, 1920x1080@144, 0x0, 1
monitor = HDMI-A-2, preferred, 0x-1080, 1
```

---

## 🚀 Operations

### How to Reload Hyprland
Hyprland configuration reloads automatically on save. If you need to force a manual reload of the configuration, run:
```bash
hyprctl reload
```

---

## 🛠️ Troubleshooting

- **Check Config Syntax for Errors:**
  Run the Hyprland configuration check utility to scan your configs for syntax errors:
  ```bash
  hyprctl configtest
  ```
- **Review System Logs:**
  If Hyprland fails to start or crashes, consult the journal logs:
  ```bash
  journalctl --user -u hyprland
  ```
- **Confirm Sourced Modules:**
  If a keybinding or styling parameter does not apply, ensure it is sourced within `hyprland.conf` and that there are no overlapping/conflicting directives.
