import QtQuick

// Small rounded button with a text label, or round with an icon (Material Symbols name).
Rectangle {
    id: root
    property alias text: label.text
    property string icon: ""
    property bool active: false
    signal clicked()

    implicitWidth: icon ? implicitHeight : label.implicitWidth + 16
    implicitHeight: 22
    radius: height / 2
    color: active ? Theme.accent : mouse.containsMouse ? Theme.overlay : Theme.surface

    Label {
        id: label
        visible: !root.icon
        anchors.centerIn: parent
        color: root.active ? Theme.accentText : Theme.text
        font.pixelSize: Theme.fontSize - 2
    }

    Icon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        name: root.icon
        size: 16
        color: root.active ? Theme.accentText : Theme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
