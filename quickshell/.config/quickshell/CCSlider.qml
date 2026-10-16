import QtQuick

// A thick slider for the control center: the filled part is accent colored, the icon sits inside
// on the left and the value on the right. Click or drag to set, scroll to nudge; clicking the
// icon calls `iconClicked` (mute).
Rectangle {
    id: root
    property real value: 0
    property string icon
    property bool dimmed: false
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 44
    radius: 16
    color: Qt.alpha(Theme.surface, 0.55)
    clip: true

    function set(v) {
        root.moved(Math.max(0, Math.min(1, v)));
    }

    readonly property real fillWidth: Math.max(44, Math.min(1, value) * width)

    Rectangle {
        width: root.fillWidth
        height: parent.height
        radius: root.radius
        color: root.dimmed ? Theme.overlay : Theme.accent
        Behavior on width {
            enabled: !drag.pressed
            NumberAnimation { duration: Theme.ms(120) }
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.set(mouse.x / width)
        onPositionChanged: mouse => { if (pressed) root.set(mouse.x / width); }
        onWheel: wheel => root.set(root.value + (wheel.angleDelta.y > 0 ? 0.03 : -0.03))
    }

    Icon {
        id: iconItem
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        filled: true
        color: root.dimmed ? Theme.base : Theme.accentText

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Label {
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        text: Math.round(root.value * 100) + "%"
        color: root.value > 0.9 ? Theme.accentText : Theme.subtext
        font.pixelSize: Theme.fontSize - 1
    }
}
