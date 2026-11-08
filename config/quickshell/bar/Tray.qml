import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Repeater {
    id: root
    required property var bar

    model: SystemTray.items
    onCountChanged: TrayItems.refresh()
    Component.onCompleted: TrayItems.refresh()

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
                } else if (mouse.button === Qt.RightButton || TrayItems.isMenuOnly(item)) {
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
