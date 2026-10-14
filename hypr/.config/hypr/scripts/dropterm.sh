#!/usr/bin/env bash
# Drop-down terminal: a kitty (class "dropterm") living on special:dropterm, shown and hidden
# with Super + `. Started on first use; rules.lua makes it float at the top of the screen.
running=$(hyprctl clients -j | jq 'any(.[]; .class == "dropterm")')
if [[ $running != true ]]; then
	kitty --class dropterm &
	# Wait for the window so the toggle below shows it
	for _ in $(seq 20); do
		sleep 0.1
		[[ $(hyprctl clients -j | jq 'any(.[]; .class == "dropterm")') == true ]] && break
	done
	shown=$(hyprctl monitors -j | jq 'any(.[]; .specialWorkspace.name == "special:dropterm")')
	[[ $shown == true ]] && exit 0
fi
hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null
