import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property real along: 0
    property real size: 0
    property real thickness: 0
    property real ear: 0
    property bool flushStart: false
    property bool flushEnd: false
    property real overscan: 0
    property color color: "white"

    visible: ear > 0

    Rectangle {
        x: root.along - root.ear - root.overscan
        y: -root.overscan
        width: root.size + 2 * (root.ear + root.overscan)
        height: root.overscan
        color: root.color
    }
    Rectangle {
        visible: root.flushStart
        x: root.along - root.overscan
        y: -root.overscan
        width: root.overscan + 1
        height: root.thickness + root.ear + 2 * root.overscan
        color: root.color
    }
    Rectangle {
        visible: root.flushEnd
        x: root.along + root.size - 1
        y: -root.overscan
        width: root.overscan + 1
        height: root.thickness + root.ear + 2 * root.overscan
        color: root.color
    }

    Fillet {
        cx: root.along
        cy: root.flushStart ? root.thickness : 0
        dx: root.flushStart ? 1 : -1
        dy: 1
    }
    Fillet {
        cx: root.along + root.size
        cy: root.flushEnd ? root.thickness : 0
        dx: root.flushEnd ? -1 : 1
        dy: 1
    }

    component Fillet: Shape {
        id: fillet
        property real cx
        property real cy
        property int dx
        property int dy
        readonly property real e: root.ear
        width: 1
        height: 1
        visible: e > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            startX: fillet.cx - fillet.dx; startY: fillet.cy - fillet.dy
            PathLine { x: fillet.cx + fillet.dx * fillet.e; y: fillet.cy - fillet.dy }
            PathLine { x: fillet.cx + fillet.dx * fillet.e; y: fillet.cy }
            PathArc {
                x: fillet.cx
                y: fillet.cy + fillet.dy * fillet.e
                radiusX: fillet.e
                radiusY: fillet.e
                direction: fillet.dx * fillet.dy < 0 ? PathArc.Clockwise : PathArc.Counterclockwise
            }
            PathLine { x: fillet.cx - fillet.dx; y: fillet.cy + fillet.dy * fillet.e }
        }
    }
}
