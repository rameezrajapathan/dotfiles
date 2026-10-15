#!/usr/bin/env bash
# Locks the session: the Quickshell lock screen (quickshell/Lock.qml), or hyprlock when that didn't
# take within a second (shell not running, or Lock failed to load). hypridle's lock_cmd.
[[ $(qs ipc call lock isLocked 2>/dev/null) == true ]] && exit 0
qs ipc call lock lock >/dev/null 2>&1
for _ in {1..10}; do
	[[ $(qs ipc call lock isLocked 2>/dev/null) == true ]] && exit 0
	sleep 0.1
done
pidof hyprlock >/dev/null || exec hyprlock
