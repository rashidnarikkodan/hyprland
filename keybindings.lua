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
    ["Y"]         = "https://www.youtube.com/",
    ["W"]         = "https://web.whatsapp.com",
    ["K"]         = "https://claude.ai/",
    ["G"]         = "https://gemini.google.com/",
    ["U"]         = "https://www.perplexity.ai/",
    ["SHIFT + G"] = "https://github.com/rashidnarikkodan",
    ["SHIFT + H"] = "https://hoppscotch.io",
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
bind("SPACE",         app(programs.menu))
bind("SHIFT + SPACE", app("pgrep -x waybar && pkill -USR1 waybar || waybar"))
bind("B",             app(programs.browser))
bind("RETURN",        app(programs.terminal))
bind("F",             app(programs.fileManager))

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
bind("Tab",           hl.dsp.focus({ workspace = "e+1" }))
bind("SHIFT + Tab",   hl.dsp.focus({ workspace = "e-1" }))

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
hw_bind("XF86AudioMute",         "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     true)
hw_bind("XF86AudioMicMute",      "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   true)
hw_bind("XF86MonBrightnessUp",   "brightnessctl -e4 -n2 set 5%+",                  true)
hw_bind("XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-",                  true)

for key, action in pairs({
    XF86AudioNext  = "next",
    XF86AudioPause = "play-pause",
    XF86AudioPlay  = "play-pause",
    XF86AudioPrev  = "previous",
}) do
    hw_bind(key, "playerctl " .. action)
end

-- Screen Shot Bindings
hw_bind("PRINT","hyprshot -m output")
bind("PRINT", hl.dsp.exec_cmd("hyprshot -m region"))
bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))