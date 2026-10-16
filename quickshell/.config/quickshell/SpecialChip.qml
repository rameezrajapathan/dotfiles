import QtQuick

// Takes the workspace indicator's place while a special workspace (scratchpad, drop-down
// terminal) is open on this monitor (Workspaces.qml): its icon and name in Theme.special, the
// color its windows' borders have too. Click to hide it; vertical bars show just the icon.
Rectangle {
    id: root
    required property string name
    property bool vertical: false
    readonly property var info: Special.info(name)

    implicitHeight: Theme.pillCircle
    implicitWidth: vertical ? Theme.pillCircle : row.implicitWidth + 2 * 10
    radius: height / 2
    color: Theme.special
    scale: mouse.pressed ? 0.94 : mouse.containsMouse ? 1.04 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.info.icon
            filled: true
            size: 16
            color: Theme.specialText
        }
        Label {
            visible: !root.vertical
            anchors.verticalCenter: parent.verticalCenter
            text: root.info.label
            color: Theme.specialText
            font.bold: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Special.hide(root.name)
    }
}
