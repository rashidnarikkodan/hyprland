# ⚡ Minimalist & Ultra-Lightweight Hyprland Setup (`lightweight` branch)

This branch contains a simplified, non-modular, ultra-lightweight **Hyprland** configuration tuned for maximum performance and minimum latency.

---

## 🚀 Features

- **No Animations**: `animations { enabled = false }` for instantaneous response and zero render lag.
- **Zero Heavy Eye-Candy**: Disabled window blur, disabled drop shadows, zero rounding (`rounding = 0`).
- **Single File Config**: All system settings, keybinds, window rules, monitor configs, and autostart commands consolidated into a single self-contained [hyprland.conf](file:///home/rashidnarikkodan/.config/hypr/hyprland.conf).
- **Clean Flat Directory**: No subdirectories (`binds/`, `config/`, `rules/`, `scripts/`, `startup/` deleted).

---

## 📁 Directory Structure

```text
~/.config/hypr
├── hyprland.conf                 # Consolidated lightweight Hyprland config
├── hyprpaper.conf                # Minimal wallpaper daemon config
├── hyprlock.conf                 # Screen lock configuration
├── hypridle.conf                 # Idle listener configuration
├── hyprsunset.conf               # Night temperature settings
├── xdg-desktop-portal-hyprland.conf # Desktop portal config
└── README.md                     # Setup documentation
```

---

## ⚡ Reloading Hyprland

Hyprland reloads automatically on save. To force a reload manually:
```bash
hyprctl reload
```
