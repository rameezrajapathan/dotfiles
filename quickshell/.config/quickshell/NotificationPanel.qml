import Quickshell
import QtQuick
import QtQuick.Layouts

// Control center tab listing every notification, newest first.
Item {
    id: root
    // Set by ControlCenter while this tab is on screen
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    // Toasts would cover the list
    onShownChanged: if (shown) NotificationService.clearPopups()

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
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
