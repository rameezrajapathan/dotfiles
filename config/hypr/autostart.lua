hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/scripts/shell.sh")
	hl.exec_cmd("if systemctl --user is-enabled -q pikadots-idle.service; then systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; systemctl --user start pikadots-idle.service; else ~/.config/hypr/scripts/idle.sh; fi")
	hl.exec_cmd("~/.config/hypr/scripts/clipboard.sh watch")
	hl.exec_cmd("python3 -I ~/.config/hypr/scripts/kde-theme.py")
	hl.exec_cmd("python3 -I ~/.config/hypr/scripts/vscode-theme.py sync")

	hl.exec_cmd("~/.config/hypr/scripts/startup-apps.sh")
end)
