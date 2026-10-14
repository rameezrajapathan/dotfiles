import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

// Background apps' tray icons (OneDrive, Remmina, ...). Left click activates,
// right click (or left on menu-only items) opens the app's menu, scroll is passed on.
Repeater {
    id: root
    required property var bar

    model: SystemTray.items

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
                } else if (mouse.button === Qt.RightButton || item.onlyMenu) {
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
