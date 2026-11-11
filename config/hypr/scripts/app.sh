#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(readlink -f "$0")")/lib.sh"

kind=${1:-}
shift || true

entry_key() {
	awk -F= -v key="$2" '/^\[/ { main = ($0 == "[Desktop Entry]") } main && $1 == key { sub(/^[^=]*=/, ""); print; exit }' "$1"
}

terminal() {
	if has xdg-terminal-exec; then
		exec xdg-terminal-exec "$@"
	fi
	local args=()
	while (($#)); do
		case $1 in
		--app-id=*) args+=(--class "${1#*=}") ;;
		--dir=*) args+=(--working-directory "${1#*=}") ;;
		--hold) args+=(--hold) ;;
		--) shift; break ;;
		*) break ;;
		esac
		shift
	done
	(($#)) && args+=(--)
	exec "${TERMINAL:-kitty}" "${args[@]}" "$@"
}

launch() {
	local id=$1 dir=$2
	shift 2
	local file=
	[[ -n $id ]] && file=$(desktop_entry "$id") || file=
	if [[ -z $file ]]; then
		(($#)) && exec xdg-open "$1"
		echo "app.sh: no default app set" >&2
		notify-send -a Apps -i dialog-warning "No default app" "Pick one in Settings > Default apps." 2>/dev/null || true
		exit 1
	fi
	if [[ $(entry_key "$file" Terminal) == true ]]; then
		local cmd opts=()
		read -ra cmd <<<"$(entry_key "$file" Exec | sed -E 's/ ?%[a-zA-Z]//g')"
		[[ -n $dir ]] && opts+=(--dir="$dir")
		terminal "${opts[@]}" -- "${cmd[@]}" "$@"
	fi
	exec gtk-launch "$id" "$@"
}

case $kind in
terminal) terminal "$@" ;;
browser) launch "$(xdg-settings get default-web-browser 2>/dev/null)" "" "$@" ;;
files) launch "$(xdg-mime query default inode/directory)" "" "${1:-$HOME}" ;;
open)
	target=${1:?usage: app.sh open PATH|URI}
	[[ $target == "~"* ]] && target=$HOME${target:1}
	if [[ -d $target ]]; then
		mime=inode/directory
	elif [[ -e $target ]]; then
		mime=$(xdg-mime query filetype "$target" 2>/dev/null)
	elif [[ $target =~ ^([A-Za-z][A-Za-z0-9+.-]*): ]]; then
		mime=x-scheme-handler/${BASH_REMATCH[1],,}
	else
		notify-send -a Shortcuts -i dialog-warning "Not found" "$target doesn't exist any more." 2>/dev/null || true
		exit 1
	fi
	id=$(xdg-mime query default "$mime" 2>/dev/null)
	[[ -z $id ]] && exec xdg-open "$target"
	launch "$id" "" "$target"
	;;
editor)
	dir=
	(($#)) && [[ -d $1 ]] && dir=$1
	launch "$(xdg-mime query default text/plain)" "$dir" "$@"
	;;
*)
	echo "usage: app.sh terminal|browser|files|editor|open [args...]" >&2
	exit 2
	;;
esac
