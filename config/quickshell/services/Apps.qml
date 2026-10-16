pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh"

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
