#!/usr/bin/env bash
set -euo pipefail

conf=~/.config/hypr/wallpaper.conf
state=~/.local/state/theme
mkdir -p "$state"

exec 9>"$state/.lock"
flock 9

current=$(sed -n 's/^\s*path\s*=\s*//p' "$conf")
current=${current/#\~/$HOME}

glass_only=false
if [[ ${1:-} == --glass ]]; then
	glass_only=true
	shift
fi

if [[ $# -gt 0 ]]; then
	img=$(realpath "$1")
	for monitor in $(hyprctl -j monitors | jq -r '.[].name'); do
		hyprctl hyprpaper wallpaper "$monitor,$img,cover" >/dev/null
	done
	printf 'wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "${img/#$HOME/\~}" >"$conf"
else
	img=$current
fi

small=$state/wallpaper-small.png
stamp="$img $(stat -c %Y "$img" 2>/dev/null)"
if [[ ! -s $small || $(cat "$state/wallpaper-small.src" 2>/dev/null) != "$stamp" ]]; then
	magick -define jpeg:size=1024x1024 "$img[0]" -resize '512x512>' "$small"
	printf '%s' "$stamp" >"$state/wallpaper-small.src"
fi

settings=~/.config/pikadots/settings.json
THEME_MODE=$(jq -r '.appearance.themeMode // "auto"' "$settings" 2>/dev/null || echo auto)
THEME_SCHEME=$(jq -r '.appearance.scheme // "auto"' "$settings" 2>/dev/null || echo auto)
glass_neutral=$(jq -r 'if ((.glass.preset // "frosted") != "off") and ((.glass.color // false) | not) then "yes" else "no" end' "$settings" 2>/dev/null || echo no)
[[ $glass_neutral == yes && ! -e ${XDG_RUNTIME_DIR:-/tmp}/pikadots-gamemode ]] && THEME_SCHEME=monochrome
export THEME_MODE THEME_SCHEME
palette=$(python3 -I ~/.config/hypr/scripts/theme-palette.py "$small")
mode=$(jq -r .theme.mode <<<"$palette")
scheme=$(jq -r .theme.scheme <<<"$palette")
python3 -I ~/.config/hypr/scripts/glass.py lua "$mode" || true
glass=$(python3 -I ~/.config/hypr/scripts/glass.py json "$mode" 2>/dev/null || echo '{}')
palette=$(jq -c --argjson glass "$glass" --arg wallpaper "$img" '. + $glass + {wallpaper: $wallpaper}' <<<"$palette")
matugen image "$small" --mode "$mode" --type "$scheme" --source-color-index 0 \
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
if $glass_only; then
	python3 -I ~/.config/hypr/scripts/vscode-theme.py || true
	python3 -I ~/.config/hypr/scripts/kde-theme.py || true
	exit 0
fi
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
