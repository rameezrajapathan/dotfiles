#!/usr/bin/env bash
# App icon theme from Settings > Fonts & icons (.appearance.iconTheme, a family like "Papirus"),
# in its dark or light variant to match the current mode.
#   icons.sh                 set GTK's icon theme
#   icons.sh --restart-shell also restart Quickshell, which reads its icon theme only at start
#   icons.sh --name [MODE]   print the variant for MODE (dark/light; default: current mode)
set -euo pipefail

settings=~/.config/pikadots/settings.json
state=~/.local/state/pikadots
family=$(jq -r '.appearance.iconTheme // empty' "$settings" 2>/dev/null || true)
family=${family:-Papirus}

exists() {
	[[ -f ~/.local/share/icons/$1/index.theme || -f ~/.icons/$1/index.theme || -f /usr/share/icons/$1/index.theme ]]
}

# Dark mode: Name-Dark or Name-dark when the theme has one; light mode: the theme itself
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
# Quickshell uses the dark variant: its panels are dark or tinted either way
variant dark >"$state/icon-theme"
# Qt and KDE apps
python3 -I ~/.config/hypr/scripts/kde-theme.py || true

if [[ ${1:-} == --restart-shell ]]; then
	qs kill >/dev/null 2>&1 || true
	sleep 0.5
	setsid -f ~/.config/hypr/scripts/shell.sh >/dev/null 2>&1
	# Back to where the change was made
	for _ in $(seq 20); do
		sleep 0.5
		qs ipc call settings open fonts >/dev/null 2>&1 && break
	done
fi
