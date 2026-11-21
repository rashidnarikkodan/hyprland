-- Monitor setup
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x768",
    scale    = "1",
    icc      = "/home/rashidnarikkodan/.local/share/icc/N140HCA-EAB.icm",
    sdrsaturation = 1.04,
})

hl.monitor({
    output   = "HDMI-A-2",
    mode     = "preferred",
    position = "0x0",
    scale    = "1",
})

-- Fallback for unspecified monitors
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})
