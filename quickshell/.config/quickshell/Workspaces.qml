import Quickshell.Hyprland
import QtQuick

Row {
    spacing: 4

    Repeater {
        model: Hyprland.workspaces.values.filter(ws => ws.id > 0)

        Rectangle {
            required property var modelData
            readonly property bool focused: modelData.focused

            width: 26
            height: 20
            radius: 6
            color: focused ? Theme.accent : (mouse.containsMouse ? Theme.surface : "transparent")

            Label {
                anchors.centerIn: parent
                text: modelData.id
                color: parent.focused ? Theme.base : (modelData.urgent ? Theme.red : Theme.text)
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: modelData.activate()
            }
        }
    }
}
