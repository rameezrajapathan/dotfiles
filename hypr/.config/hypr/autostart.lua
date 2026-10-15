hl.on("hyprland.start", function()
	hl.exec_cmd("QS_ICON_THEME=Papirus-Dark qs")
	hl.exec_cmd("~/.config/hypr/scripts/hyprpaper.sh")
	-- hypridle with the Settings app's timers (scripts/idle.sh; hypridle.conf has the defaults)
	hl.exec_cmd("~/.config/hypr/scripts/idle.sh")
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
	hl.exec_cmd("wl-paste --watch cliphist store")

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
