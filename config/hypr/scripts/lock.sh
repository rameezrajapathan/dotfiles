#!/usr/bin/env bash
[[ $(qs ipc call lock isLocked 2>/dev/null) == true ]] && exit 0
qs ipc call lock lock >/dev/null 2>&1
for _ in {1..10}; do
	[[ $(qs ipc call lock isLocked 2>/dev/null) == true ]] && exit 0
	sleep 0.1
done
pidof hyprlock >/dev/null || exec hyprlock
