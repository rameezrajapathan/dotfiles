import QtQuick
import qs.services

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 36
    implicitHeight: 20
    radius: Theme.round(height / 2, width, height)
    color: checked ? Theme.accent : Theme.surface

    Rectangle {
        width: 14
        height: 14
        radius: Theme.round(7, width, height)
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.accentText : Theme.subtext

        Behavior on x { NumberAnimation { duration: Theme.ms(120) } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
