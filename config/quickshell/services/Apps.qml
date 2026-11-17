pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

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
        if (url)
            raiseWindow.restart();
    }

    property string raiseAddress: ""

    Timer {
        id: raiseWindow
        interval: 4000
    }

    Timer {
        id: raiseLater
        interval: 250
        onTriggered: {
            Windows.refresh();
            Windows.focus(Hyprland.toplevels.values.find(t => t.address.replace(/^0x/, "") === root.raiseAddress));
        }
    }

    Connections {
        target: Hyprland
        enabled: raiseWindow.running
        function onRawEvent(event) {
            if (event.name !== "urgent")
                return;
            raiseWindow.stop();
            root.raiseAddress = event.data.replace(/^0x/, "");
            raiseLater.restart();
        }
    }
}
