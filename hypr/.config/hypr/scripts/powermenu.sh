#!/usr/bin/env bash
choice=$(printf '%s\n' lock logout suspend reboot shutdown | fuzzel --dmenu --prompt "power " --lines 5) || exit 0

case $choice in
    lock)     loginctl lock-session ;;
    logout)   hyprctl dispatch 'hl.dsp.exit()' ;;
    suspend)  systemctl suspend ;;
    reboot)   systemctl reboot ;;
    shutdown) systemctl poweroff ;;
esac
