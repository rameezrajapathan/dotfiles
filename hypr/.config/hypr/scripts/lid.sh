#!/usr/bin/env bash
# Lid switch (keybinds.lua). Usage: lid.sh close|open
# Closing with an external monitor attached turns the laptop panel off (logind ignores the lid
# while docked); without one, logind suspends as usual. Opening turns the panel back on.
panel=$(hyprctl monitors all -j | jq -r '[.[] | select(.name | startswith("eDP"))][0].name')
[[ $panel == null ]] && exit 0

case $1 in
	close)
		external=$(hyprctl monitors all -j | jq --arg p "$panel" '[.[] | select(.name != $p and .disabled == false)] | length')
		((external > 0)) && hyprctl eval "hl.monitor({ output = \"$panel\", disabled = true })" >/dev/null
		;;
	open)
		# Re-applies monitors.lua, which turns the panel back on
		hyprctl reload >/dev/null
		;;
esac
