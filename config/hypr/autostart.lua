hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/shell.sh")
	hl.exec_cmd("~/.config/hypr/scripts/hyprpaper.sh")
	hl.exec_cmd("~/.config/hypr/scripts/idle.sh")
	hl.exec_cmd("~/.config/hypr/scripts/clipboard.sh watch")
	hl.exec_cmd("python3 -I ~/.config/hypr/scripts/kde-theme.py")

	hl.exec_cmd("~/.config/hypr/scripts/startup-apps.sh")
end)
