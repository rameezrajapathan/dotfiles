#!/usr/bin/env bash
set -euo pipefail

conf=~/.config/hypr/wallpaper.conf
state=~/.local/state/theme
mkdir -p "$state"

exec 9>"$state/.lock"
flock 9

current=$(sed -n 's/^\s*path\s*=\s*//p' "$conf")
current=${current/#\~/$HOME}

if [[ $# -gt 0 ]]; then
	img=$(realpath "$1")
	for monitor in $(hyprctl -j monitors | jq -r '.[].name'); do
		hyprctl hyprpaper wallpaper "$monitor,$img,cover" >/dev/null
	done
	printf 'wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "${img/#$HOME/\~}" >"$conf"
else
	img=$current
fi

settings=~/.config/pikadots/settings.json
THEME_MODE=$(jq -r '.appearance.themeMode // "auto"' "$settings" 2>/dev/null || echo auto)
THEME_SCHEME=$(jq -r '.appearance.scheme // "auto"' "$settings" 2>/dev/null || echo auto)
export THEME_MODE THEME_SCHEME
palette=$(python3 -I ~/.config/hypr/scripts/theme-palette.py "$img")
mode=$(jq -r .theme.mode <<<"$palette")
scheme=$(jq -r .theme.scheme <<<"$palette")
matugen image "$img" --mode "$mode" --type "$scheme" --source-color-index 0 \
	--import-json-string "$palette" --quiet

sed '/^\[palettes\.main\]/,$d' ~/.config/starship.toml >"$state/starship.toml.tmp"
cat "$state/starship-palette.toml" >>"$state/starship.toml.tmp"
mv "$state/starship.toml.tmp" "$state/starship.toml"

pkill -USR1 -x kitty || true
pkill -USR1 -x cava || true
pkill -USR2 -x btop || true
if command -v pywalfox >/dev/null; then
	for tmp in /tmp "${XDG_RUNTIME_DIR:-/tmp}"/pywalfox/*/; do
		{ TMPDIR=$tmp pywalfox "$mode" && TMPDIR=$tmp pywalfox update; } >/dev/null 2>&1 || true
	done
fi
if command -v asusctl >/dev/null; then
	accent=$(jq -r '.accent // empty' "$state/quickshell.json" | tr -d '#')
	[[ $scheme == scheme-monochrome ]] && accent=ffffff
	[[ -n $accent ]] && asusctl aura effect static -c "$accent" >/dev/null 2>&1 || true
fi
hyprctl reload >/dev/null
icon_theme=$("$(dirname "$0")/icons.sh" --name "$mode")
if [[ $mode == light ]]; then
	gtk_theme=adw-gtk3
else
	gtk_theme=adw-gtk3-dark
fi
gsettings set org.gnome.desktop.interface gtk-theme "''"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
prefer_dark=$([[ $mode == dark ]] && echo true || echo false)
for ini in ~/.config/gtk-{3,4}.0/settings.ini; do
	if [[ -f $ini ]]; then
		sed -i --follow-symlinks "s/^\(gtk-application-prefer-dark-theme=\).*/\1$prefer_dark/" "$ini"
	fi
done
python3 -I ~/.config/hypr/scripts/vscode-theme.py || true
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
