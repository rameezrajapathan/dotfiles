import QtQuick
import qs.services

GlassSurface {
    id: root
    property real radius: 0
    anchors.fill: parent
    z: -1
    shadow: false
    band: Math.min(14, Math.min(width, height) / 3)

    Rectangle {
        width: root.width
        height: root.height
        radius: root.radius
        color: root.solid
    }
}
