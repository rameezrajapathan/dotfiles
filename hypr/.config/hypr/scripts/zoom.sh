#!/usr/bin/env bash
# Screen zoom around the pointer (Hyprland's cursor:zoom_factor).
#   zoom.sh in|out|reset|<factor>    in/out step by 0.25, between 1 and 4
set -euo pipefail

current=$(hyprctl -j getoption cursor:zoom_factor | jq -r .float)
case ${1:-} in
in) target=$(awk -v z="$current" 'BEGIN { print z + 0.25 }') ;;
out) target=$(awk -v z="$current" 'BEGIN { print z - 0.25 }') ;;
reset) target=1 ;;
[0-9]*) target=$1 ;;
*)
	echo "usage: zoom.sh in|out|reset|<factor>" >&2
	exit 2
	;;
esac
target=$(awk -v z="$target" 'BEGIN { if (z < 1) z = 1; if (z > 4) z = 4; printf "%.2f", z }')
hyprctl eval "hl.config({ cursor = { zoom_factor = $target } })" >/dev/null
