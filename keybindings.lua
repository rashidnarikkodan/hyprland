-- Keybindings and workspace navigation
local programs = require("programs")

local terminal = programs.terminal
local fileManager = programs.fileManager
local menu = programs.menu
local browser = programs.browser
local super = programs.super
local function webapp(url)
    return hl.dsp.exec_cmd(browser .. " --new-window --app='" .. url .. "'")
end


hl.bind(super .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(super .. " + Q", hl.dsp.window.close())
hl.bind(super .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(super .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(super .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(super .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(super .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(super .. " + SHIFT + P", hl.dsp.window.pseudo())
hl.bind(super .. " + J", hl.dsp.layout("togglesplit"))

-- Web Apps

hl.bind(super .. " + E",         webapp("https://mail.google.com"))
hl.bind(super .. " + C",         webapp("https://chatgpt.com"))
hl.bind(super .. " + P",         webapp("https://student.brototype.com"))
hl.bind(super .. " + R",         webapp("https://grok.com"))
hl.bind(super .. " + D",         webapp("https://chat.deepseek.com"))
hl.bind(super .. " + Y",         webapp("https://www.youtube.com/"))
hl.bind(super .. " + W",         webapp("https://web.whatsapp.com"))
hl.bind(super .. " + K",         webapp("https://claude.ai/"))
hl.bind(super .. " + G",         webapp("https://gemini.google.com/"))
hl.bind(super .. " + U",         webapp("https://www.perplexity.ai/"))
hl.bind(super .. " + SHIFT + G", webapp("https://github.com/rashidnarikkodan"))
hl.bind(super .. " + SHIFT + H", webapp("https://hoppscotch.io"))
hl.bind(super .. " + SHIFT + D", webapp("https://discord.com/channels/@me"))
hl.bind(super .. " + SHIFT + L", webapp("https://linkedin.com/in/rashidnarikkodan"))


-- Navigation
hl.bind(super .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(super .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(super .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(super .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(super .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(super .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

hl.bind(super .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(super .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(super .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(super .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(super .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(super .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
