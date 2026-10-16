hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/shell.sh")
	hl.exec_cmd("~/.config/hypr/scripts/hyprpaper.sh")
	-- hypridle with the Settings app's timers (scripts/idle.sh; hypridle.conf has the defaults)
	hl.exec_cmd("~/.config/hypr/scripts/idle.sh")
	-- Password prompts come from the shell (quickshell/PolkitDialog.qml; hyprpolkitagent if it can't)
	-- Clipboard history (and wl-clip-persist) with Settings > Launcher's options
	hl.exec_cmd("~/.config/hypr/scripts/clipboard.sh watch")
	-- Wallpaper colors back into kdeglobals for Qt apps (a Plasma session puts its own back)
	hl.exec_cmd("python3 -I ~/.config/hypr/scripts/kde-theme.py")

	-- Startup apps: only the ones on the Settings app's Startup apps page, once the bar's tray is
	-- up (scripts/startup-apps.sh)
	hl.exec_cmd("~/.config/hypr/scripts/startup-apps.sh")
end)
