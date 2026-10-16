#!/usr/bin/env bash
set -euo pipefail

dir="$(xdg-user-dir PICTURES)/Screenshots"
geom= output=
last="${XDG_RUNTIME_DIR:-/tmp}/screenshot-last.png"

case ${1:-region} in
region) geom=$(slurp) || exit 0 ;;
active)
	geom=$(hyprctl activewindow -j | jq -r 'if .at then "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" else empty end')
	if [[ -z $geom ]]; then
		notify-send -e -a Screenshot "No window to capture" "Focus a window first, or use Print for a region."
		exit 0
	fi
	;;
full) output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name') ;;
esac

missing() {
	notify-send -a Screenshot -u critical "$1 isn't installed" "sudo pacman -S $2"
	exit 1
}

edit() {
	command -v satty >/dev/null || missing satty satty
	mkdir -p "$dir"
	satty --filename "$1" --output-filename "$dir/$(date +%Y%m%d-%H%M%S).png" \
		--copy-command wl-copy --early-exit --initial-tool arrow
}

notify() {
	local file=$1 title=$2 body=$3
	if command -v satty >/dev/null; then
		if [[ $(notify-send -a Screenshot -i "$file" -A edit=Edit "$title" "$body") == edit ]]; then
			edit "$file"
		fi
	else
		notify-send -a Screenshot -i "$file" "$title" "$body"
	fi
}

case ${2:-} in
save)
	mkdir -p "$dir"
	file="$dir/$(date +%Y%m%d-%H%M%S).png"
	grim ${geom:+-g "$geom"} ${output:+-o "$output"} - | tee "$file" | wl-copy
	notify "$file" "Screenshot saved" "Copied to the clipboard · ${file/#$HOME/\~}"
	;;
edit)
	grim ${geom:+-g "$geom"} ${output:+-o "$output"} "$last"
	edit "$last"
	;;
text)
	command -v tesseract >/dev/null || missing tesseract "tesseract tesseract-data-eng"
	text=$(grim ${geom:+-g "$geom"} ${output:+-o "$output"} - | tesseract stdin stdout 2>/dev/null | sed -e 's/[[:space:]]*$//' -e '/./,$!d')
	if [[ -z $text ]]; then
		notify-send -a Screenshot "No text found" "Try a larger or sharper area."
		exit 0
	fi
	printf '%s' "$text" | wl-copy
	notify-send -a Screenshot "Text copied" "$(head -c 200 <<<"$text")"
	;;
*)
	grim ${geom:+-g "$geom"} ${output:+-o "$output"} - | tee "$last" | wl-copy
	if command -v satty >/dev/null; then
		notify "$last" "Screenshot copied" "Edit to draw on it or save it"
	else
		notify "$last" "Screenshot copied" "Super + Shift + F also saves one"
	fi
	;;
esac
