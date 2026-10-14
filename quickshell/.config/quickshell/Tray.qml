import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// Background apps' tray icons (OneDrive, Remmina, ...). Left click activates,
// right click (or left on menu-only items) opens the app's menu, scroll is passed on.
// Ayatana AppIndicator items (Remmina, many GTK apps) only have a menu and ignore activate, but
// don't say so; they're found by their /org/ayatana/ path in the tray watcher.
Repeater {
    id: root
    required property var bar

    // Ids of Ayatana items
    property var menuOnly: []

    model: SystemTray.items
    onCountChanged: ayatana.running = true
    Component.onCompleted: ayatana.running = true

    // A Repeater's only child is its delegate, so the process lives in a property
    property Process ayatana: Process {
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

    IconImage {
        id: icon
        required property SystemTrayItem modelData

        implicitSize: 18
        source: {
            // Some apps send a themed path like "name?path=/dir"; load the file directly
            const s = modelData.icon;
            if (s.includes("?path=")) {
                const [name, path] = s.split("?path=");
                return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
            }
            return s;
        }
        opacity: modelData.status === Status.Passive ? 0.6 : 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                const item = icon.modelData;
                if (mouse.button === Qt.MiddleButton) {
                    item.secondaryActivate();
                } else if (mouse.button === Qt.RightButton || item.onlyMenu || root.menuOnly.includes(item.id)) {
                    if (item.hasMenu) {
                        const p = icon.mapToItem(null, 0, icon.height + 10);
                        item.display(root.bar, p.x, p.y);
                    }
                } else {
                    item.activate();
                }
            }
            onWheel: wheel => icon.modelData.scroll(wheel.angleDelta.y / 120, false)
        }
    }
}
