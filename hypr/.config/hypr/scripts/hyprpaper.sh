#!/usr/bin/env bash
# Starts hyprpaper with hyprpaper.conf plus the machine's own wallpaper.conf (not in git).
# A missing wallpaper.conf gets one of the bundled wallpapers.
set -euo pipefail

dir=~/.config/hypr
if [[ ! -f $dir/wallpaper.conf ]]; then
	printf 'wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' \
		'~/Pictures/Wallpapers/orange-forest.jpg' >"$dir/wallpaper.conf"
fi

conf=${XDG_RUNTIME_DIR:-/tmp}/hyprpaper.conf
cat "$dir/hyprpaper.conf" "$dir/wallpaper.conf" >"$conf"
exec hyprpaper -c "$conf"
