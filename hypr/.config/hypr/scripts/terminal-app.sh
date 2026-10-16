#!/usr/bin/env bash
# Launcher entries for terminal apps that open with their own window class, so window rules
# (Settings app > Window rules) can match them instead of every terminal window:
#   terminal-app.sh add CLASS NAME ICON COMMAND    new entry CLASS.desktop running COMMAND
#   terminal-app.sh wrap ID CLASS                  copy of the installed entry ID (e.g. btop.desktop)
#                                                  that runs in the terminal as CLASS; it shadows
#                                                  the original, so the launcher lists it once
#                                                  (prints the entry written: ID, or CLASS.desktop
#                                                  when the user has their own ID)
#   terminal-app.sh remove ID                      delete an entry made here (the original returns)
# Entries are written to ~/.local/share/applications and marked X-Pikadots-TerminalApp=true;
# they start through app.sh terminal, so they follow the default terminal.
set -euo pipefail

apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
app="$HOME/.config/hypr/scripts/app.sh"
marker="X-Pikadots-TerminalApp=true"

# A value for Exec=: the command line run by sh, quoted as the desktop entry spec asks
# (\ " ` $ escaped inside double quotes, then every backslash doubled for the string type)
exec_quote() {
	local s
	s=$(printf '%s' "$1" | sed -e 's/[\\"`$]/\\&/g' -e 's/\\/\\\\/g')
	printf '"%s"' "$s"
}

ours() {
	[ -f "$1" ] && grep -qx "$marker" "$1"
}

# The installed entry ID outside the user's own directory
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
		# The user's own entry (maybe a symlink into a repo): never write through it; add a
		# separate entry next to it instead
		src=$file
		file="$apps/$class.desktop"
	else
		src=$(system_entry "$id") || { echo "no installed entry $id" >&2; exit 1; }
	fi
	mkdir -p "$apps"
	# Exec without field codes (%f, %U, ...), which have nothing to fill in from the launcher
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
	# The entry to remove later
	basename "$file"
	;;
remove)
	[ $# -eq 2 ] || { echo "usage: $0 remove ID" >&2; exit 2; }
	file="$apps/${2%.desktop}.desktop"
	ours "$file" && rm -f "$file"
	;;
*)
	sed -n '2,9p' "$0" >&2
	exit 2
	;;
esac
command -v update-desktop-database >/dev/null && update-desktop-database "$apps" 2>/dev/null || true
