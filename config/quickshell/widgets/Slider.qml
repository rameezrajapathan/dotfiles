import QtQuick
import qs.services

Item {
    id: root
    property real value: 0
    property bool dimmed: false
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 20

    function set(v) {
        root.moved(Math.max(0, Math.min(1, v)));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: Theme.round(3, width, height)
        color: Theme.surface

        Rectangle {
            width: Math.min(1, root.value) * parent.width
            height: parent.height
            radius: parent.radius
            color: root.dimmed ? Theme.overlay : Theme.accent
            gradient: Theme.accentFill(!root.dimmed)
        }
    }

    Rectangle {
        width: 14
        height: 14
        radius: Theme.round(7, width, height)
        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(1, root.value) * (parent.width - width)
        color: root.dimmed ? Theme.subtext : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.set(mouse.x / width)
        onPositionChanged: mouse => { if (pressed) root.set(mouse.x / width); }
        onWheel: wheel => root.set(root.value + (wheel.angleDelta.y > 0 ? 0.03 : -0.03))
    }
}
