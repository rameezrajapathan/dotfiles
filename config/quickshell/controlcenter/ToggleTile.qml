import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: tile
    property string icon
    property string label
    property string detail
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 58
    radius: Theme.round(14, width, height)
    color: active ? Theme.accent : tileMouse.containsMouse ? Theme.surface : Qt.alpha(Theme.surface, 0.6)
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.pad(12, 14, parent.width, parent.height)
        anchors.rightMargin: Theme.pad(10, 14, parent.width, parent.height)
        spacing: 10

        Icon {
            name: tile.icon
            filled: tile.active
            color: tile.active ? Theme.accentText : Theme.text
            size: 22
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: tile.label
                color: tile.active ? Theme.accentText : Theme.text
                font.bold: true
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                text: tile.detail
                color: tile.active ? Qt.alpha(Theme.accentText, 0.75) : Theme.subtext
                font.pixelSize: Theme.fontSize - 3
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
