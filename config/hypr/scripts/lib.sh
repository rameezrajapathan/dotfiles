#!/usr/bin/env bash

pikadots_settings=$HOME/.config/pikadots/settings.json
wallpaper_conf=$HOME/.config/hypr/wallpaper.conf

if command -v pacman >/dev/null; then
	pikadots_pm=pacman
elif command -v dnf >/dev/null; then
	pikadots_pm=dnf
else
	pikadots_pm=
fi

has() { command -v "$1" >/dev/null; }

setting() {
	local v
	v=$(jq -r "$1 | if . == null then empty else . end" "$pikadots_settings" 2>/dev/null) || v=
	printf '%s\n' "${v:-${2:-}}"
}

pikadots_repo() {
	if [[ -n ${PIKADOTS_DIR:-} ]]; then
		printf '%s\n' "$PIKADOTS_DIR"
		return
	fi
	local here
	here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
	git -C "$here" rev-parse --show-toplevel 2>/dev/null || (cd "$here/../../.." && pwd)
}

aur_helper() { command -v paru || command -v yay; }

pkg_name() {
	case $pikadots_pm:$1 in
	dnf:qt6-shadertools) echo qt6-qtshadertools ;;
	dnf:tesseract-data-eng) echo tesseract-langpack-eng ;;
	*) echo "$1" ;;
	esac
}

pkg_names() {
	local p
	for p; do pkg_name "$p"; done
}

install_hint() {
	local names
	names=$(pkg_names "$@" | paste -sd ' ')
	case $pikadots_pm in
	dnf) echo "sudo dnf install $names" ;;
	*) echo "sudo pacman -S $names" ;;
	esac
}

pkg_install() {
	local yes=()
	if [[ ${1:-} == -y ]]; then
		yes=(--noconfirm)
		[[ $pikadots_pm == dnf ]] && yes=(-y)
		shift
	fi
	(($#)) || return 0
	case $pikadots_pm in
	pacman) sudo pacman -S --needed "${yes[@]}" "$@" ;;
	dnf) sudo dnf install "${yes[@]}" "$@" ;;
	*) return 1 ;;
	esac
}

pkg_remove() {
	case $pikadots_pm in
	pacman) sudo pacman -Rns "$@" ;;
	dnf) sudo dnf remove "$@" ;;
	*) return 1 ;;
	esac
}

wallpaper_path() {
	local p
	p=$(sed -n 's/^\s*path\s*=\s*//p' "$wallpaper_conf" 2>/dev/null) || p=
	printf '%s\n' "${p/#\~/$HOME}"
}

wallpaper_save() {
	printf 'wallpaper {\n    monitor =\n    path = %s\n    fit_mode = cover\n}\n' "${1/#$HOME/\~}" >"$wallpaper_conf"
}

kill_shell() {
	pkill -u "$USER" -x 'qs|quickshell' >/dev/null 2>&1 || return 0
	local _
	for _ in $(seq 20); do
		pgrep -u "$USER" -x 'qs|quickshell' >/dev/null || return 0
		sleep 0.1
	done
	pkill -9 -u "$USER" -x 'qs|quickshell' >/dev/null 2>&1
	sleep 0.2
	return 0
}

desktop_entry() {
	local dir dirs path=${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
	[[ ${2:-} == system ]] && path=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
	IFS=: read -ra dirs <<<"$path"
	for dir in "${dirs[@]}"; do
		[[ -f $dir/applications/$1 ]] && { echo "$dir/applications/$1"; return 0; }
	done
	return 1
}
