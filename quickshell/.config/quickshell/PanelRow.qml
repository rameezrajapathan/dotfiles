import QtQuick
import QtQuick.Layouts

// Clickable list row: icon, title, detail text, plus optional trailing items.
Rectangle {
    id: root
    property string icon
    property string title
    property string detail
    property bool highlighted: false
    property bool clickable: true
    default property alias trailing: trailingRow.data
    signal clicked()

    implicitHeight: 32
    radius: 6
    color: clickable && mouse.containsMouse ? Theme.surface : "transparent"

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: root.clickable
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 18
            filled: root.highlighted
            color: root.highlighted ? Theme.accent : Theme.text
        }
        Label {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
            color: root.highlighted ? Theme.accent : Theme.text
        }
        Label {
            visible: text !== ""
            text: root.detail
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 2
        }
        Row {
            id: trailingRow
            spacing: 6
        }
    }
}
