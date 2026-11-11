#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"

state=~/.local/state/theme
mkdir -p "$state"

exec 9>"$state/.lock"
flock 9

current=$(wallpaper_path)

glass_only=false
if [[ ${1:-} == --glass ]]; then
	glass_only=true
	shift
fi

if [[ $# -gt 0 ]]; then
	img=$(realpath "$1")
	wallpaper_save "$img"
else
	img=$current
fi

small=$state/wallpaper-small.png
stamp="$img $(stat -c %Y "$img" 2>/dev/null)"
if [[ ! -s $small || $(cat "$state/wallpaper-small.src" 2>/dev/null) != "$stamp" ]]; then
	magick -define jpeg:size=1024x1024 "$img[0]" -resize '512x512>' "$small"
	printf '%s' "$stamp" >"$state/wallpaper-small.src"
fi

THEME_MODE=$(setting .appearance.themeMode auto)
THEME_SCHEME=$(setting .appearance.scheme auto)
glass_neutral=$(setting 'if ((.glass.preset // "frosted") != "off") and ((.glass.color // false) | not) then "yes" else "no" end' no)
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
icon_theme=$("$(dirname "$0")/icons.sh" --name "$mode")
printf '[main]\nicon-theme=%s\n' "$icon_theme" >>"$state/fuzzel.ini"

sed '/^\[palettes\.main\]/,$d' ~/.config/starship.toml >"$state/starship.toml.tmp"
cat "$state/starship-palette.toml" >>"$state/starship.toml.tmp"
mv "$state/starship.toml.tmp" "$state/starship.toml"

pkill -USR1 -x kitty || true
pkill -USR1 -x cava || true
pkill -USR2 -x btop || true
if has nvim; then
	for sock in "${XDG_RUNTIME_DIR:-/tmp}"/nvim.*.0; do
		[[ -S $sock ]] || continue
		timeout 1 nvim --server "$sock" --remote-expr \
			"execute('if get(g:, \"colors_name\", \"\") ==# \"pikadots\" | colorscheme pikadots | endif')" >/dev/null 2>&1 || true
	done
fi
if has pywalfox; then
	for tmp in /tmp "${XDG_RUNTIME_DIR:-/tmp}"/pywalfox/*/; do
		{ TMPDIR=$tmp pywalfox "$mode" && TMPDIR=$tmp pywalfox update; } >/dev/null 2>&1 || true
	done
fi
if has asusctl; then
	accent=$(jq -r '.accent // empty' "$state/quickshell.json" | tr -d '#')
	[[ $scheme == scheme-monochrome ]] && accent=ffffff
	[[ -n $accent ]] && asusctl aura effect static -c "$accent" >/dev/null 2>&1 || true
fi
python3 -I ~/.config/hypr/scripts/folders.py >/dev/null 2>&1 || true
has pikadots && { setsid -f pikadots greeter sync --later >/dev/null 2>&1 9>&- || true; }
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || exit 0
hyprctl reload >/dev/null
gtk_base=adw-gtk3
[[ $mode == dark ]] && gtk_base=adw-gtk3-dark
gtk_theme=$gtk_base
for dir in ~/.local/share/themes ~/.themes /usr/share/themes; do
	[[ -f $dir/$gtk_base/gtk-3.0/gtk.css ]] || continue
	gtk_theme=pikadots${gtk_base#adw-gtk3}
	own=~/.local/share/themes/$gtk_theme
	mkdir -p "$own/gtk-3.0" "$own/gtk-4.0"
	printf '[Desktop Entry]\nType=X-GNOME-Metatheme\nName=%s\n\n[X-GNOME-Metatheme]\nGtkTheme=%s\n' "$gtk_theme" "$gtk_theme" >"$own/index.theme"
	for v in 3.0 4.0; do
		printf '@import url("file://%s");\n@import url("file://%s");\n' "$dir/$gtk_base/gtk-$v/gtk.css" "$state/gtk.css" >"$own/gtk-$v/gtk.css"
	done
	break
done
gsettings set org.gnome.desktop.interface gtk-theme "''"
sleep 0.3
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
if $glass_only; then
	python3 -I ~/.config/hypr/scripts/vscode-theme.py || true
	python3 -I ~/.config/hypr/scripts/kde-theme.py || true
	exit 0
fi
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
