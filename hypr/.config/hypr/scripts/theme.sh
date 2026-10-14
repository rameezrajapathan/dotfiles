#!/usr/bin/env bash
# Sets the wallpaper and recolors everything from it with matugen.
# Usage: theme.sh [image]   (no image: regenerate from the current wallpaper)
set -euo pipefail

conf=~/.config/hypr/hyprpaper.conf
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
	# --follow-symlinks keeps the symlink into ~/dotfiles intact
	sed -i --follow-symlinks "s|^\(\s*path\s*=\s*\).*|\1${img/#$HOME/\~}|" "$conf"
else
	img=$current
fi

matugen image "$img" --mode dark --source-color-index 0 --quiet

# Starship has no include: base config with its palette swapped for the generated one
sed '/^\[palettes\.main\]/,$d' ~/.config/starship.toml >"$state/starship.toml.tmp"
cat "$state/starship-palette.toml" >>"$state/starship.toml.tmp"
mv "$state/starship.toml.tmp" "$state/starship.toml"

# Live reloads. Quickshell and Alacritty watch their files; fuzzel reads its config on launch.
pkill -USR1 -x kitty || true
# cava reloads its config (and so themes/wallpaper) on USR1
pkill -USR1 -x cava || true
hyprctl reload >/dev/null
# Re-applying the GTK theme makes running GTK3 apps (Thunar) reload gtk.css
gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
gsettings set org.gnome.desktop.interface gtk-theme "''"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
