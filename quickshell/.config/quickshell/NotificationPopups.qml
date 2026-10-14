import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Toasts in the top-right corner of the focused monitor, newest on top.
PanelWindow {
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + 6; right: 8 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    implicitWidth: 380
    implicitHeight: Math.max(1, column.implicitHeight)
    color: "transparent"
    visible: NotificationService.popups.length > 0

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            // Cap the stack; the rest are still in the list
            model: NotificationService.popups.slice(0, 5)

            NotificationCard {
                required property var modelData
                width: column.width
                notification: modelData
                popup: true
            }
        }
    }
}
