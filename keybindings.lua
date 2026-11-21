-- Keybindings and workspace navigation
local programs = require("programs")

-- ── Helpers ───────────────────────────────────────────────────
local function app(cmd, args)
    return hl.dsp.exec_cmd(args and (cmd .. " " .. args) or cmd)
end

local function webapp(url)
    return app(programs.browser, "--new-window --app='" .. url .. "'")
end

local function bind(combo, dispatcher, opts)
    hl.bind(programs.super .. " + " .. combo, dispatcher, opts)
end


-- ── Web Applications ──────────────────────────────────────────
local webapps = {
    ["E"]         = "https://mail.google.com",
    ["C"]         = "https://chatgpt.com",
    ["P"]         = "https://student.brototype.com",
    ["R"]         = "https://grok.com",
    ["D"]         = "https://chat.deepseek.com",
    ["Y"]         = "https://www.youtube.com/feed/subscriptions",
    ["W"]         = "https://web.whatsapp.com",
    ["T"]         = "https://web.telegram.org",
    ["K"]         = "https://claude.ai/",
    ["G"]         = "https://github.com/rashidnarikkodan?tab=repositories",
    ["SHIFT + G"] = "https://gemini.google.com/",
    ["SHIFT + C"] = "https://chatgpt.com/?temporary-chat=true",
    ["SHIFT + D"] = "https://discord.com/channels/@me",
    ["SHIFT + L"] = "https://linkedin.com/in/rashidnarikkodan",
}

for key, url in pairs(webapps) do
    bind(key, webapp(url))
end

-- ── Window Management ─────────────────────
bind("M",         app("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
bind("V",         hl.dsp.window.float({ action = "toggle" }))
bind("J",         hl.dsp.layout("togglesplit"))
bind("SHIFT + P", hl.dsp.window.pseudo())
bind("Q",         hl.dsp.window.close())

-- Core Applications 
bind("SPACE",         app("pkill -x " .. programs.menu .. " || " .. programs.menu))
bind("SHIFT + SPACE", app("pgrep -x waybar && pkill -USR1 waybar || waybar"))
bind("B",             app(programs.browser))
bind("RETURN",        app(programs.terminal))
bind("F",             app(programs.fileManager .. ' --new-window'))
bind("TAB",           app(os.getenv("HOME") .. "/.config/hypr/scripts/hyprexpose.sh toggle"))

-- ── Navigation & Workspaces ───────────────────────────────────
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    bind(dir, hl.dsp.focus({ direction = dir }))
end

local function get_target_workspace(num)
    local slot = (num == 0) and 10 or num
    local mon = hl.get_active_monitor()
    if mon and mon.name == "HDMI-A-2" then
        return 10 + slot
    end
    return slot
end

for i = 1, 10 do
    local key = i % 10
    bind(tostring(key), function()
        local target = get_target_workspace(key)
        hl.dispatch(hl.dsp.focus({ workspace = target }))
    end)
    bind("SHIFT + " .. key, function()
        local target = get_target_workspace(key)
        hl.dispatch(hl.dsp.window.move({ workspace = target }))
    end)
end

-- Special Workspaces & Scratchpads
bind("Grave",         hl.dsp.workspace.toggle_special("dev_scratch"))
bind("SHIFT + Grave", hl.dsp.window.move({ workspace = "special:dev_scratch" }))
bind("S",             hl.dsp.workspace.toggle_special("magic"))
bind("SHIFT + S",     hl.dsp.window.move({ workspace = "special:magic" }))

-- Workspace Cycling
bind("ALT + left",  hl.dsp.focus({ workspace = "r-1" }))  
bind("ALT + right", hl.dsp.focus({ workspace = "r+1" }))

-- ── Active Window Cycling (Current Monitor) ───────────────────
local function navigate_active_window(direction)
    local mon = hl.get_active_monitor()
    if not mon then return end

    local wins = hl.get_windows()
    local mon_wins = {}
    local special_ws = hl.get_active_special_workspace()

    for _, w in ipairs(wins) do
        local is_current_mon = (w.monitor and (w.monitor.id == mon.id or w.monitor.name == mon.name))
        local is_valid_ws = (w.workspace and w.workspace.id > 0)
            or (special_ws and w.workspace and w.workspace.id == special_ws.id)
        if is_current_mon and is_valid_ws then
            table.insert(mon_wins, w)
        end
    end

    if #mon_wins == 0 then return end

    table.sort(mon_wins, function(a, b)
        if a.workspace.id ~= b.workspace.id then
            return a.workspace.id < b.workspace.id
        end
        if a.at and b.at and a.at.x ~= b.at.x then
            return a.at.x < b.at.x
        end
        if a.at and b.at and a.at.y ~= b.at.y then
            return a.at.y < b.at.y
        end
        return tostring(a.address) < tostring(b.address)
    end)

    local active = hl.get_active_window()
    local cur_idx = nil
    if active then
        for i, w in ipairs(mon_wins) do
            if w.address == active.address then
                cur_idx = i
                break
            end
        end
    end

    local next_idx
    if not cur_idx then
        local cur_ws = hl.get_active_workspace()
        local cur_ws_id = cur_ws and cur_ws.id or 0
        if direction == "prev" then
            local target_idx = nil
            for i = #mon_wins, 1, -1 do
                if mon_wins[i].workspace.id < cur_ws_id then
                    target_idx = i
                    break
                end
            end
            next_idx = target_idx or #mon_wins
        else
            local target_idx = nil
            for i = 1, #mon_wins do
                if mon_wins[i].workspace.id > cur_ws_id then
                    target_idx = i
                    break
                end
            end
            next_idx = target_idx or 1
        end
    elseif direction == "prev" then
        next_idx = (cur_idx == 1) and #mon_wins or (cur_idx - 1)
    else
        next_idx = (cur_idx == #mon_wins) and 1 or (cur_idx + 1)
    end

    local target = mon_wins[next_idx]
    if target then
        hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
    end
end

bind("SHIFT + left",  function() navigate_active_window("prev") end)
bind("SHIFT + right", function() navigate_active_window("next") end)

-- ── Mouse Controls ────────────────────────────────────────────
bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
bind("mouse:272",  hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- ── Media & Hardware Controls ─────────────────────────────────
local function hw_bind(key, cmd, repeating)
    hl.bind(key, hl.dsp.exec_cmd(cmd), { locked = true, repeating = repeating or false })
end

hw_bind("XF86AudioRaiseVolume",  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", true)
hw_bind("XF86AudioLowerVolume",  "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      true)
hw_bind("XF86AudioMute",         "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     false)
hw_bind("XF86AudioMicMute",      "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   false)
hw_bind("XF86MonBrightnessUp",   "brightnessctl -e4 -n2 set 10%+",                  true)
hw_bind("XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 10%-",                  true)

for key, action in pairs({
    XF86AudioNext  = "next",
    XF86AudioPause = "play-pause",
    XF86AudioPlay  = "play-pause",
    XF86AudioPrev  = "previous",
}) do
    hw_bind(key, "playerctl " .. action)
end

-- Screen Shot Bindings
hw_bind("PRINT","hyprshot -m output -o ~/Pictures/Screenshots")
bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/Screenshots"))
bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures/Screenshots"))

-- Wallpaper Controller
bind("SHIFT + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/wallpaper-picker"))
bind("SHIFT + code:21", hl.dsp.exec_cmd('wallpapercli next'))
bind("SHIFT + MINUS", hl.dsp.exec_cmd('wallpapercli prev'))