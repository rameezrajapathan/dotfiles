#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"

pins=~/.local/share/pikadots/clipboard-pins

case ${1:-} in
watch)
	max=$(setting .launcher.clipboardSize 750)
	persist=$(setting .launcher.clipboardPersist true)
	pkill -f '^wl-paste --watch cliphist' || true
	pkill -x wl-clip-persist || true
	setsid -f wl-paste --watch cliphist -max-items "$max" store >/dev/null 2>&1
	if [[ $persist != false ]] && has wl-clip-persist; then
		setsid -f wl-clip-persist --clipboard regular >/dev/null 2>&1
	fi
	;;
pins)
	mkdir -p "$pins"
	while IFS= read -r -d '' f; do
		f=${f#* }
		if [[ $f != *.txt ]]; then
			printf '%s\t[[ image ]]\n' "$f"
		else
			printf '%s\t%s\n' "$f" "$(head -c 400 "$f" | tr '\n\t' '  ')"
		fi
	done < <(find "$pins" -mindepth 1 -maxdepth 1 ! -name '.*' -printf '%T@ %p\0' | sort -zrn)
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
