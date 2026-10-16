local colors = { active_border = "rgb(89b4fa)", inactive_border = "rgb(313244)" }
local ok, generated = pcall(dofile, os.getenv("HOME") .. "/.local/state/theme/hyprland.lua")
if ok then
	colors = generated
end

hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("TERMINAL", "kitty")
do
	local bin, path = os.getenv("HOME") .. "/.local/bin", os.getenv("PATH") or "/usr/local/bin:/usr/bin"
	if not (":" .. path .. ":"):find(":" .. bin .. ":", 1, true) then
		hl.env("PATH", bin .. ":" .. path)
	end
end
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/gcr/ssh")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "28")

hl.config({
	input = {
		kb_layout = "us",
		numlock_by_default = true,
		touchpad = { natural_scroll = true },
	},

	general = {
		gaps_in = 3,
		gaps_out = 6,
		border_size = 2,
		resize_on_border = true,
		col = {
			active_border = colors.active_border,
			inactive_border = colors.inactive_border,
		},
		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		inactive_opacity = 0.9,
		blur = { size = 6 },
		shadow = { enabled = false },
	},

	dwindle = {
		preserve_split = true,
		force_split = 2,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 1,
		key_press_enables_dpms = false,
		mouse_move_enables_dpms = false,
		allow_session_lock_restore = true,
	},

	cursor = {
		no_warps = true,
	},
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "default", style = "slidefadevert" })

pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/hypr-settings.lua")

local gamemode = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/pikadots-gamemode")
if gamemode then
	gamemode:close()
	hl.config({
		animations = { enabled = false },
		decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } },
		general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
	})
end
