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

        // Nothing to show: a quiet note in the middle of the page
        ColumnLayout {
            visible: NotificationService.list.length === 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -20
            spacing: 6

            Icon {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 6
                name: NotificationService.quiet ? "notifications_paused" : "notifications"
                size: 52
                weight: 200
                color: Theme.accent
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "You're all caught up"
                font.pixelSize: Theme.fontSize + 3
                font.weight: Font.DemiBold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: NotificationService.dnd ? "Do Not Disturb is on: only urgent ones pop up."
                    : NotificationService.scheduledQuiet ? "Quiet hours: only urgent ones pop up."
                    : "New notifications will show up here."
                color: Theme.subtext
            }
        }

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
                    icon: NotificationService.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                    active: NotificationService.dnd
                    onClicked: NotificationService.dnd = !NotificationService.dnd
                }
                Pill {
                    visible: NotificationService.list.length > 0
                    icon: "clear_all"
                    onClicked: NotificationService.dismissAll()
                }
            }


            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, root.height - Theme.barSpaceY - 120)
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
