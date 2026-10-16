#!/usr/bin/env bash

for _ in $(seq 30); do
	busctl --user status org.kde.StatusNotifierWatcher &>/dev/null && break
	sleep 0.5
done

hyprctl eval 'require("background").start({}); pcall(dofile, os.getenv("HOME") .. "/.local/state/pikadots/autostart.lua")' >/dev/null
