-- autostart.lua
hl.on("hyprland.start", function ()
    hl.exec_cmd("waybar & mako")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hyprexpose --allow-mouse")
end)
