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

	-- Tray apps start once the bar's tray is up, so they hide to it instead of opening a window
	hl.exec_cmd("~/.config/hypr/scripts/tray-apps.sh")

	-- Mail and Chrome apps start hidden (background.lua); they show in the tray pill
	require("background").start({
		"thunderbird",
		"/opt/google/chrome/google-chrome --profile-directory=Default --app-id=ompifgpmddkgmclendfeacglnodjjndh", -- Teams
		"/opt/google/chrome/google-chrome '--profile-directory=Profile 1' --app-id=hnpfjngllnobngcgfapefoaidbinmjnm", -- WhatsApp
	})

	-- Apps added in the Settings app (Startup apps page; Quickshell writes this file)
	pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/autostart.lua")
end)
