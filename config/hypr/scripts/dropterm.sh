#!/usr/bin/env bash
address() { hyprctl clients -j | jq -r 'first(.[] | select(.class == "dropterm") | .address) // empty'; }
shown() { [[ $(hyprctl monitors -j | jq 'any(.[]; .specialWorkspace.name == "special:dropterm")') == true ]]; }

if [[ -z $(address) ]]; then
	"$(dirname "$0")/app.sh" terminal --app-id=dropterm &
	for _ in $(seq 20); do
		sleep 0.1
		[[ -n $(address) ]] && break
	done
	shown || hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null
else
	hyprctl dispatch 'hl.dsp.workspace.toggle_special("dropterm")' >/dev/null
fi
shown && hyprctl dispatch "hl.dsp.focus({ window = \"address:$(address)\" })" >/dev/null
