import QtQuick
import QtQuick.Shapes
import qs.services

Shape {
    id: root
    readonly property var host: parent && parent.radius === undefined && parent.parent ? parent.parent : parent
    readonly property real hostAlpha: host && host.color !== undefined ? host.color.a : 1
    property real radius: host?.radius ?? 0
    property real strength: 1
    property real borderWidth: 1
    readonly property point light: Glass.lightDir
    readonly property bool hostBorder: {
        const b = host?.border;
        if (!b || b.width <= 0 || b.color.a <= 0.01)
            return false;
        return !(b.color.r === 0 && b.color.g === 0 && b.color.b === 0 && b.color.a === 1);
    }

    anchors.fill: parent
    visible: width > 0 && height > 0 && hostAlpha > 0.01 && (Glass.flat ? !hostBorder : Glass.rim > 0)
    opacity: Glass.flat ? 1 : Math.min(1, Glass.rim * strength)
    preferredRendererType: Shape.CurveRenderer

    property LinearGradient rimGradient: LinearGradient {
        x1: root.width / 2 - root.light.x * root.width / 2
        y1: root.height / 2 - root.light.y * root.height / 2
        x2: root.width / 2 + root.light.x * root.width / 2
        y2: root.height / 2 + root.light.y * root.height / 2
        GradientStop { position: 0; color: Qt.alpha(Glass.rimColor, 0.35) }
        GradientStop { position: 0.45; color: Glass.rimShade }
        GradientStop { position: 1; color: Glass.rimColor }
    }

    ShapePath {
        fillColor: "transparent"
        strokeWidth: root.borderWidth
        strokeColor: Glass.flat ? Glass.outline : Glass.rimColor
        strokeGradient: Glass.flat ? null : root.rimGradient
        PathRectangle {
            x: root.borderWidth / 2
            y: root.borderWidth / 2
            width: Math.max(0, root.width - root.borderWidth)
            height: Math.max(0, root.height - root.borderWidth)
            radius: Math.max(0, root.radius - root.borderWidth / 2)
        }
    }
}
