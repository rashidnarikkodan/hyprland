# 🧊 Hyprland Config

Minimal, modular Hyprland configuration split by purpose for easy maintenance.

---

## 📚 References (Official Docs)

* Hyprland Configuring Guide
  https://wiki.hypr.land/Configuring/

* Monitors
  https://wiki.hypr.land/Configuring/Monitors/

* Keywords / General Config
  https://wiki.hypr.land/Configuring/Keywords/

* Environment Variables
  https://wiki.hypr.land/Configuring/Environment-variables/

* Variables (UI / Look & Feel)
  https://wiki.hypr.land/Configuring/Variables/

* Animations
  https://wiki.hypr.land/Configuring/Animations/

* Dwindle Layout
  https://wiki.hypr.land/Configuring/Dwindle-Layout/

* Master Layout
  https://wiki.hypr.land/Configuring/Master-Layout/

* Gestures
  https://wiki.hypr.land/Configuring/Gestures

* Binds / Keybindings
  https://wiki.hypr.land/Configuring/Binds/

* Window Rules
  https://wiki.hypr.land/Configuring/Window-Rules/

* Workspace Rules
  https://wiki.hypr.land/Configuring/Workspace-Rules/

---

## 📁 Structure

```
~/.config/hypr/
├── hyprland.conf
├── monitors.conf
├── programs.conf
├── autostart.conf
├── env.conf
├── look.conf
├── input.conf
├── keybinds.conf
└── rules.conf
```

---

## 🚀 Usage

* Place files in `~/.config/hypr/`
* Ensure `hyprland.conf` sources all modules
* Reload:

  ```
  hyprctl reload
  ```

---

## ⚙️ What’s Included

* Dwindle tiling layout
* Basic animations + blur
* Waybar & Hyprpaper autostart
* Workspace/keybinding setup
* Window rules (XWayland fixes, etc.)

---

## ✏️ Customize

* Apps → `programs.conf`
* UI → `look.conf`
* Keybinds → `keybinds.conf`
* Startup → `autostart.conf`

---

## 🧠 Notes

* Fully modular via `source =`
* Original comments preserved
* Easy to extend (themes, multi-monitor, etc.)

---
