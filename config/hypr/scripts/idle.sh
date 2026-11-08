#!/usr/bin/env bash
set -u

if [[ -z ${INVOCATION_ID:-} ]] && systemctl --user is-enabled -q pikadots-idle.service 2>/dev/null; then
	exec systemctl --user restart pikadots-idle.service
fi

. "$(dirname "$(readlink -f "$0")")/lib.sh"
dim=$(setting .idle.dimMinutes 5)
lock=$(setting .idle.lockMinutes 10)
off=$(setting .idle.screenOffMinutes 11)
sleep_after=$(setting .idle.suspendMinutes 30)
lock_on_sleep=$(setting .idle.lockBeforeSleep true)

conf=${XDG_RUNTIME_DIR:-/tmp}/hypridle.conf
{
	echo "general {"
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
