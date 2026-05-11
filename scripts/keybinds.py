#!/usr/bin/env python3
import re
import gi
import os
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, Pango, GLib

class KeybindsWindow(Gtk.Window):
    def __init__(self):
        GLib.set_prgname("hyprland-keybinds")
        GLib.set_application_name("Hyprland Keybindings")
        super().__init__(title="Hyprland Keybindings")
        self.set_name("hyprland-keybinds")
        self.set_default_size(900, 700)
        self.set_position(Gtk.WindowPosition.CENTER)
        
        # Load CSS
        style_provider = Gtk.CssProvider()
        css = """
        window {
            background-color: rgba(24, 24, 37, 0.85);
            color: #cdd6f4;
            border-radius: 16px;
        }
        .main-container {
            padding: 20px;
        }
        .header {
            font-size: 32px;
            font-weight: 800;
            padding: 10px 0 30px 0;
            color: #89b4fa;
        }
        .section-header {
            font-size: 20px;
            font-weight: 700;
            padding: 25px 15px 10px 15px;
            color: #f5c2e7;
            border-bottom: 1px solid rgba(245, 194, 231, 0.2);
            margin-bottom: 10px;
        }
        .keybind-row {
            padding: 12px 15px;
            border-radius: 8px;
            transition: background 0.2s;
        }
        .keybind-row:hover {
            background-color: rgba(255, 255, 255, 0.05);
        }
        .key-combo {
            font-family: 'JetBrains Mono', 'Fira Code', monospace;
            font-weight: 600;
            color: #fab387;
            background-color: rgba(250, 179, 135, 0.15);
            padding: 4px 10px;
            border-radius: 6px;
            margin-right: 20px;
        }
        .action {
            color: #94e2d5;
            font-weight: 600;
            font-family: monospace;
        }
        .description {
            color: #a6adc8;
            font-size: 14px;
        }
        scrolledwindow {
            border: none;
        }
        scrollbar {
            background-color: transparent;
        }
        scrollbar slider {
            background-color: rgba(255, 255, 255, 0.2);
            border-radius: 20px;
            min-width: 6px;
        }
        """
        style_provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # UI Layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        main_box.get_style_context().add_class("main-container")
        self.add(main_box)

        header = Gtk.Label(label="Hyprland Shortcuts")
        header.get_style_context().add_class("header")
        header.set_halign(Gtk.Align.CENTER)
        main_box.pack_start(header, False, False, 0)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        main_box.pack_start(scrolled, True, True, 0)

        self.list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        scrolled.add(self.list_box)

        self.load_keybinds()

        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", Gtk.main_quit)
        self.show_all()

    def load_keybinds(self):
        config_path = os.path.expanduser("~/.config/hypr/keybinds.conf")
        if not os.path.exists(config_path):
            lbl = Gtk.Label(label="Config not found at ~/.config/hypr/keybinds.conf")
            self.list_box.pack_start(lbl, True, True, 0)
            return

        with open(config_path, "r") as f:
            lines = f.readlines()

        main_mod = "SUPER"
        
        # Regex to find $mainMod definition
        for line in lines:
            if "$mainMod =" in line:
                m = re.search(r"\$mainMod\s*=\s*(\w+)", line)
                if m:
                    main_mod = m.group(1)
                break

        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            if line.startswith("#"):
                # Section header
                section_title = line.lstrip("#").strip()
                if section_title:
                    lbl = Gtk.Label(label=section_title)
                    lbl.get_style_context().add_class("section-header")
                    lbl.set_halign(Gtk.Align.START)
                    self.list_box.pack_start(lbl, False, False, 0)
                continue

            # Handle bind, bindm, bindl, bindel, bindle, etc.
            if line.startswith("bind"):
                # Match bind[flags] = MODS, KEY, ACTION, ARGS
                # Using a more flexible split approach
                try:
                    parts = line.split("=", 1)
                    if len(parts) < 2: continue
                    
                    binding = parts[1].split(",", 3)
                    if len(binding) < 3: continue
                    
                    mods = binding[0].strip().replace("$mainMod", main_mod)
                    key = binding[1].strip()
                    action = binding[2].strip()
                    args = binding[3].strip() if len(binding) > 3 else ""

                    row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
                    row.get_style_context().add_class("keybind-row")
                    
                    key_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
                    key_box.set_size_request(250, -1)
                    
                    key_label = Gtk.Label()
                    key_label.set_markup(f"<span class='key-combo'>{mods} + {key}</span>")
                    key_label.set_halign(Gtk.Align.START)
                    key_box.pack_start(key_label, False, False, 0)
                    
                    content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
                    
                    action_label = Gtk.Label()
                    action_label.set_markup(f"<span class='action'>{action}</span>")
                    action_label.set_halign(Gtk.Align.START)
                    
                    desc_label = Gtk.Label(label=args)
                    desc_label.get_style_context().add_class("description")
                    desc_label.set_halign(Gtk.Align.START)
                    desc_label.set_line_wrap(True)
                    desc_label.set_max_width_chars(60)

                    content_box.pack_start(action_label, False, False, 0)
                    content_box.pack_start(desc_label, False, False, 0)

                    row.pack_start(key_box, False, False, 0)
                    row.pack_start(content_box, True, True, 0)
                    
                    self.list_box.pack_start(row, False, False, 0)
                except Exception as e:
                    print(f"Error parsing line: {line} - {e}")

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape or event.keyval == Gdk.KEY_q:
            Gtk.main_quit()

if __name__ == "__main__":
    # Set application ID for Wayland/Hyprland rules
    Gtk.Window.set_default_icon_name("help-browser")
    win = KeybindsWindow()
    Gtk.main()
