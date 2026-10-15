import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar listing every notification, newest first.
// A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    function toggle() {
        visible = !visible;
    }

    // Toasts would cover the list
    onVisibleChanged: if (visible) NotificationService.clearPopups()

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-list"
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 400
        height: content.implicitHeight + 28
        color: Theme.baseTranslucent
        radius: 10
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.bold: true
                }
                Pill {
                    visible: NotificationService.list.length > 0
                    icon: "clear_all"
                    onClicked: NotificationService.dismissAll()
                }
            }

            Label {
                visible: NotificationService.list.length === 0
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                text: "No notifications"
                color: Theme.overlay
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, root.height - Theme.barHeight - 120)
                visible: count > 0
                clip: true
                spacing: 8
                model: NotificationService.list

                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view.width
                    notification: modelData
                }
            }
        }
    }
}
