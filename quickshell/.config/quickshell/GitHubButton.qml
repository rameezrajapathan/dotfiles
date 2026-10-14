import QtQuick

// GitHub notifications with an unread count; hidden until gh is signed in. Click for the list.
Icon {
    id: root
    signal clicked()

    visible: GitHub.signedIn
    name: "commit"
    color: GitHub.unread > 0 ? Theme.text : Theme.overlay

    Rectangle {
        visible: GitHub.unread > 0
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
            text: GitHub.unread > 9 ? "9+" : GitHub.unread
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
