import QtQuick
import qs.services
import qs.widgets

Flow {
    id: root
    property var options: []
    property var current
    signal picked(var value)

    spacing: 6

    Repeater {
        model: root.options

        Rectangle {
            id: chip
            required property var modelData
            readonly property bool selected: root.current === modelData.value

            implicitWidth: label.implicitWidth + 26
            implicitHeight: 30
            radius: Theme.round(height / 2, width, height)
            color: selected ? Theme.accent : mouse.containsMouse ? Qt.alpha(Theme.overlay, 0.35) : Qt.alpha(Theme.base, 0.6)
            border.width: selected ? 0 : 1
            border.color: Qt.alpha(Theme.overlay, 0.3)
            Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

            Label {
                id: label
                anchors.centerIn: parent
                text: chip.modelData.label
                color: chip.selected ? Theme.accentText : Theme.text
                font.pixelSize: Theme.fontSize - 1
                font.weight: chip.selected ? Font.DemiBold : Font.Normal
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(chip.modelData.value)
            }
        }
    }
}
