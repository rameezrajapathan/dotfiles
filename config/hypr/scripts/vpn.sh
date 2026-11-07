#!/usr/bin/env bash
name=${1:?usage: vpn.sh <connection name or uuid>}
out=$(python3 -I "$(dirname "$(readlink -f "$0")")/vpn.py" toggle "$name")
if [[ $(jq -r .ok <<<"$out") != true ]]; then
	if [[ $(jq -r '.needsPassword // false' <<<"$out") == true ]]; then
		qs ipc call vpn connect "$name" >/dev/null 2>&1 && exit 0
	fi
	notify-send -a VPN -u critical "Couldn't connect to $name" "$(jq -r '.error // "The connection failed."' <<<"$out")"
	exit 1
fi
