local colors = { active_border = "rgb(89b4fa)", inactive_border = "rgb(313244)" }
local ok, generated = pcall(dofile, os.getenv("HOME") .. "/.local/state/theme/hyprland.lua")
if ok then
	colors = generated
end
local settings_json = ""
do
	local f = io.open(os.getenv("HOME") .. "/.config/pikadots/settings.json")
	settings_json = f and f:read("a") or ""
	if f then
		f:close()
	end
	if colors.accent_end and colors.accent_end ~= "rgb()" and settings_json:match('"gradient"%s*:%s*true') then
		colors.active_border = { colors = { colors.active_border, colors.accent_end }, angle = 45 }
	end
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
		background_color = "rgb(000000)",
		vrr = 1,
		key_press_enables_dpms = false,
		mouse_move_enables_dpms = false,
		allow_session_lock_restore = true,
	},

	cursor = {
		no_warps = true,
	},
})

if not settings_json:match('"pikadots%.gestures"%s*:%s*false') then
	hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
	hl.gesture({ fingers = 3, direction = "up", action = function() hl.exec_cmd("qs ipc call overview toggle") end })
	hl.gesture({ fingers = 3, direction = "down", action = "special", workspace_name = "magic" })
	hl.gesture({ fingers = 4, direction = "pinch", action = "cursor_zoom", zoom_level = 1, mode = "live" })
	hl.gesture({ fingers = 3, direction = "swipe", mods = "SUPER", action = "move" })
	hl.gesture({ fingers = 4, direction = "swipe", mods = "SUPER", action = "resize" })
	hl.gesture({ fingers = 4, direction = "horizontal", action = "scroll_move" })
	hl.gesture({ fingers = 4, direction = "down", action = function() hl.exec_cmd("qs ipc call desktop toggle") end })
end

hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("smooth", { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })
hl.curve("springy", { type = "spring", mass = 1, stiffness = 260, damping = 22 })
hl.curve("bouncy", { type = "spring", mass = 1, stiffness = 200, damping = 15 })

hl.animation({ leaf = "windows", enabled = true, speed = 3, spring = "smooth" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, spring = "smooth", style = "popin 87%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, spring = "smooth" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = false })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, spring = "smooth", style = "slidefadevert" })

local borders = { active = colors.active_border, inactive = colors.inactive_border }
local glass_ok, glass = pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/glass.lua")
local glassy = glass_ok and type(glass) == "table" and glass.enabled
if glassy then
	local active = glass.active_border
	if not glass.neutral then
		local accent = colors.active_border
		local list = type(accent) == "table" and accent.colors or { accent }
		active = { colors = { glass.rim, list[1], list[2] or glass.active_border.colors[3] }, angle = glass.angle }
	end
	borders = { active = active, inactive = glass.inactive_border }
	glass.config.general = { col = { active_border = active, inactive_border = glass.inactive_border } }
	hl.config(glass.config)
end

do
	local g = colors.group or {
		active = "89b4fa", active_text = "11111b", inactive = "313244", inactive_text = "bac2de",
		text = "cdd6f4", locked = "f5c2e7", locked_text = "11111b",
	}
	local size = math.max(10, (tonumber(settings_json:match('"fontSize"%s*:%s*(%d+)')) or 15) - 3)
	local active, active_text = "rgba(" .. g.active .. "eb)", "rgb(" .. g.active_text .. ")"
	if glassy and glass.neutral then
		active, active_text = "rgba(ffffff38)", "rgb(" .. g.text .. ")"
	end
	local fill = glassy and "c2" or "eb"
	hl.config({
		group = {
			col = {
				border_active = borders.active,
				border_inactive = borders.inactive,
				border_locked_active = "rgb(" .. g.locked .. ")",
				border_locked_inactive = "rgba(" .. g.locked .. "66)",
			},
			groupbar = {
				enabled = true,
				font_family = settings_json:match('"font"%s*:%s*"([^"]+)"') or "sans-serif",
				font_size = size,
				font_weight_active = "semibold",
				font_weight_inactive = "medium",
				height = size + 14,
				render_titles = true,
				text_padding = 10,
				gradients = true,
				gradient_rounding = 10,
				gradient_round_only_edges = false,
				indicator_height = 0,
				gaps_in = 4,
				gaps_out = 4,
				keep_upper_gap = true,
				blur = glassy and true or false,
				middle_click_close = true,
				disable_when_only = true,
				col = {
					active = active,
					inactive = "rgba(" .. g.inactive .. fill .. ")",
					locked_active = "rgba(" .. g.locked .. "eb)",
					locked_inactive = "rgba(" .. g.inactive .. fill .. ")",
				},
				text_color = active_text,
				text_color_inactive = "rgb(" .. g.inactive_text .. ")",
				text_color_locked_active = "rgb(" .. g.locked_text .. ")",
				text_color_locked_inactive = "rgb(" .. g.inactive_text .. ")",
			},
		},
	})
end

if colors.backdrop and not settings_json:match('"pikadots%.backdropColors"%s*:%s*false') then
	hl.config({
		decoration = {
			blur = {
				aurora = { color1 = colors.backdrop.aurora1, color2 = colors.backdrop.aurora2 },
				fluid_jar = { color = colors.backdrop.fluid },
			},
		},
	})
end

pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/hypr-settings.lua")

if settings_json:match('"reduceMotion"%s*:%s*true') then
	hl.config({ decoration = { wobble = { enabled = false }, motion_blur = { enabled = false } } })
end

local gamemode = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/pikadots-gamemode")
if gamemode then
	gamemode:close()
	hl.config({
		animations = { enabled = false },
		decoration = {
			rounding = 0,
			blur = { enabled = false },
			shadow = { enabled = false },
			glow = { enabled = false },
			wobble = { enabled = false },
			motion_blur = { enabled = false },
		},
		general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
	})
end
