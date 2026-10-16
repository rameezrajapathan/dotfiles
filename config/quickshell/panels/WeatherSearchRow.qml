import QtQuick
import qs.services
import qs.widgets

Rectangle {
    id: row
    property string icon
    property string title
    property string subtitle
    property bool accent: false
    signal picked()

    width: parent?.width ?? 0
    height: 42
    radius: Theme.round(10, width, height)
    color: rowMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"

    Icon {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        name: row.icon
        filled: true
        size: 18
        color: row.accent ? Theme.accent : Theme.subtext
    }
    Column {
        x: 40
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 52
        Label {
            width: parent.width
            text: row.title
            color: Theme.text
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: row.subtitle
            color: Theme.subtext
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize - 2
        }
    }
    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.picked()
    }
}
