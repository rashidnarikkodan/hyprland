-- Keyboard, pointer, and touchpad configuration
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

local scripts_dir = (os.getenv("HOME") or "") .. "/.config/hypr/scripts"

-- Workspace swipe
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- 3-finger swipe up: open workspaces overview immediately on gesture start
hl.gesture({
    fingers = 3,
    direction = "up",
    action = {
        start = function()
            hl.exec_cmd(scripts_dir .. "/hyprexpose.sh open")
        end,
    },
})

-- 3-finger swipe down: dismiss workspaces overview immediately on gesture start
hl.gesture({
    fingers = 3,
    direction = "down",
    action = {
        start = function()
            hl.exec_cmd(scripts_dir .. "/hyprexpose.sh close")
        end,
    },
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
