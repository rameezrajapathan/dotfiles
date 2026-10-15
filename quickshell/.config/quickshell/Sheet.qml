import Quickshell
import QtQuick
import QtQuick.Shapes

// A panel that comes out of the bar's pill: while it opens, a copy of the pill (BarIsland, same
// place as the real one, which hides meanwhile) takes the sheet's color, its bottom corners
// square off, concave curves grow from its sides and the sheet slides down out from under it.
// The pill's icons keep working. Fill a full-screen overlay with it, put the content inside and
// set sheetWidth/sheetHeight (the sheet below the pill). `closed()` fires once the close
// animation has finished (hide the window then); `dismiss()` asks the owner to close.
Item {
    id: root
    property bool open: false
    property real sheetWidth: 600
    property real sheetHeight: 400
    property real radius: 24
    property real ear: 14
    property color color: Theme.baseTranslucent
    // "settings" or "calendar" for those panels: clicking their own pill item just closes them
    property string kind: ""
    default property alias content: inner.data
    signal closed()
    signal dismiss()

    // 0 closed .. 1 open
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuint
            onRunningChanged: if (!running && !root.open) root.closed()
        }
    }

    readonly property real pillHeight: island.height
    readonly property real pillTop: (Theme.barHeight - pillHeight) / 2
    readonly property real pillBottom: pillTop + pillHeight
    readonly property real pillX: Math.round((width - island.width) / 2)
    // Wide enough for the curves and its own top corners on both sides of the pill
    readonly property real bodyWidth: Math.max(sheetWidth, island.width + 2 * (ear + radius))
    readonly property real bodyX: Math.round((width - bodyWidth) / 2)
    // Sheet offset while sliding in
    readonly property real slide: (progress - 1) * sheetHeight

    // The real pill hides while this one covers it
    readonly property bool covering: progress > 0
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    onCoveringChanged: Panels.cover(screenName, covering)
    Component.onDestruction: if (covering) Panels.cover(screenName, false)

    anchors.fill: parent

    // Background: pill, curves and sheet drawn opaque and overlapping, then made translucent
    // together, so there are no seams where they meet (separate translucent shapes leave a faint
    // line at the joins on fractional scales)
    Item {
        id: background
        visible: root.covering
        x: root.bodyX
        y: root.pillTop
        width: root.bodyWidth
        height: root.pillHeight + root.sheetHeight
        opacity: root.color.a
        layer.enabled: true

        readonly property color solid: Qt.rgba(root.color.r, root.color.g, root.color.b, 1)

        // Sheet, sliding out from under the pill
        Item {
            y: root.pillHeight
            width: parent.width
            height: root.sheetHeight
            clip: true

            Rectangle {
                y: root.slide
                width: parent.width
                height: parent.height
                radius: root.radius
                color: background.solid
            }
        }

        // Pill, its bottom corners squaring off as the sheet comes out; reaches 2 px into the
        // sheet so they overlap
        Rectangle {
            x: root.pillX - root.bodyX
            width: island.width
            height: root.pillHeight + 2 * root.progress
            color: background.solid
            topLeftRadius: root.pillHeight / 2
            topRightRadius: root.pillHeight / 2
            bottomLeftRadius: root.pillHeight / 2 * (1 - root.progress)
            bottomRightRadius: root.pillHeight / 2 * (1 - root.progress)
        }

        Ear { x: root.pillX - root.bodyX - size + 1; mirrored: false }
        Ear { x: root.pillX - root.bodyX + island.width - 1; mirrored: true }
    }

    // Content, sliding with the sheet
    Item {
        visible: root.covering
        x: root.bodyX
        y: root.pillBottom
        width: root.bodyWidth
        height: root.sheetHeight
        clip: true

        Item {
            y: root.slide
            width: parent.width
            height: parent.height

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

    // The bar's pill, drawn over the background above
    BarIsland {
        id: island
        x: root.pillX
        y: root.pillTop
        color: "transparent"
        visible: root.covering
        settingsActive: root.kind === "settings"
        // Opening another panel closes this one (Exclusive)
        onClockClicked: root.kind === "calendar" ? root.dismiss() : Toggles.calendarRequested()
        onMusicClicked: Toggles.controlCenterRequested("music")
        onCaptureClicked: Toggles.controlCenterRequested("capture")
        onSettingsClicked: root.kind === "settings" ? root.dismiss() : Toggles.controlCenterRequested("")
    }

    // Concave curve joining a side of the pill to the top of the sheet
    component Ear: Shape {
        property bool mirrored
        readonly property real size: root.ear * root.progress
        y: root.pillHeight - size + 1
        width: size
        height: size
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: mirrored ? -1 : 1; origin.x: size / 2 }

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
