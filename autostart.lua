-- autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- hyprpaper")
    -- hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
    -- hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
    -- hl.exec_cmd("systemctl --user start elephant.service walker.service")
    -- hl.exec_cmd("~/bin/workspace.sh")
end)
