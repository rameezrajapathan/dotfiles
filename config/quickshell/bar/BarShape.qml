import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property bool bare: false
    property real along: 0
    property real size: 0
    readonly property bool vertical: Theme.barVertical
    readonly property real radius: Theme.pillRadius
    x: vertical ? Theme.barGap : along
    y: vertical ? along : Theme.barGap
    width: vertical ? Theme.pillHeight : size
    height: vertical ? size : Theme.pillHeight

    GlassSurface {
        id: glass
        anchors.fill: parent
        visible: !root.bare
        shadow: false
        band: Math.min(12, Theme.pillHeight / 3)

        Rectangle {
            width: glass.width
            height: glass.height
            radius: root.radius
            color: glass.solid
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.bare && Settings.bar.border
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(Theme.overlay, 0.5)
    }
}
