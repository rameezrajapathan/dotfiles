import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.widgets

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property string edge: Dock.edge
    readonly property bool vertical: Dock.vertical
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool fullscreen: monitor?.activeWorkspace?.hasFullscreen ?? false
    readonly property int iconSize: Dock.iconSize
    readonly property int depth: Dock.depth
    readonly property int maxDepth: Math.ceil(iconSize * Dock.magnifyScale) + 2 * Dock.pad
    readonly property int room: Math.max(vertical ? 300 : 230, menu.open ? menu.needed + 24 : 0)
    readonly property real length: vertical ? height : width
    readonly property Item canvas: stage

    property bool dismissed: false
    property bool peek: false
    property bool revealed: false
    property bool touched: false

    readonly property point pointer: canvasHover.point.position
    property bool hovered: false
    readonly property real growth: (Dock.magnifyScale - 1) * iconSize * 1.5
    readonly property rect hoverZone: rect(rest.start - growth, rest.len + 2 * growth, 0, Dock.gap + maxDepth)
    function updateHover() {
        hovered = canvasHover.hovered && !stripActive && contains(hoverZone, pointer);
    }
    onPointerChanged: updateHover()
    onStripActiveChanged: updateHover()
    readonly property bool previewHovered: canvasHover.hovered && preview.visible && contains(preview.cardRect, pointer)
    readonly property bool held: Dock.holdScreen !== "" && Dock.holdScreen === (modelData?.name ?? "")
    readonly property bool engaged: hovered || previewHovered || menu.open || dragKey !== "" || held
    readonly property bool hasItems: Dock.items.length > 0
    readonly property bool menuOpen: menu.open
    readonly property bool overlapped: {
        if (Dock.mode !== "intellihide" || !monitor || !screen)
            return false;
        const special = Special.on(monitor.name);
        const sw = screen.width;
        const sh = screen.height;
        const reach = Dock.gap + depth;
        const r = edge === "bottom" ? Qt.rect((sw - rest.len) / 2, sh - reach, rest.len, reach)
            : edge === "left" ? Qt.rect(0, (sh - rest.len) / 2, reach, rest.len)
            : Qt.rect(sw - reach, (sh - rest.len) / 2, reach, rest.len);
        return Hyprland.toplevels.values.some(t => {
            const ws = t.workspace;
            if (!ws || !(ws === monitor.activeWorkspace || (special && ws.name === "special:" + special)))
                return false;
            const o = t.lastIpcObject;
            if (!o?.at || !o?.size)
                return false;
            const x = o.at[0] - monitor.x;
            const y = o.at[1] - monitor.y;
            return x < r.x + r.width && x + o.size[0] > r.x && y < r.y + r.height && y + o.size[1] > r.y;
        });
    }
    readonly property bool shown: hasItems && !fullscreen && (held || !dismissed
        && (Dock.mode === "always" || peek || revealed || engaged || (Dock.mode === "intellihide" && !overlapped)))
    readonly property bool stripActive: hasItems && !shown && !fullscreen && Dock.mode !== "always"

    property real progress: shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic } }
    readonly property real slide: (1 - progress) * (Dock.gap + maxDepth + 16)
    readonly property bool moving: progress > 0 && progress < 1 || magAmount > 0 && magAmount < 1 || dragKey !== ""

    visible: Dock.enabled && Dock.onScreen(modelData?.name ?? "")
    anchors {
        bottom: edge === "bottom" || vertical
        top: vertical
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitHeight: vertical ? 0 : Dock.gap + maxDepth + room
    implicitWidth: vertical ? Dock.gap + maxDepth + room : 0
    exclusionMode: Dock.mode === "always" ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: Dock.mode === "always" && shown ? Dock.gap + depth : 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-dock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    mask: Region {
        item: hit
        Region { item: preview.hit }
        Region { item: menu.hit }
    }

    function contains(r, p) {
        return p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height;
    }

    function rect(along, size, fromEdge, thickness) {
        if (edge === "bottom")
            return Qt.rect(along, height - fromEdge - thickness, size, thickness);
        if (edge === "left")
            return Qt.rect(fromEdge, along, thickness, size);
        return Qt.rect(width - fromEdge - thickness, along, thickness, size);
    }

    function alongOf(p) {
        return vertical ? p.y : p.x;
    }

    function fromEdgeOf(p) {
        return edge === "bottom" ? height - p.y : edge === "left" ? p.x : width - p.x;
    }

    function sizeOf(item) {
        return item.kind === "divider" ? Math.max(2, Dock.spacing) : iconSize;
    }

    readonly property var rest: {
        const items = Dock.items;
        const centers = {};
        let a = 0;
        for (const it of items) {
            const s = sizeOf(it);
            centers[it.key] = a + s / 2;
            a += s + Dock.spacing;
        }
        const len = items.length ? 2 * Dock.pad + a - Dock.spacing : 0;
        const start = (length - len) / 2;
        for (const k in centers)
            centers[k] += start + Dock.pad;
        return { centers: centers, len: len, start: start };
    }

    property real magAmount: hovered && Dock.magnifyScale > 1 && dragKey === "" && !menu.open ? 1 : 0
    Behavior on magAmount { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
    readonly property bool magnifying: magAmount > 0

    property string dragKey: ""
    property real dragAlong: 0
    property real dragOut: 0
    readonly property bool dragRemoving: dragKey !== "" && Dock.isPinned(dragKey) && dragOut > Dock.gap + maxDepth + 40
    readonly property var visiblePins: Dock.pinned.filter(k => k !== dragKey && rest.centers[k] !== undefined)
    readonly property int dropIndex: dragKey === "" ? -1 : visiblePins.filter(k => rest.centers[k] < dragAlong).length
    readonly property bool dropInPins: {
        if (dragKey === "")
            return false;
        if (Dock.isPinned(dragKey) || !visiblePins.length)
            return true;
        return dragAlong < rest.centers[visiblePins[visiblePins.length - 1]] + iconSize;
    }

    readonly property var order: {
        const items = Dock.items;
        if (dragKey === "" || !Dock.isPinned(dragKey) || dragRemoving)
            return items;
        const dragged = items.find(i => i.key === dragKey);
        if (!dragged)
            return items;
        const others = items.filter(i => i.key !== dragKey);
        const first = others.findIndex(i => i.pinned);
        const base = first >= 0 ? first : others.filter(i => i.kind === "launcher").length;
        others.splice(base + dropIndex, 0, dragged);
        return others;
    }

    readonly property var layout: {
        const S = Dock.magnifyScale;
        const m = alongOf(pointer);
        const range = iconSize * 3;
        const pos = {};
        let a = 0;
        for (const it of order) {
            let sc = 1;
            if (it.kind !== "divider" && magAmount > 0 && S > 1) {
                const d = Math.abs(m - (rest.centers[it.key] ?? -1e6));
                sc = 1 + (S - 1) * magAmount * Math.max(0, Math.cos(Math.min(1, d / range) * Math.PI / 2));
            }
            const s = sizeOf(it) * sc;
            pos[it.key] = { along: a, size: s, scale: sc };
            a += s + Dock.spacing;
        }
        const len = order.length ? 2 * Dock.pad + a - Dock.spacing : 0;
        const start = (length - len) / 2;
        for (const k in pos)
            pos[k].along += start + Dock.pad;
        return { pos: pos, len: len, start: start };
    }

    readonly property rect zoneRect: shown
        ? rect(layout.start, layout.len, 0, Dock.gap + (hovered ? maxDepth : depth))
        : stripActive ? rect(rest.start, rest.len, 0, 2) : Qt.rect(0, 0, 0, 0)

    property string hoverKey: ""
    property string previewKey: ""

    function itemHover(key, on) {
        if (on)
            hoverKey = key;
        else if (hoverKey === key)
            hoverKey = "";
    }

    onHoverKeyChanged: {
        if (hoverKey && dragKey === "" && !menu.open) {
            if (previewKey)
                previewKey = hoverKey;
            else
                previewTimer.restart();
        } else {
            previewTimer.stop();
            closeTimer.restart();
        }
    }
    onPreviewHoveredChanged: if (!previewHovered) closeTimer.restart()

    Timer {
        id: previewTimer
        interval: Math.max(0, Dock.cfg.previewDelay)
        onTriggered: if (root.hoverKey && root.dragKey === "" && !menu.open) root.previewKey = root.hoverKey
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: if (!root.hoverKey && !root.previewHovered) root.previewKey = ""
    }

    function closePreview() {
        previewTimer.stop();
        previewKey = "";
    }

    function openMenu(key) {
        closePreview();
        Keybinds.refresh();
        menu.key = key;
        menu.open = true;
    }

    function activate(key) {
        closePreview();
        Dock.activate(key);
    }

    function beginDrag(key) {
        closePreview();
        dragKey = key;
    }

    function moveDrag(p) {
        dragAlong = alongOf(p);
        dragOut = fromEdgeOf(p);
    }

    property string removingKey: ""

    function endDrag() {
        const key = dragKey;
        if (dragRemoving) {
            removingKey = key;
            removeTimer.restart();
        } else if (dragOut < Dock.gap + maxDepth + 24 && dropInPins && Dock.canPin(key)) {
            const without = Dock.pinned.filter(k => k !== key);
            const before = visiblePins[dropIndex];
            Dock.pin(key, before === undefined ? without.length : without.indexOf(before));
        }
        dragKey = "";
    }

    Timer {
        id: removeTimer
        interval: Theme.ms(180)
        onTriggered: {
            Dock.unpin(root.removingKey);
            root.removingKey = "";
        }
    }

    onEngagedChanged: {
        if (engaged) {
            leaveTimer.stop();
            if (peek)
                touched = true;
        } else {
            leaveTimer.restart();
        }
    }

    Timer {
        id: leaveTimer
        interval: 400
        onTriggered: {
            if (root.engaged)
                return;
            root.revealed = false;
            if (root.touched)
                root.peek = false;
        }
    }

    readonly property bool inStrip: stripActive && canvasHover.hovered && contains(zoneRect, pointer)
    onInStripChanged: inStrip ? dwellTimer.restart() : dwellTimer.stop()

    Timer {
        id: dwellTimer
        interval: 150
        onTriggered: {
            root.dismissed = false;
            root.revealed = true;
        }
    }

    Connections {
        target: Dock
        function onVisibilityRequested(how) {
            if (how === "hide" || how === "toggle" && root.shown) {
                root.dismissed = true;
                root.peek = false;
                root.revealed = false;
                root.closePreview();
                menu.open = false;
            } else {
                root.dismissed = false;
                if (!root.shown) {
                    root.touched = false;
                    root.peek = true;
                }
            }
        }
    }

    readonly property var place: {
        const sw = screen?.width ?? 0;
        const sh = screen?.height ?? 0;
        const shift = Dock.mode === "always" && Theme.barPosition === (vertical ? "top" : "left") ? Theme.barHeight : 0;
        const start = shift + rest.start;
        const r = edge === "bottom" ? { x: start, y: sh - Dock.gap - depth, width: rest.len, height: depth }
            : edge === "left" ? { x: Dock.gap, y: start, width: depth, height: rest.len }
            : { x: sw - Dock.gap - depth, y: start, width: depth, height: rest.len };
        return Object.assign(r, { edge: edge, shown: shown && progress === 1, available: visible && hasItems && !fullscreen });
    }
    onPlaceChanged: Qt.callLater(() => Dock.setPlace(modelData?.name ?? "", place))

    ListModel {
        id: itemModel
    }

    function sync() {
        const keys = Dock.items.map(i => i.key);
        for (let i = itemModel.count - 1; i >= 0; i--)
            if (!keys.includes(itemModel.get(i).key))
                itemModel.remove(i);
        const have = [];
        for (let i = 0; i < itemModel.count; i++)
            have.push(itemModel.get(i).key);
        for (const k of keys)
            if (!have.includes(k))
                itemModel.append({ key: k });
        if (previewKey && !keys.includes(previewKey))
            closePreview();
    }

    Connections {
        target: Dock
        function onItemsChanged() {
            root.sync();
        }
    }
    Component.onCompleted: sync()

    Item {
        id: hit
        x: root.zoneRect.x
        y: root.zoneRect.y
        width: root.zoneRect.width
        height: root.zoneRect.height
    }

    Item {
        id: stage
        anchors.fill: parent

        HoverHandler {
            id: canvasHover
            onHoveredChanged: root.updateHover()
        }

        Rectangle {
            id: body
            readonly property rect r: root.rect(root.layout.start, root.layout.len, Dock.gap - root.slide, root.depth)
            x: r.x
            y: r.y
            width: r.width
            height: r.height
            visible: root.hasItems && root.progress > 0
            opacity: Math.min(1, root.progress * 1.5)
            radius: Theme.round(Math.min(22, root.depth * 0.34), width, height)
            color: "transparent"

            GlassPanel {
                radius: body.radius
                tint: Qt.alpha(Theme.base, Dock.glass.tint)
                rim: Glass.flat ? 1 / 0.35 : Dock.glass.rim
                refraction: Dock.glass.refraction
                shadow: true
                tracking: root.moving
            }
        }

        Repeater {
            model: itemModel

            DockItem {
                dock: root
            }
        }

        DockPreview {
            id: preview
            dock: root
            key: root.previewKey
        }

        DockMenu {
            id: menu
            dock: root
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: menu.open
        onCleared: menu.open = false
    }
}
