import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    signal clicked()

    implicitWidth: Theme.barVertical ? 22 : row.implicitWidth + 14
    implicitHeight: Theme.barVertical ? row.implicitHeight + 14 : 22
    radius: Theme.round(height / 2, width, height)
    color: Qt.alpha(Theme.yellow, mouse.containsMouse ? 0.3 : 0.18)
    Behavior on implicitWidth { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }

    GridLayout {
        id: row
        anchors.centerIn: parent
        flow: Theme.barVertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: [
                { on: Privacy.mic, icon: "mic" },
                { on: Privacy.camera, icon: "videocam" },
                { on: Privacy.screenShared, icon: "screen_share" }
            ].filter(m => m.on)
            Icon {
                required property var modelData
                name: modelData.icon
                filled: true
                size: 15
                color: Theme.yellow
            }
        }
        Label {
            visible: mouse.containsMouse && !Theme.barVertical
            text: Privacy.summary
            color: Theme.yellow
            font.pixelSize: Theme.fontSize - 2
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Tooltip {
        active: Theme.barVertical
        text: Privacy.summary
        side: Theme.awayFromBar
    }
}
