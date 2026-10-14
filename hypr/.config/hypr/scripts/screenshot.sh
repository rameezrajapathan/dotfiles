#!/usr/bin/env bash
# Usage: screenshot.sh region|full|active [save]
# Always copies to the clipboard; "save" also writes to ~/Pictures/Screenshots.
set -euo pipefail

case ${1:-region} in
    region) geom=$(slurp) || exit 0 ;;
    active) geom=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"') ;;
    full)   geom= ;;
esac

if [[ ${2:-} == save ]]; then
    dir="$(xdg-user-dir PICTURES)/Screenshots"
    mkdir -p "$dir"
    file="$dir/$(date +%Y%m%d-%H%M%S).png"
    grim ${geom:+-g "$geom"} - | tee "$file" | wl-copy
    notify-send -a Screenshot -i "$file" "Screenshot saved" "Copied to the clipboard · ${file/#$HOME/\~}"
else
    grim ${geom:+-g "$geom"} - | wl-copy
fi
