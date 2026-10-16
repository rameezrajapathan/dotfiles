import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: root
    property real value: 0
    property real size: 64
    property color tint: Theme.accent
    property color tintEnd: Theme.shade(tint)
    property bool dimmed: false
    property string text: Math.round(clamped * 100) + "%"

    readonly property real clamped: Math.max(0, Math.min(1, value))
    readonly property real thickness: Math.max(5, Math.round(size / 10))
    readonly property real r: (size - thickness) / 2
    property real shown: clamped
    Behavior on shown { NumberAnimation { duration: Theme.ms(450); easing.type: Easing.OutCubic } }

    implicitWidth: size
    implicitHeight: size

    ConicalGradient {
        id: arcGradient
        centerX: root.size / 2
        centerY: root.size / 2
        angle: 90
        GradientStop { position: 0; color: root.tintEnd }
        GradientStop { position: Math.min(0.999, Math.max(0, 1 - root.shown)); color: root.tintEnd }
        GradientStop { position: 1; color: root.tint }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(Theme.surface, 0.9)
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: 0
                sweepAngle: 360
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.dimmed ? Theme.overlay : root.tint
            strokeGradient: root.dimmed || !Theme.gradientAccent ? null : arcGradient
            strokeWidth: root.shown > 0.005 ? root.thickness : 0
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.r
                radiusY: root.r
                startAngle: -90
                sweepAngle: 360 * root.shown
            }
        }
    }

    Label {
        anchors.centerIn: parent
        text: root.text
        color: root.dimmed ? Theme.overlay : Theme.text
        font.pixelSize: Math.round(root.size * 0.24)
        font.weight: Font.DemiBold
    }
}
