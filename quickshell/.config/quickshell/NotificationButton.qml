import QtQuick

// Bell with a count of unread notifications; click for the list.
Label {
    id: root
    signal clicked()

    readonly property int count: NotificationService.list.length

    font.pixelSize: Theme.fontSize + 3
    text: count > 0 ? "󰂚" : "󰂜"
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
        onClicked: root.clicked()
    }
}
