#!/usr/bin/env bash
# Applies Settings > Fonts outside the shell: the terminal font (kitty, through an included file)
# and, when "Use in apps" is on, the interface font for GTK apps.
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

# The marker remembers that these were set here, so turning it off only undoes our own change
if [ "$apps" = "true" ] && [ -n "$ui" ]; then
    gsettings set org.gnome.desktop.interface font-name "$ui 10"
    [ -n "$mono" ] && gsettings set org.gnome.desktop.interface monospace-font-name "$mono 10"
    touch "$state/app-fonts"
elif [ -e "$state/app-fonts" ]; then
    gsettings reset org.gnome.desktop.interface font-name
    gsettings reset org.gnome.desktop.interface monospace-font-name
    rm -f "$state/app-fonts"
fi
# Qt and KDE apps get the same interface fonts (kdeglobals)
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
# VS Code / Code - OSS editor and terminal font
python3 -I ~/.config/hypr/scripts/vscode-theme.py || true
