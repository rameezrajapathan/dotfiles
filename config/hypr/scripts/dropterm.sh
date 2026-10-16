#!/usr/bin/env bash
running=$(hyprctl clients -j | jq 'any(.[]; .class == "dropterm")')
if [[ $running != true ]]; then
	"$(dirname "$0")/app.sh" terminal --app-id=dropterm &
	for _ in $(seq 20); do
		sleep 0.1
		[[ $(hyprctl clients -j | jq 'any(.[]; .class == "dropterm")') == true ]] && break
	done
	shown=$(hyprctl monitors -j | jq 'any(.[]; .specialWorkspace.name == "special:dropterm")')
	[[ $shown == true ]] && exit 0
fi
hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null
