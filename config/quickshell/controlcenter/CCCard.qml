import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: root
    property bool clickable: false
    property real padding: Theme.pad(14, 22)
    signal clicked()

    radius: Theme.round(22, width, height)
    color: Theme.glassFill(1, clickable && mouse.containsMouse)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    GlassRim {}

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
