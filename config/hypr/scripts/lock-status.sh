#!/usr/bin/env bash
case $1 in
	battery)
		bat=/sys/class/power_supply/BAT0
		[[ -d $bat ]] || exit 0
		pct=$(<"$bat/capacity")
		if [[ $(<"$bat/status") == Charging ]]; then
			icon=󰂄
		else
			icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
			icon=${icons[pct >= 100 ? 9 : pct / 10]}
		fi
		echo "$icon  $pct%"
		;;
	music)
		[[ $(playerctl status 2>/dev/null) == Playing ]] || exit 0
		playerctl metadata --format '󰎆  {{ title }}  ·  {{ artist }}' 2>/dev/null
		;;
esac
