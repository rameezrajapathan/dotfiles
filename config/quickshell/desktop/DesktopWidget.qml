import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    required property var entry
    required property string screenName
    required property var area
    property bool live: true
    property bool editable: false
    property bool preview: false

    readonly property var cells: Desktop.dims(entry)
    readonly property var spot: Desktop.clamp(entry, area)
    readonly property int shownW: resizing ? targetW : cells.w
    readonly property int shownH: resizing ? targetH : cells.h
    readonly property string sizeClass: Desktop.classOf(shownW, shownH)
    readonly property real homeX: area.x + spot.col * Desktop.cell + Desktop.gutter
    readonly property real homeY: area.y + spot.row * Desktop.cell + Desktop.gutter
    readonly property real radius: Theme.round(26, width, height)
    readonly property var glass: {
        const p = Settings.desktop.glass;
        if (!Glass.active || p === "system" || !Dock.glassOptions.includes(p))
            return { tint: Glass.tint, rim: Glass.rim, refraction: Glass.refraction };
        if (p === "solid")
            return { tint: Glass.forMode(0.92), rim: Glass.rim * 0.5, refraction: 0 };
        const v = Glass.presets[p] ?? {};
        return { tint: Glass.forMode(v.tint ?? Glass.tint), rim: v.rim ?? Glass.rim, refraction: v.refraction ?? Glass.refraction };
    }

    property bool dragging: false
    property point grab: Qt.point(0, 0)
    readonly property int targetCol: dragging ? Math.round((x - Desktop.gutter - area.x) / Desktop.cell) : spot.col
    readonly property int targetRow: dragging ? Math.round((y - Desktop.gutter - area.y) / Desktop.cell) : spot.row

    property bool resizing: false
    property real stretchW: 0
    property real stretchH: 0
    readonly property var minCells: Desktop.minOf(entry.kind)
    readonly property int targetW: Math.max(minCells.w, Math.min(Desktop.maxSpan, Math.round((stretchW + 2 * Desktop.gutter) / Desktop.cell)))
    readonly property int targetH: Math.max(minCells.h, Math.min(Desktop.maxSpan, Math.round((stretchH + 2 * Desktop.gutter) / Desktop.cell)))
    readonly property int ghostW: resizing ? targetW : cells.w
    readonly property int ghostH: resizing ? targetH : cells.h
    readonly property bool targetFree: (dragging || resizing) && Desktop.fits(Desktop.layout(screenName), entry.id, targetCol, targetRow, ghostW, ghostH, area)

    x: homeX
    y: homeY
    width: resizing ? stretchW : Desktop.pixels(cells.w, cells.h).w
    height: resizing ? stretchH : Desktop.pixels(cells.w, cells.h).h
    z: dragging || resizing ? 10 : 0
    Behavior on x { enabled: !root.dragging; NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
    Behavior on y { enabled: !root.dragging; NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
    Behavior on width { enabled: !root.resizing; NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
    Behavior on height { enabled: !root.resizing; NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }

    scale: dragging ? 1.04 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(140) } }

    property real wobble: 0
    rotation: root.editable && !root.dragging && !root.resizing ? wobble : 0
    SequentialAnimation on wobble {
        running: root.editable && !root.dragging && !root.resizing && !Theme.reduceMotion
        loops: Animation.Infinite
        NumberAnimation { to: 0.5; duration: 130 + (root.entry.id.charCodeAt(0) % 5) * 12 }
        NumberAnimation { to: -0.5; duration: 260 }
        NumberAnimation { to: 0; duration: 130 }
    }

    GlassSurface {
        anchors.fill: parent
        tracking: root.dragging || root.resizing
        tint: Qt.alpha(Theme.base, root.glass.tint)
        rim: Glass.flat ? 1 / 0.35 : root.glass.rim
        refraction: root.glass.refraction
        band: Math.min(16, Math.min(width, height) / 4)

        Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
            color: parent.solid
        }
    }

    readonly property string contentUrl: Desktop.kind(entry.kind)?.content ? Qt.resolvedUrl(Desktop.kind(entry.kind).content) : ""

    function loadContent() {
        body.setSource(contentUrl, { sizeClass: sizeClass, live: live });
    }

    onContentUrlChanged: loadContent()
    Component.onCompleted: loadContent()

    readonly property bool editsInPlace: Desktop.kind(entry.kind)?.editsInPlace === true

    Loader {
        id: body
        anchors.fill: parent
        enabled: !root.editable || root.editsInPlace
        z: root.editable && root.editsInPlace ? 1 : 0
        clip: true
        onLoaded: {
            item.sizeClass = Qt.binding(() => root.sizeClass);
            item.live = Qt.binding(() => root.live);
            if ("widgetId" in item)
                item.widgetId = Qt.binding(() => root.preview ? "" : root.entry.id);
            if ("editing" in item)
                item.editing = Qt.binding(() => root.editable && !root.preview);
            if ("screenName" in item)
                item.screenName = Qt.binding(() => root.screenName);
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.editable
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
        onPressed: event => {
            root.grab = Qt.point(event.x, event.y);
            root.dragging = true;
        }
        onPositionChanged: event => {
            if (!root.dragging)
                return;
            const p = mapToItem(root.parent, event.x, event.y);
            root.x = p.x - root.grab.x;
            root.y = p.y - root.grab.y;
        }
        onReleased: {
            const col = root.targetCol, row = root.targetRow, ok = root.targetFree;
            root.dragging = false;
            if (!ok || !Desktop.move(root.screenName, root.entry.id, col, row))
                root.home();
        }
        onCanceled: {
            root.dragging = false;
            root.home();
        }
    }

    function home() {
        x = Qt.binding(() => homeX);
        y = Qt.binding(() => homeY);
    }

    onHomeXChanged: if (!dragging) x = Qt.binding(() => homeX)
    onHomeYChanged: if (!dragging) y = Qt.binding(() => homeY)

    IconButton {
        x: -10
        y: -10
        z: 2
        width: 30
        height: 30
        visible: root.editable && !root.dragging && !root.resizing
        tone: "solid"
        icon: "remove"
        iconSize: 18
        tip: "Remove"
        onClicked: Desktop.remove(root.screenName, root.entry.id)
    }

    Item {
        id: grip
        z: 2
        visible: root.editable && !root.dragging
        x: root.width - width + 10
        y: root.height - height + 10
        width: 30
        height: 30
        IconButton {
            anchors.fill: parent
            rotation: 90
            tone: "solid"
            active: gripMouse.containsMouse || root.resizing
            icon: "open_in_full"
            iconSize: 16
        }
        MouseArea {
            id: gripMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.SizeFDiagCursor
            property point start
            property size from
            onPressed: event => {
                start = mapToItem(root.parent, event.x, event.y);
                from = Qt.size(root.width, root.height);
                root.stretchW = from.width;
                root.stretchH = from.height;
                root.resizing = true;
            }
            onPositionChanged: event => {
                if (!root.resizing)
                    return;
                const p = mapToItem(root.parent, event.x, event.y);
                const minW = root.minCells.w * Desktop.cell - 2 * Desktop.gutter;
                const minH = root.minCells.h * Desktop.cell - 2 * Desktop.gutter;
                const maxPx = Desktop.maxSpan * Desktop.cell - 2 * Desktop.gutter;
                root.stretchW = Math.max(minW, Math.min(maxPx, from.width + p.x - start.x));
                root.stretchH = Math.max(minH, Math.min(maxPx, from.height + p.y - start.y));
            }
            onReleased: {
                const w = root.targetW, h = root.targetH, ok = root.targetFree;
                if (ok)
                    Desktop.resize(root.screenName, root.entry.id, w, h);
                root.resizing = false;
            }
            onCanceled: root.resizing = false
        }
        Tooltip {
            text: "Drag to resize"
        }
    }

    Rectangle {
        visible: root.resizing
        anchors.centerIn: parent
        width: sizeLabel.implicitWidth + 24
        height: 32
        radius: 16
        color: Qt.alpha(Theme.base, 0.85)
        Label {
            id: sizeLabel
            anchors.centerIn: parent
            text: root.targetW + " × " + root.targetH
            font.weight: Font.Bold
        }
    }
}
