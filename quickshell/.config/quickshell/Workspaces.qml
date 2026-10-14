import Quickshell.Hyprland
import QtQuick

// One dot per workspace; the focused one stretches into an accent pill.
Row {
    spacing: 2

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0)

        Item {
            id: ws
            required property var modelData
            readonly property bool focused: modelData.focused

            width: dot.width + 10
            height: 20

            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: ws.focused ? 24 : 8
                height: 8
                radius: height / 2
                color: ws.focused ? Theme.accent
                    : ws.modelData.urgent ? Theme.red
                    : mouse.containsMouse ? Theme.text
                    : Theme.overlay

                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.modelData.activate()
            }
        }
    }
}
