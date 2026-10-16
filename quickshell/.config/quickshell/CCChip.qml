import QtQuick

// A small rounded label with an icon, clickable (status chips in the control center).
Rectangle {
    id: root
    property string icon
    property string text
    property bool highlight: false
    property color tint: Theme.accent
    signal clicked()

    implicitWidth: row.implicitWidth + 24
    implicitHeight: 30
    radius: height / 2
    color: highlight ? Qt.alpha(tint, mouse.containsMouse ? 0.32 : 0.2)
        : Qt.alpha(Theme.surface, mouse.containsMouse ? 0.85 : 0.55)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 16
            color: root.highlight ? root.tint : Theme.subtext
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.highlight ? root.tint : Theme.subtext
            font.pixelSize: Theme.fontSize - 2
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
