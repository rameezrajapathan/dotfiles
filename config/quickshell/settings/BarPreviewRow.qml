import QtQuick
import qs.services

Row {
    id: root
    property var modules: []
    property real barH: 16

    height: barH
    spacing: 3

    Repeater {
        model: root.modules

        Item {
            required property string modelData
            readonly property bool circle: ["workspaces", "avatar", "launcher"].includes(modelData)
            readonly property bool wide: ["clock", "date", "title", "media", "weather", "meeting", "system", "tray"].includes(modelData)
            width: modelData === "divider" ? 1
                : modelData === "title" || modelData === "media" ? 18
                : wide ? 10 : circle ? root.barH * 0.62 : 4
            height: root.barH

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.modelData === "divider" ? root.barH * 0.4 : parent.circle ? width : parent.wide ? 3 : 4
                radius: height / 2
                color: parent.circle ? Theme.accent : Qt.alpha(Theme.text, parent.modelData === "divider" ? 0.3 : 0.75)
            }
        }
    }
}
