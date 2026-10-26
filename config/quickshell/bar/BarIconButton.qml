import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property string icon
    property color color: Theme.text
    property int size: Theme.iconSize
    property string tip: ""
    property string tipKeys: ""
    signal clicked()

    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    Icon {
        id: glyph
        anchors.centerIn: parent
        name: root.icon
        size: root.size
        color: root.color
        opacity: mouse.containsMouse ? 0.7 : 1
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Tooltip {
        text: root.tip
        keys: root.tipKeys
        side: Theme.awayFromBar
    }
}
