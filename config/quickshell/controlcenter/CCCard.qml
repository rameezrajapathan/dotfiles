import QtQuick
import qs.services

Rectangle {
    id: root
    property bool clickable: false
    property real padding: Theme.pad(14, 22)
    signal clicked()

    radius: Theme.round(22, width, height)
    color: clickable && mouse.containsMouse ? Qt.alpha(Theme.surface, 0.5) : Qt.alpha(Theme.surface, 0.3)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
