import Quickshell
import QtQuick
import QtQuick.Shapes
import qs.bar
import qs.services

Item {
    id: root
    property bool open: false
    property real sheetWidth: 600
    property real sheetHeight: 400
    property real radius: Theme.round(24)
    property real ear: 14
    property color color: Theme.baseTranslucent
    property string kind: ""
    property var anchorIds: {
        switch (kind) {
        case "settings": return ["avatar"];
        case "calendar": return ["clock", "date"];
        case "weather": return ["weather"];
        }
        return [];
    }
    default property alias content: inner.data
    signal closed()
    signal dismiss()

    property string motion: PanelMotion.style
    property real progress: 0
    readonly property real shown: PanelMotion.clamp(progress)
    readonly property var shapeNow: PanelMotion.shape(motion, progress)

    NumberAnimation {
        id: motionAnim
        target: root
        property: "progress"
        onRunningChanged: if (!running && !root.open) root.closed()
    }

    readonly property string edge: Theme.barPosition
    readonly property bool vertical: Theme.barVertical
    readonly property real length: vertical ? height : width
    readonly property real sheetAlong: vertical ? sheetHeight : sheetWidth
    readonly property real sheetDepth: vertical ? sheetWidth : sheetHeight

    property var anchor: ({ index: bar.strip ? 0 : 1, cx: length / 2 })
    function measureAnchor() {
        if (open && length > 0)
            anchor = bar.anchorFor(anchorIds);
    }
    onLengthChanged: Qt.callLater(measureAnchor)
    onOpenChanged: {
        measureAnchor();
        const style = PanelMotion.info(motion);
        motionAnim.stop();
        motionAnim.to = open ? 1 : 0;
        motionAnim.duration = open ? PanelMotion.openDuration(motion) : PanelMotion.closeDuration();
        motionAnim.easing.type = open ? style.easing : Easing.OutCubic;
        motionAnim.easing.overshoot = style.overshoot ?? 1.70158;
        motionAnim.start();
    }

    readonly property bool strip: bar.strip
    readonly property Item shape: bar.shapes[anchor.index] ?? bar.shapes[1]
    readonly property real shapeX: shape.along
    readonly property real shapeWidth: shape.size
    readonly property real shapeTop: Theme.barEdgeGap
    readonly property real shapeHeight: Theme.pillHeight
    readonly property real shapeBottom: shapeTop + shapeHeight
    readonly property real shapeRadius: Theme.pillRadius
    readonly property real reach: ear + radius + 4
    readonly property real overscan: Theme.barAttached ? 16 : 0

    readonly property bool pillFlushLeft: shapeX < reach
    readonly property bool pillFlushRight: length - shapeX - shapeWidth < reach
    readonly property real bodyWidth: strip ? Math.min(sheetAlong, shapeWidth)
        : pillFlushLeft && pillFlushRight ? shapeWidth
        : Math.max(sheetAlong, shapeWidth + 2 * reach - 8)
    readonly property bool flushLeft: strip ? centeredX - ear < shapeX + shapeRadius : pillFlushLeft
    readonly property bool flushRight: strip ? centeredX + bodyWidth + ear > shapeX + shapeWidth - shapeRadius
        : pillFlushRight
    readonly property real centeredX: strip
        ? Math.max(shapeX, Math.min(shapeX + shapeWidth - bodyWidth, Math.round(anchor.cx - bodyWidth / 2)))
        : Math.max(4, Math.min(length - 4 - bodyWidth, Math.round(shapeX + (shapeWidth - bodyWidth) / 2)))
    readonly property real bodyX: flushLeft ? shapeX
        : flushRight ? shapeX + shapeWidth - bodyWidth
        : centeredX
    readonly property real startWidth: strip ? Math.min(bodyWidth, 160) : Math.min(shapeWidth, bodyWidth)
    readonly property real startX: strip
        ? Math.max(shapeX, Math.min(shapeX + shapeWidth - startWidth, anchor.cx - startWidth / 2))
        : shapeX + (shapeWidth - startWidth) / 2
    readonly property real curWidth: startWidth + (bodyWidth - startWidth) * shapeNow.w
    readonly property real curX: startX + (bodyX - startX) * shapeNow.w
    readonly property real curHeight: Math.max(0, sheetDepth * shapeNow.h)
    readonly property real slide: shapeNow.y * sheetDepth
    readonly property real topRound: PanelMotion.clamp((curWidth - startWidth) / (2 * reach))

    readonly property bool covering: progress > 0
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    property int coverKey: 0
    Component.onCompleted: coverKey = Panels.newKey()
    onCoveringChanged: Panels.cover(coverKey, screenName, covering)
    onScreenNameChanged: if (covering) Panels.cover(coverKey, screenName, true)
    Component.onDestruction: Panels.cover(coverKey, "", false)

    anchors.fill: parent

    readonly property matrix4x4 edgeMatrix: {
        switch (edge) {
        case "bottom": return Qt.matrix4x4(1, 0, 0, 0, 0, -1, 0, height, 0, 0, 1, 0, 0, 0, 0, 1);
        case "left": return Qt.matrix4x4(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        case "right": return Qt.matrix4x4(0, -1, 0, width, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        }
        return Qt.matrix4x4();
    }
    function place(a, d, la, ld, extent) {
        switch (edge) {
        case "bottom": return Qt.rect(a, extent - d - ld, la, ld);
        case "left": return Qt.rect(d, a, ld, la);
        case "right": return Qt.rect(extent - d - ld, a, ld, la);
        }
        return Qt.rect(a, d, la, ld);
    }

    GlassSurface {
        id: background
        visible: root.covering
        width: root.length + 2 * root.overscan
        height: root.shapeBottom + Math.max(root.sheetDepth, root.curHeight) + root.overscan
        tint: root.color
        band: 16
        transform: Matrix4x4 {
            matrix: root.edgeMatrix.times(Qt.matrix4x4(1, 0, 0, -root.overscan, 0, 1, 0, -root.overscan, 0, 0, 1, 0, 0, 0, 0, 1))
        }

        Item {
            x: root.overscan
            y: root.overscan

            Item {
                x: root.curX
                y: root.shapeBottom
                width: root.curWidth
                height: root.curHeight
                clip: true

                Rectangle {
                    y: root.slide
                    width: parent.width
                    height: root.shapeNow.reveal || root.shapeNow.h >= 1 ? root.sheetDepth : root.curHeight
                    color: background.solid
                    opacity: root.shapeNow.body
                    radius: root.radius
                    topLeftRadius: root.strip || root.flushLeft ? 0 : root.radius * root.topRound
                    topRightRadius: root.strip || root.flushRight ? 0 : root.radius * root.topRound
                    transform: Scale {
                        origin.x: root.curWidth / 2
                        xScale: root.shapeNow.bodyScale
                        yScale: root.shapeNow.bodyScale
                    }
                }
            }

            Rectangle {
                readonly property real r: root.shapeRadius
                readonly property real square: r * (1 - root.shown)
                x: root.shapeX
                y: root.shapeTop - root.overscan
                width: root.shapeWidth
                height: root.shapeHeight + root.overscan + (root.strip ? 0 : 2 * root.shown)
                color: background.solid
                topLeftRadius: Theme.barAttached ? 0 : r
                topRightRadius: Theme.barAttached ? 0 : r
                bottomLeftRadius: root.shape.flushStart ? 0 : root.strip && !root.flushLeft ? r : square
                bottomRightRadius: root.shape.flushEnd ? 0 : root.strip && !root.flushRight ? r : square
            }

            BarEars {
                along: root.shapeX
                size: root.shapeWidth
                thickness: root.shapeBottom
                ear: Theme.barEar
                flushStart: root.shape.flushStart
                flushEnd: root.shape.flushEnd
                overscan: root.overscan
                color: background.solid
            }

            Ear {
                visible: !root.flushLeft
                x: root.strip ? root.curX - size + 1 : root.shapeX - size + 1
                mirrored: false
            }
            Ear {
                visible: !root.flushRight
                x: root.strip ? root.curX + root.curWidth - 1 : root.shapeX + root.shapeWidth - 1
                mirrored: true
            }
        }
    }

    Item {
        readonly property rect box: root.place(root.curX, root.shapeBottom, root.curWidth, root.curHeight,
            root.vertical ? root.width : root.height)
        visible: root.covering
        x: box.x
        y: box.y
        width: box.width
        height: box.height
        clip: true

        Item {
            readonly property rect box: root.place(root.bodyX - root.curX, root.slide + root.shapeNow.cy,
                root.bodyWidth, root.sheetDepth, root.curHeight)
            x: box.x
            y: box.y
            width: box.width
            height: box.height
            opacity: root.shapeNow.content * root.shapeNow.body
            scale: root.shapeNow.scale
            transformOrigin: ({ bottom: Item.Bottom, left: Item.Left, right: Item.Right })[root.edge] ?? Item.Top

            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: inner
                anchors.fill: parent
            }
        }
    }

    BarLayout {
        id: bar
        x: root.edge === "right" ? root.width - width : 0
        y: root.edge === "bottom" ? root.height - height : 0
        width: root.vertical ? Theme.barHeight : root.width
        height: root.vertical ? root.height : Theme.barHeight
        opacity: root.covering ? 1 : 0
        bareShape: root.covering ? root.anchor.index : -1
        settingsActive: root.kind === "settings"
        onAction: name => {
            if (root.kind === "settings" && name === "cc:"
                    || root.kind === "calendar" && name === "calendar"
                    || root.kind === "weather" && name === "weather")
                root.dismiss();
            else
                Toggles.barAction(name);
        }
    }

    component Ear: Shape {
        property bool mirrored
        readonly property real size: root.ear * root.shown
        y: root.strip ? root.shapeBottom - 1 : root.shapeBottom - size + 1
        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: mirrored ? -1 : 1
            yScale: root.strip ? -1 : 1
            origin.x: size / 2
            origin.y: size / 2
        }

        ShapePath {
            fillColor: background.solid
            strokeWidth: -1
            startX: size; startY: 0
            PathLine { x: size; y: size }
            PathLine { x: 0; y: size }
            PathArc { x: size; y: 0; radiusX: size; radiusY: size; direction: PathArc.Counterclockwise }
        }
    }
}
