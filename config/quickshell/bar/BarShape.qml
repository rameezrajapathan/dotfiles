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
    readonly property bool attached: Theme.barAttached
    readonly property real ear: Theme.barEar
    readonly property real thickness: Theme.barEdgeGap + Theme.pillHeight
    readonly property real barLength: vertical ? parent.height : parent.width
    readonly property bool flushStart: attached && along < 1
    readonly property bool flushEnd: attached && along + size > barLength - 1
    x: vertical ? Theme.barCrossStart : along
    y: vertical ? along : Theme.barCrossStart
    width: vertical ? Theme.pillHeight : size
    height: vertical ? size : Theme.pillHeight

    Item {
        id: floating
        anchors.fill: parent
        visible: !root.attached

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

    Item {
        id: attachedLayer
        readonly property real overscan: 16
        readonly property real origin: root.along - root.ear - overscan
        readonly property real extent: root.vertical ? root.parent.width : root.parent.height
        readonly property matrix4x4 edgeMatrix: {
            const t = Qt.matrix4x4(1, 0, 0, origin, 0, 1, 0, -overscan, 0, 0, 1, 0, 0, 0, 0, 1);
            let e;
            switch (Theme.barPosition) {
            case "bottom": e = Qt.matrix4x4(1, 0, 0, 0, 0, -1, 0, extent, 0, 0, 1, 0, 0, 0, 0, 1); break;
            case "left": e = Qt.matrix4x4(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1); break;
            case "right": e = Qt.matrix4x4(0, -1, 0, extent, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1); break;
            default: e = Qt.matrix4x4();
            }
            return e.times(t);
        }
        onEdgeMatrixChanged: edgeGlass.updateMap()
        parent: root.parent
        z: -1
        visible: root.attached && root.visible && !root.bare
        x: 0
        y: 0

        GlassSurface {
            id: edgeGlass
            width: root.size + 2 * (root.ear + attachedLayer.overscan)
            height: root.thickness + root.ear + 2 * attachedLayer.overscan
            shadow: false
            band: Math.min(12, Theme.pillHeight / 3)
            transform: Matrix4x4 { matrix: attachedLayer.edgeMatrix }

            Item {
                x: attachedLayer.overscan
                y: attachedLayer.overscan

                Rectangle {
                    x: root.ear
                    y: -attachedLayer.overscan
                    width: root.size
                    height: root.thickness + attachedLayer.overscan
                    color: edgeGlass.solid
                    bottomLeftRadius: root.flushStart ? 0 : root.radius
                    bottomRightRadius: root.flushEnd ? 0 : root.radius
                }

                BarEars {
                    along: root.ear
                    size: root.size
                    thickness: root.thickness
                    ear: root.ear
                    overscan: attachedLayer.overscan
                    flushStart: root.flushStart
                    flushEnd: root.flushEnd
                    color: edgeGlass.solid
                }
            }
        }
    }
}
