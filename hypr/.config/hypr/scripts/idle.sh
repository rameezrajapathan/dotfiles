#!/usr/bin/env bash
# Starts hypridle with the timers from the Settings app (Power page), in minutes, 0 = never.
# Without choices it's the same as hypridle.conf: dim 5, lock 10, screen off 11, suspend 30.
# Usage: idle.sh   (autostart; also restarts a running hypridle, which the app does after a change)
set -u

settings=~/.config/pikadots/settings.json
get() {
	local v
	v=$(jq -r ".idle.$1 // empty" "$settings" 2>/dev/null)
	echo "${v:-$2}"
}
dim=$(get dimMinutes 5)
lock=$(get lockMinutes 10)
off=$(get screenOffMinutes 11)
sleep_after=$(get suspendMinutes 30)
lock_on_sleep=$(get lockBeforeSleep true)

conf=${XDG_RUNTIME_DIR:-/tmp}/hypridle.conf
{
	echo "general {"
	echo "    # The Quickshell lock screen, hyprlock as the fallback (scripts/lock.sh)"
	echo "    lock_cmd = ~/.config/hypr/scripts/lock.sh"
	[[ $lock_on_sleep == true ]] && echo "    before_sleep_cmd = loginctl lock-session"
	echo "    after_sleep_cmd = hyprctl dispatch dpms on"
	echo "}"
	listener() {
		(($1 > 0)) || return 0
		printf '\nlistener {\n    timeout = %d\n    on-timeout = %s\n' $(($1 * 60)) "$2"
		[[ -n ${3:-} ]] && printf '    on-resume = %s\n' "$3"
		echo "}"
	}
	listener "$dim" "brightnessctl -s set 10%" "brightnessctl -r"
	listener "$lock" "loginctl lock-session"
	listener "$off" "hyprctl dispatch dpms off" "hyprctl dispatch dpms on"
	listener "$sleep_after" "systemctl suspend"
} >"$conf"

pkill -x hypridle && sleep 0.2
exec hypridle -c "$conf"
