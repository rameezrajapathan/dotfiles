#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"

state=~/.local/state/pikadots
family=$(setting .appearance.iconTheme Papirus)

exists() {
	[[ -f ~/.local/share/icons/$1/index.theme || -f ~/.icons/$1/index.theme || -f /usr/share/icons/$1/index.theme ]]
}

variant() {
	local mode=$1
	if [[ $mode == dark ]]; then
		for v in "$family-Dark" "$family-dark"; do
			exists "$v" && { echo "$v"; return; }
		done
	fi
	exists "$family" && { echo "$family"; return; }
	echo Papirus-Dark
}

current_mode() {
	[[ $(gsettings get org.gnome.desktop.interface color-scheme) == *light* ]] && echo light || echo dark
}

if [[ ${1:-} == --name ]]; then
	variant "${2:-$(current_mode)}"
	exit
fi

theme=$(variant "$(current_mode)")
gsettings set org.gnome.desktop.interface icon-theme "$theme"
mkdir -p "$state"
variant dark >"$state/icon-theme"
fuzzel_ini=~/.local/state/theme/fuzzel.ini
[[ -f $fuzzel_ini ]] && sed -i "s/^icon-theme=.*/icon-theme=$theme/" "$fuzzel_ini"
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
setsid -f python3 -I ~/.config/hypr/scripts/folders.py >/dev/null 2>&1 || true

if [[ ${1:-} == --restart-shell ]]; then
	kill_shell
	setsid -f ~/.config/hypr/scripts/shell.sh >/dev/null 2>&1
	for _ in $(seq 20); do
		sleep 0.5
		qs ipc call settings open fonts >/dev/null 2>&1 && break
	done
fi
