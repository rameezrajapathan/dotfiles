import QtQuick

// Bell with a count of unread notifications (crossed out during Do Not Disturb); click for the
// list, right click toggles Do Not Disturb.
Icon {
    id: root
    signal clicked()

    readonly property int count: NotificationService.list.length

    name: NotificationService.dnd ? "notifications_off" : count > 0 ? "notifications_unread" : "notifications"
    filled: count > 0 && !NotificationService.dnd
    color: count > 0 ? Theme.text : Theme.overlay

    Rectangle {
        visible: root.count > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -5
        anchors.topMargin: -2
        width: Math.max(14, badge.implicitWidth + 6)
        height: 14
        radius: 7
        color: Theme.accent

        Label {
            id: badge
            anchors.centerIn: parent
            text: root.count > 9 ? "9+" : root.count
            color: Theme.accentText
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                NotificationService.dnd = !NotificationService.dnd;
            else
                root.clicked();
        }
    }
}
