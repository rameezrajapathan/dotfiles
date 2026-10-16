#!/usr/bin/env bash
set -uo pipefail

notify() { notify-send -a VPN "$@"; }
vpn_uuids() { nmcli -t -f UUID,TYPE connection show | awk -F: '$2 == "vpn" || $2 == "wireguard" { print $1 }' | sort; }

setup_openvpn() {
	local uuid=$1 name data user
	name=$(nmcli -g connection.id connection show "$uuid")
	data=$(nmcli -g vpn.data connection show "$uuid")
	[[ $(nmcli -g vpn.service-type connection show "$uuid") == *openvpn ]] || return 0
	[[ $data == *connection-type\ =\ password* ]] || return 0
	if [[ $data != *username\ =* ]]; then
		user=$(fuzzel --dmenu --lines 0 --prompt "$name username: ") && [[ -n $user ]] &&
			nmcli connection modify "$uuid" +vpn.data "username=$user"
	fi
	nmcli connection modify "$uuid" +vpn.data password-flags=0
}

case ${1:-} in
import)
	file=$(zenity --file-selection --title "Import a VPN" --filename "$HOME/Downloads/" \
		--file-filter "VPN files (.ovpn, .conf) | *.ovpn *.conf" --file-filter "All files | *") || exit 0
	[[ $file == *.conf ]] && type=wireguard || type=openvpn
	if ! out=$(nmcli connection import type "$type" file "$file" 2>&1); then
		notify -u critical VPN "Couldn't import ${file##*/}: ${out##*Error: }"
		exit 1
	fi
	uuid=$(grep -oE '[0-9a-f]{8}-[0-9a-f-]{27}' <<<"$out" | tail -1)
	[[ $type == openvpn ]] && setup_openvpn "$uuid"
	[[ $type == wireguard ]] && nmcli connection down "$uuid" >/dev/null 2>&1
	notify VPN "Added $(nmcli -g connection.id connection show "$uuid")"
	;;
new)
	before=$(vpn_uuids)
	nm-connection-editor --create --type vpn
	for uuid in $(comm -13 <(echo "$before") <(vpn_uuids)); do
		setup_openvpn "$uuid"
	done
	;;
*)
	echo "usage: ${0##*/} import|new" >&2
	exit 2
	;;
esac
