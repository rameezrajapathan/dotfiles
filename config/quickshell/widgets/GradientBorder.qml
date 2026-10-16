import QtQuick
import QtQuick.Shapes
import qs.services

Shape {
    id: root
    property bool active: true
    property real borderWidth: parent?.border?.width ?? 1
    property real radius: parent?.radius ?? 0
    property real strength: 1

    anchors.fill: parent
    visible: active && Theme.gradientAccent && borderWidth > 0
    opacity: strength
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeWidth: root.borderWidth
        strokeColor: Theme.accent
        strokeGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: root.width
            y2: root.height
            GradientStop { position: 0; color: Theme.accent }
            GradientStop { position: 1; color: Theme.accentEnd }
        }
        PathRectangle {
            x: root.borderWidth / 2
            y: root.borderWidth / 2
            width: Math.max(0, root.width - root.borderWidth)
            height: Math.max(0, root.height - root.borderWidth)
            radius: Math.max(0, root.radius - root.borderWidth / 2)
        }
    }
}
