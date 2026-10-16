#!/usr/bin/env bash
# Opens the system's default app of a kind, so keybinds and the bar never name one:
#   app.sh terminal [--app-id=ID] [--dir=DIR] [--hold] [command...]
#                                 ~/.config/xdg-terminals.list, via xdg-terminal-exec
#   app.sh browser [url]          xdg-settings get default-web-browser
#   app.sh files [dir]            xdg-mime query default inode/directory
#   app.sh editor [path]          xdg-mime query default text/plain
# Change a default with xdg-settings / xdg-mime, or by editing xdg-terminals.list.
set -u

kind=${1:-}
shift || true

# Path of an installed desktop entry, by id (user entries first, like the desktop does)
desktop_file() {
    local dir
    IFS=: read -ra dirs <<<"${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for dir in "${dirs[@]}"; do
        [ -f "$dir/applications/$1" ] && { echo "$dir/applications/$1"; return; }
    done
}

# Value of a key in the [Desktop Entry] group
entry_key() {
    awk -F= -v key="$2" '/^\[/ { main = ($0 == "[Desktop Entry]") } main && $1 == key { sub(/^[^=]*=/, ""); print; exit }' "$1"
}

terminal() {
    if command -v xdg-terminal-exec >/dev/null; then
        exec xdg-terminal-exec "$@"
    fi
    # Without xdg-terminal-exec: $TERMINAL, with kitty's spelling of the options
    local args=()
    while [ $# -gt 0 ]; do
        case $1 in
            --app-id=*) args+=(--class "${1#*=}") ;;
            --dir=*) args+=(--working-directory "${1#*=}") ;;
            --hold) args+=(--hold) ;;
            --) shift; break ;;
            *) break ;;
        esac
        shift
    done
    [ $# -gt 0 ] && args+=(--)
    exec "${TERMINAL:-kitty}" "${args[@]}" "$@"
}

# Launches a desktop entry with arguments; terminal apps (Neovim, micro, ...) go into the
# default terminal, started in `dir` when given
launch() {
    local id=$1 dir=$2
    shift 2
    local file
    file=$(desktop_file "$id")
    if [ -z "$id" ] || [ -z "$file" ]; then
        [ $# -gt 0 ] && exec xdg-open "$1"
        echo "app.sh: no default app set" >&2
        notify-send -a Apps -i dialog-warning "No default app" "Pick one in Settings > Default apps." 2>/dev/null
        exit 1
    fi
    if [ "$(entry_key "$file" Terminal)" = true ]; then
        # Exec without its field codes (%f, %U, ...), then our arguments
        local cmd
        read -ra cmd <<<"$(entry_key "$file" Exec | sed -E 's/ ?%[a-zA-Z]//g')"
        local opts=()
        [ -n "$dir" ] && opts+=(--dir="$dir")
        terminal "${opts[@]}" -- "${cmd[@]}" "$@"
    fi
    exec gtk-launch "$id" "$@"
}

case $kind in
    terminal) terminal "$@" ;;
    browser) launch "$(xdg-settings get default-web-browser 2>/dev/null)" "" "$@" ;;
    files) launch "$(xdg-mime query default inode/directory)" "" "${1:-$HOME}" ;;
    editor)
        # A folder (a project) also becomes the working directory
        dir=""
        [ $# -gt 0 ] && [ -d "$1" ] && dir=$1
        launch "$(xdg-mime query default text/plain)" "$dir" "$@"
        ;;
    *)
        echo "usage: app.sh terminal|browser|files|editor [args...]" >&2
        exit 2
        ;;
esac
