import QtQuick
import QtQuick.Shapes
import qs.services

Shape {
    id: root
    readonly property Item host: parent && parent.radius === undefined && parent.parent ? parent.parent : parent
    readonly property real hostAlpha: host && host.color !== undefined ? Math.max(host.color.a, host.border && host.border.width > 0 ? host.border.color.a : 0) : 1
    property real radius: host?.radius ?? 0
    property real strength: 1
    property real borderWidth: 1
    readonly property point light: Glass.lightDir

    anchors.fill: parent
    visible: Glass.rim > 0 && width > 0 && height > 0 && hostAlpha > 0.01
    opacity: Math.min(1, Glass.rim * strength)
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeWidth: root.borderWidth
        strokeColor: Glass.rimColor
        strokeGradient: LinearGradient {
            x1: root.width / 2 - root.light.x * root.width / 2
            y1: root.height / 2 - root.light.y * root.height / 2
            x2: root.width / 2 + root.light.x * root.width / 2
            y2: root.height / 2 + root.light.y * root.height / 2
            GradientStop { position: 0; color: Qt.alpha(Glass.rimColor, 0.35) }
            GradientStop { position: 0.45; color: Glass.rimShade }
            GradientStop { position: 1; color: Glass.rimColor }
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
