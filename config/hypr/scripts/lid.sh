#!/usr/bin/env bash
panel=$(hyprctl monitors all -j | jq -r '[.[] | select(.name | startswith("eDP"))][0].name')
[[ $panel == null ]] && exit 0

case $1 in
	close)
		external=$(hyprctl monitors all -j | jq --arg p "$panel" '[.[] | select(.name != $p and .disabled == false)] | length')
		((external > 0)) && hyprctl eval "hl.monitor({ output = \"$panel\", disabled = true })" >/dev/null
		;;
	open)
		hyprctl reload >/dev/null
		;;
esac
