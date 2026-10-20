#!/usr/bin/env bash
set -euo pipefail

settings=~/.config/pikadots/settings.json
state=~/.local/state/pikadots
mkdir -p "$state"

read_key() { jq -r ".appearance.$1 // empty" "$settings" 2>/dev/null || true; }
mono=$(read_key monoFont)
ui=$(read_key font)
apps=$(read_key appFonts)

if [ -n "$mono" ]; then
    printf 'font_family %s\n' "$mono" > "$state/kitty-font.conf"
else
    rm -f "$state/kitty-font.conf"
fi
pkill -USR1 -x kitty || true

if [ -n "$ui" ]; then
    printf 'osd-font="%s"\nsub-font="%s"\n' "$ui" "$ui" > "$state/mpv-font.conf"
else
    : > "$state/mpv-font.conf"
fi

if [ "$apps" = "true" ] && [ -n "$ui" ]; then
    gsettings set org.gnome.desktop.interface font-name "$ui 10"
    [ -n "$mono" ] && gsettings set org.gnome.desktop.interface monospace-font-name "$mono 10"
    touch "$state/app-fonts"
elif [ -e "$state/app-fonts" ]; then
    gsettings reset org.gnome.desktop.interface font-name
    gsettings reset org.gnome.desktop.interface monospace-font-name
    rm -f "$state/app-fonts"
fi
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
python3 -I ~/.config/hypr/scripts/vscode-theme.py || true
