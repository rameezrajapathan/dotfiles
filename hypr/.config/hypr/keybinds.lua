-- Keybindings

local mod = "SUPER"
local function script(cmd)
	return hl.dsp.exec_cmd("~/.config/hypr/scripts/" .. cmd)
end
local function shot(args)
	return script("screenshot.sh " .. args)
end

-- Application launchers
hl.bind(mod .. " + T", hl.dsp.exec_cmd("FASTFETCH=1 kitty"), { description = "Open terminal with fastfetch (Kitty)" })
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"), { description = "Open terminal (Kitty)" })
hl.bind(mod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"), { description = "Show notifications" })
hl.bind(mod .. " + C", hl.dsp.exec_cmd("code"), { description = "Open code editor (Visual Studio Code)" })
hl.bind(mod .. " + B", hl.dsp.exec_cmd("zen-browser"), { description = "Open web browser (Zen)" })
hl.bind(mod .. " + SHIFT + F", shot("region save"), { description = "Capture and save a region screenshot" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"), { description = "Open file manager (Thunar)" })
hl.bind(mod .. " + A", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "Open app launcher" })
hl.bind(mod .. " + V", script("clipboard.sh"), { description = "Open clipboard history" })
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("qs ipc call power toggle"), { description = "Open power menu" })
hl.bind(mod .. " + SHIFT + slash", hl.dsp.exec_cmd("qs ipc call cheatsheet toggle"), { description = "Show keybindings" })
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Pick wallpaper" })
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock session" })

-- Keyboard backlight
-- Uses the standard Linux keyboard-backlight LED device when available.
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl -d '*::kbd_backlight' set +1 && qs ipc call osd keyboard"), { repeating = true, description = "Raise keyboard brightness" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d '*::kbd_backlight' set 1- && qs ipc call osd keyboard"), { repeating = true, description = "Lower keyboard brightness" })

-- Display brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+ && qs ipc call osd brightness"), { locked = true, repeating = true, description = "Raise display brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%- && qs ipc call osd brightness"), { locked = true, repeating = true, description = "Lower display brightness" })

-- Window management
hl.bind(mod .. " + Q", require("background").hide_or_close, { description = "Close active window (background apps hide to the tray)" })
hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating window" })
hl.bind(mod .. " + SHIFT + M", hl.dsp.window.fullscreen({ mode = 1 }), { description = "Toggle maximized window" })
hl.bind(mod .. " + W", hl.dsp.group.toggle(), { description = "Toggle window group" })
hl.bind(mod .. " + M", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen window" })

-- Focus navigation
hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })

-- Window movement
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })

-- Monitor navigation
hl.bind(mod .. " + CTRL + left", hl.dsp.focus({ monitor = "left" }), { description = "Focus monitor left" })
hl.bind(mod .. " + CTRL + right", hl.dsp.focus({ monitor = "right" }), { description = "Focus monitor right" })
hl.bind(mod .. " + CTRL + H", hl.dsp.focus({ monitor = "left" }), { description = "Focus monitor left" })
hl.bind(mod .. " + CTRL + J", hl.dsp.focus({ monitor = "down" }), { description = "Focus monitor down" })
hl.bind(mod .. " + CTRL + K", hl.dsp.focus({ monitor = "up" }), { description = "Focus monitor up" })
hl.bind(mod .. " + CTRL + L", hl.dsp.focus({ monitor = "right" }), { description = "Focus monitor right" })

-- Move window to monitor
hl.bind(mod .. " + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "left" }), { description = "Move window to monitor left" })
hl.bind(mod .. " + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "down" }), { description = "Move window to monitor down" })
hl.bind(mod .. " + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "up" }), { description = "Move window to monitor up" })
hl.bind(mod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "right" }), { description = "Move window to monitor right" })
hl.bind(mod .. " + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "left" }), { description = "Move window to monitor left" })
hl.bind(mod .. " + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "down" }), { description = "Move window to monitor down" })
hl.bind(mod .. " + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "up" }), { description = "Move window to monitor up" })
hl.bind(mod .. " + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "right" }), { description = "Move window to monitor right" })

-- Workspace navigation
hl.bind(mod .. " + Page_Down", hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to next workspace" })
hl.bind(mod .. " + Page_Up", hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to previous workspace" })
hl.bind(mod .. " + U", hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to next workspace" })
hl.bind(mod .. " + I", hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to previous workspace" })
hl.bind(mod .. " + CTRL + down", hl.dsp.window.move({ workspace = "e+1" }), { description = "Move window to next workspace" })
hl.bind(mod .. " + CTRL + up", hl.dsp.window.move({ workspace = "e-1" }), { description = "Move window to previous workspace" })
hl.bind(mod .. " + CTRL + U", hl.dsp.window.move({ workspace = "e+1" }), { description = "Move window to next workspace" })
hl.bind(mod .. " + CTRL + I", hl.dsp.window.move({ workspace = "e-1" }), { description = "Move window to previous workspace" })

-- Move window to workspace
hl.bind(mod .. " + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "e+1" }), { description = "Move window to next workspace" })
hl.bind(mod .. " + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "e-1" }), { description = "Move window to previous workspace" })
hl.bind(mod .. " + SHIFT + U", hl.dsp.window.move({ workspace = "e+1" }), { description = "Move window to next workspace" })
hl.bind(mod .. " + SHIFT + I", hl.dsp.window.move({ workspace = "e-1" }), { description = "Move window to previous workspace" })

-- Mouse-wheel workspace navigation
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to next workspace" })
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to previous workspace" })
hl.bind(mod .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "e+1" }), { description = "Move window to next workspace" })
hl.bind(mod .. " + CTRL + mouse_up", hl.dsp.window.move({ workspace = "e-1" }), { description = "Move window to previous workspace" })

-- Numbered workspaces
for i = 1, 9 do
	hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
	hl.bind(mod .. " + ALT + " .. i, hl.dsp.window.move({ workspace = i, silent = true }), { description = "Move window silently to workspace " .. i })
end

-- Special workspaces
hl.bind(mod .. " + F1", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle special workspace magic" })
hl.bind(mod .. " + SHIFT + F1", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to special workspace magic" })
hl.bind(mod .. " + ALT + F1", hl.dsp.window.move({ workspace = "special:magic", silent = true }), { description = "Move window silently to special workspace magic" })
hl.bind(mod .. " + F2", hl.dsp.workspace.toggle_special("magic1"), { description = "Toggle special workspace magic1" })
hl.bind(mod .. " + SHIFT + F2", hl.dsp.window.move({ workspace = "special:magic1" }), { description = "Move window to special workspace magic1" })
hl.bind(mod .. " + ALT + F2", hl.dsp.window.move({ workspace = "special:magic1", silent = true }), { description = "Move window silently to special workspace magic1" })

-- Layout management
hl.bind(mod .. " + bracketleft", hl.dsp.layout("preselect l"), { description = "Preselect left split" })
hl.bind(mod .. " + bracketright", hl.dsp.layout("preselect r"), { description = "Preselect right split" })
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })
hl.bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen window" })

-- Mouse move / resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind(mod .. " + Z", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mod .. " + X", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

-- Resize by keycode
hl.bind(mod .. " + code:20", hl.dsp.window.resize({ x = -100, y = 0 }), { description = "Expand window left" })
hl.bind(mod .. " + code:21", hl.dsp.window.resize({ x = 100, y = 0 }), { description = "Shrink window left" })

-- Manual sizing
hl.bind(mod .. " + minus", hl.dsp.window.resize({ x = -50, y = 0 }), { repeating = true, description = "Shrink window width" })
hl.bind(mod .. " + equal", hl.dsp.window.resize({ x = 50, y = 0 }), { repeating = true, description = "Expand window width" })
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -50 }), { repeating = true, description = "Shrink window height" })
hl.bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 50 }), { repeating = true, description = "Expand window height" })

-- Screenshots
hl.bind("CTRL + XF86Launch1", shot("full"), { description = "Copy full-screen screenshot" })
hl.bind("ALT + XF86Launch1", shot("active"), { description = "Copy active-window screenshot" })
hl.bind("Print", shot("region"), { description = "Copy region screenshot" })
hl.bind("CTRL + Print", shot("full"), { description = "Copy full-screen screenshot" })
hl.bind("ALT + Print", shot("active"), { description = "Copy active-window screenshot" })

-- Screen recording (press again to stop)
hl.bind(mod .. " + SHIFT + R", script("record.sh region"), { description = "Record a region" })
hl.bind(mod .. " + ALT + R", script("record.sh full"), { description = "Record the full screen" })

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && qs ipc call osd volume"), { locked = true, repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && qs ipc call osd volume"), { locked = true, repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume"), { locked = true, description = "Toggle audio mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call osd mic"), { locked = true, description = "Toggle microphone mute" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs ipc call media playPause"), { locked = true, description = "Play / pause media" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call media playPause"), { locked = true, description = "Play / pause media" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs ipc call media next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs ipc call media previous"), { locked = true, description = "Previous track" })
