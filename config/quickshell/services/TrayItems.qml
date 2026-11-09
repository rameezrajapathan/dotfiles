pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick

Singleton {
    id: root

    property var menuOnly: []

    function refresh() {
        reader.running = true;
    }

    readonly property int barCount: SystemTray.items.values.filter(i => !isHidden(i)).length

    function isHidden(item) {
        return (Settings.bar.hiddenTray ?? []).includes(item.id);
    }

    function setHidden(item, hide) {
        const list = (Settings.bar.hiddenTray ?? []).filter(id => id !== item.id);
        if (hide)
            list.push(item.id);
        Settings.bar.hiddenTray = list;
    }

    function isMenuOnly(item) {
        return item.onlyMenu || menuOnly.includes(item.id);
    }

    Process {
        id: reader
        command: ["sh", "-c", `
            busctl --user --json=short get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
                org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems |
            grep -o '"[^"]*/org/ayatana/[^"]*"' | tr -d '"' |
            while read -r item; do
                busctl --user get-property "\${item%%/*}" "/\${item#*/}" org.kde.StatusNotifierItem Id | cut -d'"' -f2
            done`]
        stdout: StdioCollector {
            onStreamFinished: root.menuOnly = text.split("\n").filter(s => s)
        }
    }
}
