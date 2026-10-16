import QtQuick
import QtQuick.Shapes
import qs.services

Item {
    id: root
    property string kind: "play"
    property color color: Theme.text
    property real size: 18

    implicitWidth: size
    implicitHeight: size

    Row {
        anchors.centerIn: parent
        visible: root.kind === "pause"
        spacing: root.size * 0.22

        Repeater {
            model: 2
            Rectangle {
                width: root.size * 0.28
                height: root.size * 0.9
                radius: Theme.round(width * 0.35, width, height)
                color: root.color
            }
        }
    }

    Shape {
        id: glyph
        anchors.fill: parent
        visible: root.kind !== "pause"
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.kind === "previous" ? -1 : 1; origin.x: root.size / 2 }

        readonly property real s: root.size
        readonly property bool skip: root.kind === "next" || root.kind === "previous"
        readonly property real x0: skip ? s * 0.12 : s * 0.2
        readonly property real x1: skip ? s * 0.66 : s * 0.9

        ShapePath {
            fillColor: root.color
            strokeColor: root.color
            strokeWidth: root.size * 0.16
            joinStyle: ShapePath.RoundJoin
            startX: glyph.x0; startY: glyph.s * 0.1
            PathLine { x: glyph.x1; y: glyph.s * 0.5 }
            PathLine { x: glyph.x0; y: glyph.s * 0.9 }
            PathLine { x: glyph.x0; y: glyph.s * 0.1 }
        }
        ShapePath {
            strokeColor: glyph.skip ? root.color : "transparent"
            fillColor: "transparent"
            strokeWidth: root.size * 0.16
            capStyle: ShapePath.RoundCap
            startX: glyph.s * 0.86; startY: glyph.s * 0.1
            PathLine { x: glyph.s * 0.86; y: glyph.s * 0.9 }
        }
    }
}
