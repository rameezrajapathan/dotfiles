import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property string icon
    property string label
    property bool confirm: false
    property bool armed: false
    signal activated()

    implicitWidth: 48
    implicitHeight: 48

    Timer {
        id: disarm
        interval: 4000
        onTriggered: root.armed = false
    }

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: Theme.round(width / 2, width, height)
        color: root.armed ? Qt.alpha(Theme.red, 0.9)
            : mouse.containsMouse ? Qt.alpha(Theme.surface, 0.85) : Qt.alpha(Theme.base, 0.45)
        border.width: 1
        border.color: Qt.alpha(Theme.text, root.armed ? 0 : 0.12)
        scale: mouse.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: Theme.ms(160) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: 22
            color: root.armed ? Theme.base : Theme.text
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 10
        width: tip.implicitWidth + 20
        height: 28
        radius: Theme.round(14, width, height)
        color: Qt.alpha(Theme.base, 0.8)
        opacity: mouse.containsMouse || root.armed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(150) } }

        Label {
            id: tip
            anchors.centerIn: parent
            text: root.armed ? "Click again to " + root.label.toLowerCase() : root.label
            font.family: Theme.displayFont
            color: root.armed ? Theme.red : Theme.text
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.confirm && !root.armed) {
                root.armed = true;
                disarm.restart();
                return;
            }
            root.armed = false;
            root.activated();
        }
    }
}
