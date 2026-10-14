#!/usr/bin/env bash
# Toggle the NetworkManager VPN connection.
# Asks for the password the first time and saves it in NetworkManager
# (root-only file in /etc/NetworkManager/system-connections).
name="Office VPN"

if nmcli -t -f NAME connection show --active | grep -qx "$name"; then
    nmcli connection down "$name"
    exit
fi

if ! nmcli -s -g vpn.secrets connection show "$name" | grep -q 'password = .'; then
    password=$(fuzzel --dmenu --password --lines 0 --prompt "$name password: ") || exit 0
    [[ -n $password ]] || exit 0
    nmcli connection modify "$name" vpn.secrets "password=$password"
    unset password
fi

if ! nmcli connection up "$name"; then
    # Most likely a wrong or changed password: forget it so the next try asks again.
    nmcli connection modify "$name" vpn.secrets ""
    notify-send -u critical "VPN" "Couldn't connect to $name. The saved password was cleared; try again."
fi
