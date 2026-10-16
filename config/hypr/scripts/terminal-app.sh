#!/usr/bin/env bash
set -euo pipefail

apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
app="$HOME/.config/hypr/scripts/app.sh"
marker="X-Pikadots-TerminalApp=true"

exec_quote() {
	local s
	s=$(printf '%s' "$1" | sed -e 's/[\\"`$]/\\&/g' -e 's/\\/\\\\/g')
	printf '"%s"' "$s"
}

ours() {
	[ -f "$1" ] && grep -qx "$marker" "$1"
}

system_entry() {
	local dir
	IFS=: read -ra dirs <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
	for dir in "${dirs[@]}"; do
		[ -f "$dir/applications/$1" ] && { echo "$dir/applications/$1"; return; }
	done
	return 1
}

case ${1:-} in
add)
	[ $# -eq 5 ] || { echo "usage: $0 add CLASS NAME ICON COMMAND" >&2; exit 2; }
	class=$2 name=$3 icon=$4 cmd=$5
	first=${cmd%%[[:space:]]*}
	command -v "$first" >/dev/null || { echo "$first isn't installed" >&2; exit 1; }
	file="$apps/$class.desktop"
	[ -e "$file" ] && ! ours "$file" && { echo "$file exists and isn't ours" >&2; exit 1; }
	mkdir -p "$apps"
	cat >"$file" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$cmd in the terminal
Icon=$icon
Exec=$app terminal --app-id=$class -- sh -c $(exec_quote "$cmd")
Terminal=false
Categories=ConsoleOnly;
StartupWMClass=$class
$marker
EOF
	;;
wrap)
	[ $# -eq 3 ] || { echo "usage: $0 wrap ID CLASS" >&2; exit 2; }
	id=$2 class=$3
	file="$apps/$id"
	if ours "$file"; then
		src=$(system_entry "$id") || { echo "no installed entry $id" >&2; exit 1; }
	elif [ -e "$file" ]; then
		src=$file
		file="$apps/$class.desktop"
	else
		src=$(system_entry "$id") || { echo "no installed entry $id" >&2; exit 1; }
	fi
	mkdir -p "$apps"
	awk -v app="$app" -v class="$class" -v marker="$marker" '
		/^\[/ { main = ($0 == "[Desktop Entry]") }
		main && /^Exec=/ {
			cmd = substr($0, 6)
			gsub(/ ?%[fFuUdDnNickvm]/, "", cmd)
			print "Exec=" app " terminal --app-id=" class " -- " cmd
			next
		}
		main && /^(Terminal|StartupWMClass|TryExec|DBusActivatable|NoDisplay|Hidden)=/ { next }
		{ print }
		main && /^\[Desktop Entry\]$/ { print "Terminal=false"; print "StartupWMClass=" class; print marker }
	' "$src" >"$file.tmp"
	mv "$file.tmp" "$file"
	basename "$file"
	;;
remove)
	[ $# -eq 2 ] || { echo "usage: $0 remove ID" >&2; exit 2; }
	file="$apps/${2%.desktop}.desktop"
	ours "$file" && rm -f "$file"
	;;
*)
	echo "usage: terminal-app.sh add CLASS NAME ICON COMMAND | wrap ID CLASS" >&2
	exit 2
	;;
esac
command -v update-desktop-database >/dev/null && update-desktop-database "$apps" 2>/dev/null || true
