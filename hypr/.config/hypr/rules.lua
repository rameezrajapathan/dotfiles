-- Apps can't maximize themselves (kitty and Chrome ask to on open); Super + F still maximizes
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Zen: tiled like other apps; only Picture-in-Picture and the Library window float
hl.window_rule({ match = { class = "zen", title = "Picture-in-Picture" }, float = true })
hl.window_rule({ match = { class = "zen", title = ".*Library.*" }, float = true })

-- Unnamed XWayland helper windows shouldn't steal focus
hl.window_rule({
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- Dialogs
hl.window_rule({ match = { class = "thunar", title = "File Operation Progress" }, float = true, center = true })
hl.window_rule({ match = { class = "thunar", title = ".*Rename.*" }, float = true, center = true })
hl.window_rule({ match = { class = "xdg-desktop-portal-gtk", title = "^(Open|Save)" }, float = true })
hl.window_rule({ match = { class = "blueman-manager" }, float = true })
hl.window_rule({ match = { class = "steam" }, float = true })

-- Blur behind every Quickshell surface (bar pills, panels, launcher, menus, popups, OSD).
-- ignore_alpha skips nearly transparent pixels, so full-screen overlays only blur under their content.
hl.layer_rule({ match = { namespace = "^quickshell.*$" }, blur = true, ignore_alpha = 0.4, no_anim = true })

-- Drop-down terminal (scripts/dropterm.sh, Super + `): floats across the top on its own special workspace
hl.window_rule({
	match = { class = "^dropterm$" },
	float = true,
	size = "monitor_w*0.7 monitor_h*0.45",
	move = "monitor_w*0.15 50",
	workspace = "special:dropterm silent",
})
