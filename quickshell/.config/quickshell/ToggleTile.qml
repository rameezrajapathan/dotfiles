import QtQuick
import QtQuick.Layouts

// On/off tile for the Account tab's quick settings: icon, label and a short state line.
Rectangle {
    id: tile
    property string icon
    property string label
    property string detail
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 58
    radius: 14
    color: active ? Theme.accent : tileMouse.containsMouse ? Theme.surface : Qt.alpha(Theme.surface, 0.6)
    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
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
