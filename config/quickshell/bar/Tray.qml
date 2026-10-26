import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Repeater {
    id: root
    required property var bar

    property var menuOnly: []

    model: SystemTray.items
    onCountChanged: ayatana.running = true
    Component.onCompleted: ayatana.running = true

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
                        const edge = Theme.barPosition;
                        const p = icon.mapToItem(null, edge === "left" ? icon.width + 10 : edge === "right" ? -10 : 0,
                            edge === "bottom" ? -10 : edge === "top" ? icon.height + 10 : 0);
                        item.display(root.bar, p.x, p.y);
                    }
                } else {
                    item.activate();
                }
            }
            onWheel: wheel => icon.modelData.scroll(wheel.angleDelta.y / 120, false)
        }

        Tooltip {
            text: icon.modelData.tooltipTitle || icon.modelData.title || icon.modelData.id
            side: Theme.awayFromBar
        }
    }
}
