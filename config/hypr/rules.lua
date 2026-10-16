hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({ match = { class = "zen", title = "Picture-in-Picture" }, float = true })
hl.window_rule({ match = { class = "zen", title = ".*Library.*" }, float = true })

hl.window_rule({
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

hl.window_rule({ match = { class = "thunar", title = "File Operation Progress" }, float = true, center = true })
hl.window_rule({ match = { class = "thunar", title = ".*Rename.*" }, float = true, center = true })
hl.window_rule({ match = { class = "xdg-desktop-portal-gtk", title = "^(Open|Save)" }, float = true })
hl.window_rule({ match = { class = "blueman-manager" }, float = true })
hl.window_rule({ match = { class = "steam" }, float = true })
hl.window_rule({ match = { class = "^org.quickshell$", title = "^Settings$" }, float = true, center = true, size = "1040 720" })

hl.layer_rule({ match = { namespace = "^quickshell.*$" }, blur = true, ignore_alpha = 0.4, no_anim = true })

hl.window_rule({
	match = { class = "^dropterm$" },
	float = true,
	size = "monitor_w*0.7 monitor_h*0.45",
	move = "monitor_w*0.15 50",
	workspace = "special:dropterm silent",
})

local ok, theme = pcall(dofile, os.getenv("HOME") .. "/.local/state/theme/hyprland.lua")
local special_border = ok and theme.special_border or "rgb(f5c2e7)"
hl.window_rule({ match = { workspace = "s[true]" }, border_color = special_border })

pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/window-rules.lua")
