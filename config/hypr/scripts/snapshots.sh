#!/usr/bin/env bash
command -v snapper >/dev/null || exit 1
config=${1:-root}
[[ -f /etc/snapper/configs/$config ]] || { echo '{"config":false,"count":null,"latest":null,"source":""}'; exit 0; }

dates=
source=
if json=$(snapper --jsonout -c "$config" list --disable-used-space 2>/dev/null); then
	dates=$(jq -r --arg c "$config" '.[$c][] | select(.number != 0) | .date' <<<"$json" 2>/dev/null) && source=snapper
fi
if [[ -z $source && $config == root && -r /boot/grub/grub-btrfs.cfg ]]; then
	dates=$(grep -oP "^submenu '\| \K[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:]{8}" /boot/grub/grub-btrfs.cfg)
	source=grub-btrfs
fi
if [[ -z $source ]]; then
	echo '{"config":true,"count":null,"latest":null,"source":""}'
	exit 0
fi
latest=$(sort <<<"$dates" | tail -1)
[[ -n $latest ]] && latest=$(date -d "$latest" +%s 2>/dev/null)
jq -nc --arg source "$source" --argjson count "$(grep -c . <<<"$dates")" --arg latest "$latest" \
	'{config: true, count: $count, latest: ($latest | tonumber? // null), source: $source}'
