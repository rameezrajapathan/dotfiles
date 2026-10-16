#!/usr/bin/env bash
set -euo pipefail

pins=~/.local/share/pikadots/clipboard-pins
settings=~/.config/pikadots/settings.json

setting() {
	jq -r ".launcher.$1 // empty" "$settings" 2>/dev/null || true
}

case ${1:-} in
watch)
	max=$(setting clipboardSize)
	persist=$(setting clipboardPersist)
	pkill -f '^wl-paste --watch cliphist' || true
	pkill -x wl-clip-persist || true
	setsid -f wl-paste --watch cliphist -max-items "${max:-750}" store >/dev/null 2>&1
	if [[ $persist != false ]] && command -v wl-clip-persist >/dev/null; then
		setsid -f wl-clip-persist --clipboard regular >/dev/null 2>&1
	fi
	;;
pins)
	mkdir -p "$pins"
	for f in $(ls -1t "$pins"); do
		if [[ $f != *.txt ]]; then
			printf '%s\t[[ image ]]\n' "$pins/$f"
		else
			printf '%s\t%s\n' "$pins/$f" "$(head -c 400 "$pins/$f" | tr '\n\t' '  ')"
		fi
	done
	;;
pin)
	mkdir -p "$pins"
	tmp=$(mktemp "$pins/.new.XXXXXX")
	printf '%s\t' "$2" | cliphist decode >"$tmp"
	type=$(file -b --mime-type "$tmp")
	case $type in
	image/*) ext=${type#image/} ;;
	*) ext=txt ;;
	esac
	mv "$tmp" "$pins/$(date +%s%N).$ext"
	;;
unpin)
	[[ $2 == "$pins"/* ]] && rm -f -- "$2"
	;;
copy-pin)
	if [[ $2 != *.txt ]]; then
		wl-copy --type "$(file -b --mime-type "$2")" <"$2"
	else
		wl-copy <"$2"
	fi
	;;
wipe)
	cliphist wipe
	rm -rf "${XDG_RUNTIME_DIR:-/tmp}/quickshell-clipboard"
	;;
*)
	echo "usage: clipboard.sh watch | pins | pin ID | unpin FILE | copy-pin FILE | wipe" >&2
	exit 2
	;;
esac
