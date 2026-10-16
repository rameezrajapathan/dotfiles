import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Toasts on the focused monitor, newest nearest the edge; where, how many and how wide come from
// the Settings app (Notifications page).
PanelWindow {
    readonly property string position: Settings.notifications.position
    readonly property bool bottom: position.startsWith("bottom")

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
        top: !bottom
        bottom: bottom
        right: position.endsWith("right")
        left: position.endsWith("left")
    }
    // Clear of the bar, whichever edge it's on
    margins {
        top: (Theme.barPosition === "top" ? Theme.barHeight : 0) + 6
        bottom: (Theme.barPosition === "bottom" ? Theme.barHeight : 0) + 8
        right: (Theme.barPosition === "right" ? Theme.barHeight : 0) + 8
        left: (Theme.barPosition === "left" ? Theme.barHeight : 0) + 8
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    implicitWidth: Settings.notifications.width
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    visible: NotificationService.popups.length > 0

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            // Cap the stack; the rest are still in the list
            // Newest next to the edge: at the bottom, the list runs upward
            model: bottom ? NotificationService.popups.slice(0, Settings.notifications.maxPopups).reverse()
                : NotificationService.popups.slice(0, Settings.notifications.maxPopups)

            NotificationCard {
                required property var modelData
                width: column.width
                notification: modelData
                popup: true
            }
        }
    }
}
