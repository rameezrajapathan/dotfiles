#!/usr/bin/env bash
# Start background apps that live in the bar's tray. Waits (up to 15s) for Quickshell's
# StatusNotifierWatcher; without it OneDriveGUI shows its window and closing quits it.

for _ in $(seq 30); do
	busctl --user status org.kde.StatusNotifierWatcher &>/dev/null && break
	sleep 0.5
done

pgrep -f /usr/bin/onedrivegui >/dev/null || onedrivegui &
pgrep -x remmina >/dev/null || remmina -i &
