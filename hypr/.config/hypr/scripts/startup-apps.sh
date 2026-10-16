#!/usr/bin/env bash
# Starts the Settings app's Startup apps (~/.local/state/pikadots/autostart.lua, written by
# SettingsStartupPage.qml) once the bar's tray is up (up to 15 s): tray apps like OneDriveGUI
# started before Quickshell's StatusNotifierWatcher exists show their window and quit on close.
# Chrome apps and mail among them start hidden (background.lua's 30 s rule).

for _ in $(seq 30); do
	busctl --user status org.kde.StatusNotifierWatcher &>/dev/null && break
	sleep 0.5
done

hyprctl eval 'require("background").start({}); pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/autostart.lua")' >/dev/null
