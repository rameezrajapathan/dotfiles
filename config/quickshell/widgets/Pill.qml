import QtQuick
import qs.services

Rectangle {
    id: root
    property alias text: label.text
    property string icon: ""
    property bool active: false
    signal clicked()

    implicitWidth: icon ? implicitHeight : label.implicitWidth + 16
    implicitHeight: 22
    radius: Theme.round(height / 2, width, height)
    color: active ? Theme.selectedFill : mouse.containsMouse ? Theme.overlay : Theme.glassFill(2)
    gradient: Theme.accentFill(active)

    GlassRim {
        strength: 0.7
    }

    Label {
        id: label
        visible: !root.icon
        anchors.centerIn: parent
        color: root.active ? Theme.selectedText : Theme.text
        font.pixelSize: Theme.fontSize - 2
    }

    Icon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        name: root.icon
        size: 16
        color: root.active ? Theme.selectedText : Theme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
