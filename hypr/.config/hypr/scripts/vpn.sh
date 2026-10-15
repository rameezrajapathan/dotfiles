#!/usr/bin/env bash
# Toggle a NetworkManager VPN connection. Usage: vpn.sh <connection name>
# For OpenVPN connections that store their password in NetworkManager
# (password-flags=0), asks for it the first time and saves it.
name=${1:?usage: vpn.sh <connection name>}

if nmcli -t -f NAME connection show --active | grep -qxF "$name"; then
    nmcli connection down "$name"
    exit
fi

stores_password() {
    nmcli -g vpn.data connection show "$name" | grep -q 'password-flags = 0'
}

if stores_password && ! nmcli -s -g vpn.secrets connection show "$name" | grep -q 'password = .'; then
    password=$(fuzzel --dmenu --password --lines 0 --prompt "$name password: ") || exit 0
    [[ -n $password ]] || exit 0
    nmcli connection modify "$name" vpn.secrets "password=$password"
    unset password
fi

if ! nmcli connection up "$name"; then
    if stores_password; then
        # Most likely a wrong or changed password: forget it so the next try asks again.
        nmcli connection modify "$name" vpn.secrets ""
        notify-send -u critical "VPN" "Couldn't connect to $name. The saved password was cleared; try again."
    else
        notify-send -u critical "VPN" "Couldn't connect to $name."
    fi
fi
