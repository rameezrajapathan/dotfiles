import Quickshell
import QtQuick
import QtQuick.Shapes

// A panel that comes out of the bar: while it opens, a copy of the bar (BarLayout, same place as
// the real one, which hides meanwhile) takes the sheet's color where the sheet joins it, concave
// curves grow at the join and the sheet slides down out from under it. The bar's items keep
// working. With a pill or islands the sheet comes out of the pill holding the item it belongs to
// (anchorIds), whose bottom corners square off; with a full-width bar it hangs from the bar's
// bottom edge under that item. Where the pill is too close to the screen's side for a curve, the
// sheet's edge lines up with the pill's instead.
// Fill a full-screen overlay with it, put the content inside and set sheetWidth/sheetHeight (the
// sheet below the bar). `closed()` fires once the close animation has finished (hide the window
// then); `dismiss()` asks the owner to close.
Item {
    id: root
    property bool open: false
    property real sheetWidth: 600
    property real sheetHeight: 400
    property real radius: 24
    property real ear: 14
    property color color: Theme.baseTranslucent
    // "settings", "calendar" or "weather" for those panels: clicking their own bar item just closes them
    property string kind: ""
    // Bar items (BarModule ids) this sheet belongs to, in order of preference
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

    // How it opens and closes (PanelMotion.qml; Settings > Effects)
    property string motion: PanelMotion.style
    // 0 closed .. 1 open (Spring passes 1 a little)
    property real progress: 0
    readonly property real shown: PanelMotion.clamp(progress)
    readonly property var shapeNow: PanelMotion.shape(motion, progress)

    // Started by hand so the curve for this direction is set before it runs
    NumberAnimation {
        id: motionAnim
        target: root
        property: "progress"
        onRunningChanged: if (!running && !root.open) root.closed()
    }

    // Where the sheet joins the bar; picked when it opens
    property var anchor: ({ index: bar.strip ? 0 : 1, cx: width / 2 })
    onOpenChanged: {
        if (open)
            anchor = bar.anchorFor(anchorIds);
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
    readonly property real shapeX: shape.x
    readonly property real shapeWidth: shape.width
    readonly property real shapeTop: Theme.barGap
    readonly property real shapeHeight: Theme.pillHeight
    readonly property real shapeBottom: shapeTop + shapeHeight
    readonly property real shapeRadius: Theme.pillRadius
    // Room for a curve and the sheet's own corner beside the pill
    readonly property real reach: ear + radius + 4

    readonly property bool pillFlushLeft: shapeX < reach
    readonly property bool pillFlushRight: width - shapeX - shapeWidth < reach
    readonly property real bodyWidth: strip ? Math.min(sheetWidth, shapeWidth)
        : pillFlushLeft && pillFlushRight ? shapeWidth
        : Math.max(sheetWidth, shapeWidth + 2 * reach - 8)
    // A side where the sheet's edge continues the pill's (or the bar's) instead of curving out
    readonly property bool flushLeft: strip ? centeredX - ear < shapeX + shapeRadius : pillFlushLeft
    readonly property bool flushRight: strip ? centeredX + bodyWidth + ear > shapeX + shapeWidth - shapeRadius
        : pillFlushRight
    readonly property real centeredX: strip
        ? Math.max(shapeX, Math.min(shapeX + shapeWidth - bodyWidth, Math.round(anchor.cx - bodyWidth / 2)))
        : Math.max(4, Math.min(width - 4 - bodyWidth, Math.round(shapeX + (shapeWidth - bodyWidth) / 2)))
    readonly property real bodyX: flushLeft ? shapeX
        : flushRight ? shapeX + shapeWidth - bodyWidth
        : centeredX
    // The body now: Morph, Spring and Liquid grow it from the pill's width (or a short piece of a
    // full bar, under the item) to full size; Slide moves it down; Reveal uncovers it
    readonly property real startWidth: strip ? Math.min(bodyWidth, 160) : Math.min(shapeWidth, bodyWidth)
    readonly property real startX: strip
        ? Math.max(shapeX, Math.min(shapeX + shapeWidth - startWidth, anchor.cx - startWidth / 2))
        : shapeX + (shapeWidth - startWidth) / 2
    readonly property real curWidth: startWidth + (bodyWidth - startWidth) * shapeNow.w
    readonly property real curX: startX + (bodyX - startX) * shapeNow.w
    readonly property real curHeight: Math.max(0, sheetHeight * shapeNow.h)
    readonly property real slide: shapeNow.y * sheetHeight
    // Top corners round off as the body widens past the pill
    readonly property real topRound: PanelMotion.clamp((curWidth - startWidth) / (2 * reach))

    // The real bar hides while this copy covers it
    readonly property bool covering: progress > 0
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    onCoveringChanged: Panels.cover(screenName, covering)
    Component.onDestruction: if (covering) Panels.cover(screenName, false)

    anchors.fill: parent

    // Background: the pill (or bar), curves and sheet drawn opaque and overlapping, then made
    // translucent together, so there are no seams where they meet (separate translucent shapes
    // leave a faint line at the joins on fractional scales)
    Item {
        id: background
        visible: root.covering
        width: root.width
        height: root.shapeBottom + Math.max(root.sheetHeight, root.curHeight)
        opacity: root.color.a
        layer.enabled: true

        readonly property color solid: Qt.rgba(root.color.r, root.color.g, root.color.b, 1)

        // Sheet, coming out from under the pill
        Item {
            x: root.curX
            y: root.shapeBottom
            width: root.curWidth
            height: root.curHeight
            clip: true

            Rectangle {
                y: root.slide
                width: parent.width
                height: root.shapeNow.reveal || root.shapeNow.h >= 1 ? root.sheetHeight : root.curHeight
                color: background.solid
                opacity: root.shapeNow.body
                radius: root.radius
                // Square where it continues the pill's side, or hangs from a full bar
                topLeftRadius: root.strip || root.flushLeft ? 0 : root.radius * root.topRound
                topRightRadius: root.strip || root.flushRight ? 0 : root.radius * root.topRound
                transform: Scale {
                    origin.x: root.curWidth / 2
                    xScale: root.shapeNow.bodyScale
                    yScale: root.shapeNow.bodyScale
                }
            }
        }

        // The pill or bar, its bottom corners squaring off as the sheet comes out where they
        // meet it; reaches 2 px into the sheet so they overlap
        Rectangle {
            readonly property real r: root.shapeRadius
            readonly property real square: r * (1 - root.shown)
            x: root.shapeX
            y: root.shapeTop
            width: root.shapeWidth
            height: root.shapeHeight + (root.strip ? 0 : 2 * root.shown)
            color: background.solid
            topLeftRadius: r
            topRightRadius: r
            bottomLeftRadius: root.strip && !root.flushLeft ? r : square
            bottomRightRadius: root.strip && !root.flushRight ? r : square
        }

        // Pill: curves at its bottom sides; full bar: at the sheet's top sides
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

    // Content, laid out at full size where it ends up, shown through the body as it opens
    Item {
        visible: root.covering
        x: root.curX
        y: root.shapeBottom
        width: root.curWidth
        height: root.curHeight
        clip: true

        Item {
            x: root.bodyX - root.curX
            y: root.slide + root.shapeNow.cy
            width: root.bodyWidth
            height: root.sheetHeight
            opacity: root.shapeNow.content * root.shapeNow.body
            scale: root.shapeNow.scale
            transformOrigin: Item.Top

            // Clicks on the sheet stay on it
            MouseArea {
                anchors.fill: parent
            }

            Item {
                id: inner
                anchors.fill: parent
            }
        }
    }

    // The bar, drawn over the background above; laid out even while hidden so `anchorFor` can
    // find its items
    BarLayout {
        id: bar
        width: root.width
        opacity: root.covering ? 1 : 0
        bareShape: root.covering ? root.anchor.index : -1
        settingsActive: root.kind === "settings"
        // Opening another panel closes this one (Exclusive)
        onAction: name => {
            if (root.kind === "settings" && name === "cc:"
                    || root.kind === "calendar" && name === "calendar"
                    || root.kind === "weather" && name === "weather")
                root.dismiss();
            else
                Toggles.barAction(name);
        }
    }

    // Concave curve filling the corner between the pill's side and the sheet's top, or (full bar)
    // between the bar's bottom and the sheet's side
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
