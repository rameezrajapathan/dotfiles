pragma Singleton

import Quickshell
import QtQuick

// The system's default apps (hypr/scripts/app.sh): the panels and launcher open the default
// terminal, browser, file manager or editor through here instead of naming one.
Singleton {
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh"

    // `options` are xdg-terminal-exec's: "--dir=PATH", "--hold", "--app-id=ID"
    function terminal(command, options) {
        Quickshell.execDetached([script, "terminal"].concat(options ?? [], command?.length ? ["--"].concat(command) : []));
    }

    function files(dir) {
        Quickshell.execDetached([script, "files"].concat(dir ? [dir] : []));
    }

    function editor(path) {
        Quickshell.execDetached([script, "editor"].concat(path ? [path] : []));
    }

    function browser(url) {
        Quickshell.execDetached([script, "browser"].concat(url ? [url] : []));
    }
}
