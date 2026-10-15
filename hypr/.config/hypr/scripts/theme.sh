#!/usr/bin/env bash
# Sets the wallpaper and recolors everything from it with matugen.
# Usage: theme.sh [image]   (no image: regenerate from the current wallpaper)
set -euo pipefail

conf=~/.config/hypr/wallpaper.conf
state=~/.local/state/theme
mkdir -p "$state"

# One run at a time when wallpapers are clicked quickly
exec 9>"$state/.lock"
flock 9

current=$(sed -n 's/^\s*path\s*=\s*//p' "$conf")
current=${current/#\~/$HOME}

if [[ $# -gt 0 ]]; then
	img=$(realpath "$1")
	for monitor in $(hyprctl -j monitors | jq -r '.[].name'); do
		hyprctl hyprpaper wallpaper "$monitor,$img,cover" >/dev/null
	done
	# This machine's wallpaper, kept out of git (scripts/hyprpaper.sh loads it at login)
	printf 'wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "${img/#$HOME/\~}" >"$conf"
else
	img=$current
fi

# Light or dark and how colorful, from the wallpaper itself: black and white pictures give a grey
# theme, bright ones a light theme (theme-palette.py)
palette=$(python3 -I ~/.config/hypr/scripts/theme-palette.py "$img")
mode=$(jq -r .theme.mode <<<"$palette")
scheme=$(jq -r .theme.scheme <<<"$palette")
matugen image "$img" --mode "$mode" --type "$scheme" --source-color-index 0 \
	--import-json-string "$palette" --quiet

# Starship has no include: base config with its palette swapped for the generated one
sed '/^\[palettes\.main\]/,$d' ~/.config/starship.toml >"$state/starship.toml.tmp"
cat "$state/starship-palette.toml" >>"$state/starship.toml.tmp"
mv "$state/starship.toml.tmp" "$state/starship.toml"

# Live reloads. Quickshell and Alacritty watch their files; fuzzel reads its config on launch.
pkill -USR1 -x kitty || true
# cava reloads its config (and so themes/wallpaper) on USR1
pkill -USR1 -x cava || true
# Zen and Firefox through the Pywalfox extension: one socket per open browser (pywalfox-host),
# plus the default one for a browser started through the package's own manifest
if command -v pywalfox >/dev/null; then
	for tmp in /tmp "${XDG_RUNTIME_DIR:-/tmp}"/pywalfox/*/; do
		{ TMPDIR=$tmp pywalfox "$mode" && TMPDIR=$tmp pywalfox update; } >/dev/null 2>&1 || true
	done
fi
# ROG keyboard lighting in the accent color (asusctl; skipped on other laptops)
if command -v asusctl >/dev/null; then
	accent=$(jq -r '.accent // empty' "$state/quickshell.json" | tr -d '#')
	# A black and white theme's accent is black in light mode, which would switch the lights off
	[[ $scheme == scheme-monochrome ]] && accent=ffffff
	[[ -n $accent ]] && asusctl aura effect static -c "$accent" >/dev/null 2>&1 || true
fi
hyprctl reload >/dev/null
# Re-applying the GTK theme makes running GTK3 apps (Thunar) reload gtk.css
# (light or dark variant to match); color-scheme is what libadwaita apps and websites follow
if [[ $mode == light ]]; then
	gtk_theme=adw-gtk3 icon_theme=Papirus
else
	gtk_theme=adw-gtk3-dark icon_theme=Papirus-Dark
fi
gsettings set org.gnome.desktop.interface gtk-theme "''"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
# GTK3 also reads prefer-dark from settings.ini, which would keep adw-gtk3 dark
prefer_dark=$([[ $mode == dark ]] && echo true || echo false)
for ini in ~/.config/gtk-{3,4}.0/settings.ini; do
	if [[ -f $ini ]]; then
		sed -i --follow-symlinks "s/^\(gtk-application-prefer-dark-theme=\).*/\1$prefer_dark/" "$ini"
	fi
done
