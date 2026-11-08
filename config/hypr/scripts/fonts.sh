#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"

state=~/.local/state/pikadots
mkdir -p "$state"

mono=$(setting .appearance.monoFont)
ui=$(setting .appearance.font)
apps=$(setting .appearance.appFonts)

if [[ -n $mono ]]; then
	printf 'font_family %s\n' "$mono" >"$state/kitty-font.conf"
else
	rm -f "$state/kitty-font.conf"
fi
pkill -USR1 -x kitty || true

if [[ -n $ui ]]; then
	printf 'osd-font="%s"\nsub-font="%s"\n' "$ui" "$ui" >"$state/mpv-font.conf"
else
	: >"$state/mpv-font.conf"
fi

if [[ $apps == true && -n $ui ]]; then
	gsettings set org.gnome.desktop.interface font-name "$ui 10"
	[[ -n $mono ]] && gsettings set org.gnome.desktop.interface monospace-font-name "$mono 10"
	touch "$state/app-fonts"
elif [[ -e $state/app-fonts ]]; then
	gsettings reset org.gnome.desktop.interface font-name
	gsettings reset org.gnome.desktop.interface monospace-font-name
	rm -f "$state/app-fonts"
fi
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
python3 -I ~/.config/hypr/scripts/vscode-theme.py || true
