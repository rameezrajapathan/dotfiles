-- Keybindings

local mod = "SUPER"
local dispatch = require("dispatch")
local function script(cmd)
	return hl.dsp.exec_cmd("~/.config/hypr/scripts/" .. cmd)
end
-- Default apps (scripts/app.sh): whatever the system has set, never a named app
local function app(kind)
	return script("app.sh " .. kind)
end
local function shot(args)
	return script("screenshot.sh " .. args)
end

-- Application launchers
hl.bind(mod .. " + T", hl.dsp.exec_cmd("FASTFETCH=1 ~/.config/hypr/scripts/app.sh terminal"), { description = "Open terminal with fastfetch" })
hl.bind(mod .. " + grave", script("dropterm.sh"), { description = "Toggle drop-down terminal" })
hl.bind(mod .. " + Tab", hl.dsp.exec_cmd("qs ipc call overview next"), { description = "Switch workspaces (hold Super)" })
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call overview prev"), { description = "Switch workspaces backwards" })
-- Releasing Super switches to the workspace selected in the overview
hl.bind(mod .. " + Super_L", hl.dsp.exec_cmd("qs ipc call overview commit"), { release = true, transparent = true, non_consuming = true })
hl.bind("ALT + Tab", hl.dsp.exec_cmd("qs ipc call switcher next"), { description = "Switch windows (hold Alt)" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call switcher prev"), { description = "Switch windows backwards" })
-- Releasing Alt picks the selected window in the switcher
hl.bind("ALT + Alt_L", hl.dsp.exec_cmd("qs ipc call switcher commit"), { release = true, transparent = true, non_consuming = true })
hl.bind(mod .. " + Return", app("terminal"), { description = "Open terminal" })
hl.bind(mod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"), { description = "Show notifications" })
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("qs ipc call quicksettings dnd"), { description = "Toggle Do Not Disturb" })
hl.bind(mod .. " + S", hl.dsp.exec_cmd("qs ipc call controlcenter toggle ''"), { description = "Open settings (control center)" })
hl.bind(mod .. " + CTRL + W", hl.dsp.exec_cmd("qs ipc call weather toggle"), { description = "Show the weather" })
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("qs ipc call settings open ''"), { description = "Open the Settings app" })
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("qs ipc call quicksettings pickColor"), { description = "Pick a color from the screen (copies hex)" })
hl.bind(mod .. " + C", app("editor"), { description = "Open text editor" })
hl.bind(mod .. " + B", app("browser"), { description = "Open web browser" })
hl.bind(mod .. " + SHIFT + F", shot("region save"), { description = "Capture and save a region screenshot" })
hl.bind(mod .. " + SHIFT + T", shot("region text"), { description = "Copy the text in a region (OCR)" })

-- Screen zoom around the pointer (scripts/zoom.sh; Settings > Accessibility)
hl.bind(mod .. " + ALT + equal", script("zoom.sh in"), { repeating = true, description = "Zoom in" })
hl.bind(mod .. " + ALT + minus", script("zoom.sh out"), { repeating = true, description = "Zoom out" })
hl.bind(mod .. " + ALT + 0", script("zoom.sh reset"), { description = "Reset zoom" })
hl.bind(mod .. " + E", app("files"), { description = "Open file manager" })
hl.bind(mod .. " + A", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "Open app launcher" })
hl.bind(mod .. " + P", hl.dsp.exec_cmd("qs ipc call launcher open '~'"), { description = "Open a project (VS Code / Neovim)" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("qs ipc call launcher open +"), { description = "Open clipboard history" })
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("qs ipc call power toggle"), { description = "Open power menu" })
hl.bind(mod .. " + SHIFT + slash", hl.dsp.exec_cmd("qs ipc call cheatsheet toggle"), { description = "Show keybindings" })
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"), { description = "Pick wallpaper" })
hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock session" })

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
hl.bind(mod .. " + CTRL + M", hl.dsp.window.fullscreen({ mode = 1 }), { description = "Toggle maximized window" })
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
hl.bind(mod .. " + CTRL + left", dispatch.focus_monitor("left"), { description = "Focus monitor left" })
hl.bind(mod .. " + CTRL + right", dispatch.focus_monitor("right"), { description = "Focus monitor right" })
hl.bind(mod .. " + CTRL + H", dispatch.focus_monitor("left"), { description = "Focus monitor left" })
hl.bind(mod .. " + CTRL + J", dispatch.focus_monitor("down"), { description = "Focus monitor down" })
hl.bind(mod .. " + CTRL + K", dispatch.focus_monitor("up"), { description = "Focus monitor up" })
hl.bind(mod .. " + CTRL + L", dispatch.focus_monitor("right"), { description = "Focus monitor right" })

-- Move window to monitor
hl.bind(mod .. " + SHIFT + CTRL + left", dispatch.move_to_monitor("left"), { description = "Move window to monitor left" })
hl.bind(mod .. " + SHIFT + CTRL + down", dispatch.move_to_monitor("down"), { description = "Move window to monitor down" })
hl.bind(mod .. " + SHIFT + CTRL + up", dispatch.move_to_monitor("up"), { description = "Move window to monitor up" })
hl.bind(mod .. " + SHIFT + CTRL + right", dispatch.move_to_monitor("right"), { description = "Move window to monitor right" })
hl.bind(mod .. " + SHIFT + CTRL + H", dispatch.move_to_monitor("left"), { description = "Move window to monitor left" })
hl.bind(mod .. " + SHIFT + CTRL + J", dispatch.move_to_monitor("down"), { description = "Move window to monitor down" })
hl.bind(mod .. " + SHIFT + CTRL + K", dispatch.move_to_monitor("up"), { description = "Move window to monitor up" })
hl.bind(mod .. " + SHIFT + CTRL + L", dispatch.move_to_monitor("right"), { description = "Move window to monitor right" })

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
	hl.bind(mod .. " + ALT + " .. i, function() dispatch.move_silently(i) end, { description = "Move window silently to workspace " .. i })
end

-- Special workspaces
hl.bind(mod .. " + F1", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle special workspace magic" })
hl.bind(mod .. " + SHIFT + F1", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move window to special workspace magic" })
hl.bind(mod .. " + ALT + F1", function() dispatch.move_silently("special:magic") end, { description = "Move window silently to special workspace magic" })
hl.bind(mod .. " + F2", hl.dsp.workspace.toggle_special("magic1"), { description = "Toggle special workspace magic1" })
hl.bind(mod .. " + SHIFT + F2", hl.dsp.window.move({ workspace = "special:magic1" }), { description = "Move window to special workspace magic1" })
hl.bind(mod .. " + ALT + F2", function() dispatch.move_silently("special:magic1") end, { description = "Move window silently to special workspace magic1" })

-- Layout management
hl.bind(mod .. " + bracketleft", dispatch.try(hl.dsp.layout("preselect l")), { description = "Preselect left split" })
hl.bind(mod .. " + bracketright", dispatch.try(hl.dsp.layout("preselect r")), { description = "Preselect right split" })
hl.bind(mod .. " + J", dispatch.try(hl.dsp.layout("togglesplit")), { description = "Toggle split direction" })
hl.bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen window" })

-- Mouse move / resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind(mod .. " + Z", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind(mod .. " + X", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })


-- Manual sizing
hl.bind(mod .. " + minus", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true, description = "Shrink window width" })
hl.bind(mod .. " + equal", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true, description = "Expand window width" })
hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true, description = "Shrink window height" })
hl.bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true, description = "Expand window height" })

-- Screenshots
hl.bind("CTRL + XF86Launch1", shot("full"), { description = "Copy full-screen screenshot" })
hl.bind("ALT + XF86Launch1", shot("active"), { description = "Copy active-window screenshot" })
hl.bind("Print", shot("region"), { description = "Copy region screenshot" })
hl.bind("CTRL + Print", shot("full"), { description = "Copy full-screen screenshot" })
hl.bind("ALT + Print", shot("active"), { description = "Copy active-window screenshot" })
hl.bind("SHIFT + Print", shot("region edit"), { description = "Annotate a region screenshot" })

-- Screen recording (press again to stop)
hl.bind(mod .. " + SHIFT + R", script("record.sh region"), { description = "Record a region" })
hl.bind(mod .. " + ALT + R", script("record.sh full"), { description = "Record the full screen" })

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+ && qs ipc call osd volume"), { locked = true, repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%- && qs ipc call osd volume"), { locked = true, repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call osd volume"), { locked = true, description = "Toggle audio mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call osd mic"), { locked = true, description = "Toggle microphone mute" })
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("qs ipc call media toggle"), { description = "Open music player" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("qs ipc call media playPause"), { locked = true, description = "Play / pause media" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("qs ipc call media playPause"), { locked = true, description = "Play / pause media" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("qs ipc call media next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("qs ipc call media previous"), { locked = true, description = "Previous track" })

-- Lid: closing it while docked turns the laptop panel off; opening turns it back on
hl.bind("switch:on:Lid Switch", script("lid.sh close"), { locked = true, description = "Laptop lid closed" })
hl.bind("switch:off:Lid Switch", script("lid.sh open"), { locked = true, description = "Laptop lid opened" })
