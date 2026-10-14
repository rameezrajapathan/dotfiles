-- Apps can't maximize themselves (kitty and Chrome ask to on open); Super + F still maximizes
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Zen
hl.window_rule({ match = { class = "^zen$" }, float = true, center = true, size = "1920 1080" })
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

-- Quickshell launcher, power menu, cheatsheet and notification popups blur what's behind them. ignore_alpha skips the faint
-- launcher backdrop, so only its card is blurred; the power menu's backdrop is opaque enough.
hl.layer_rule({ match = { namespace = "^quickshell-(launcher|power|cheatsheet|notifications)$" }, blur = true, ignore_alpha = 0.4, no_anim = true })
