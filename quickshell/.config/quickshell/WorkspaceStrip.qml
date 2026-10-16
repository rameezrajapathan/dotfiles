import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// Workspace indicators that show every workspace (WorkspaceStyles.qml): numbers, boxes,
// underline, dots, pills, vertical pills or app icons, in a row (a column on a side bar). Which workspaces show,
// their labels, size and the gliding highlight come from Settings > Bar > Workspaces. Click one
// to switch to it, the current one (or right click) for the overview; scroll goes through the
// workspaces in use. A red mark means a workspace wants attention.
Item {
    id: root
    property string style: "numbers"
    property bool vertical: Theme.barVertical

    readonly property var opts: Settings.workspaces
    readonly property real size: Math.max(0.7, Math.min(1.3, opts.size))
    readonly property var info: WorkspaceStyles.info(style)

    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen ?? null) ?? Hyprland.focusedMonitor
    readonly property int current: monitor?.activeWorkspace?.id ?? 1

    // Workspace id → its windows, most recently used first
    readonly property var occupants: {
        const map = {};
        for (const t of Hyprland.toplevels.values) {
            const id = t.workspace?.id ?? -1;
            if (id > 0)
                (map[id] = map[id] ?? []).push(t);
        }
        for (const id in map)
            map[id].sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 99) - (b.lastIpcObject?.focusHistoryID ?? 99));
        return map;
    }
    readonly property var urgent: Hyprland.workspaces.values.filter(w => w.urgent).map(w => w.id)

    // The workspaces shown, in order
    readonly property var ids: {
        const shown = new Set(Object.keys(occupants).map(Number));
        shown.add(current);
        if (opts.show !== "occupied")
            for (let i = 1; i <= Math.max(1, opts.count); i++)
                shown.add(i);
        return [...shown].filter(i => i > 0).sort((a, b) => a - b);
    }

    // Sizes: label cells fill the pill's circle; dots and pills scale with the size setting
    readonly property real cell: Math.round(Theme.pillCircle * Math.min(1, 0.8 + 0.2 * size))
    readonly property real dot: Math.round(8 * size)
    readonly property real gap: style === "dots" || style === "pills" ? Math.round(6 * size)
        : style === "vpills" ? Math.round(5 * size)
        : style === "boxes" ? 4 : 2
    readonly property bool glides: info.glide === true && opts.glide
    readonly property int ms: Theme.ms(260)

    function occupied(id) {
        return (occupants[id]?.length ?? 0) > 0;
    }

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    // The gliding highlight under the current workspace (numbers, underline, dots, icons)
    Rectangle {
        id: highlight
        readonly property Item target: {
            repeater.count;
            return repeater.itemAt(root.ids.indexOf(root.current));
        }
        readonly property bool line: root.style === "underline"
        readonly property real thickness: Math.max(2, Math.round(3 * root.size))
        // Dots: the bigger current dot, over the plain ones
        readonly property real grow: root.style === "dots" ? root.dot * 0.35 / 2 : 0
        z: root.style === "dots" ? 1 : 0
        visible: root.glides && target !== null
        // A line under the label (beside it on a side bar), else the cell itself
        x: grid.x + (target?.x ?? 0) - grow + (line ? (root.vertical ? 0 : ((target?.width ?? 0) - width) / 2) : 0)
        y: grid.y + (target?.y ?? 0) - grow + (line ? (root.vertical ? ((target?.height ?? 0) - height) / 2 : (target?.height ?? 0) - height) : 0)
        width: line ? (root.vertical ? thickness : (target?.width ?? 0) * 0.55) : (target?.width ?? 0) + 2 * grow
        height: line ? (root.vertical ? (target?.height ?? 0) * 0.55 : thickness) : (target?.height ?? 0) + 2 * grow
        radius: Math.min(width, height) / 2
        color: root.style === "icons" ? Qt.alpha(Theme.accent, 0.28) : Theme.accent
        Behavior on x { NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, root.ids.length)
        spacing: root.gap
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            id: repeater
            model: root.ids

            Item {
                id: ws
                required property int modelData
                readonly property int wsId: modelData
                readonly property bool active: wsId === root.current
                readonly property bool used: root.occupied(wsId)
                readonly property bool alert: root.urgent.includes(wsId) && !active
                // Brighter with windows (unless that's turned off), dim when empty
                readonly property color restColor: alert ? Theme.red
                    : !root.opts.markOccupied || used ? Theme.text : Qt.alpha(Theme.text, 0.4)
                readonly property string text: WorkspaceStyles.label(wsId, root.opts.labels)

                // Pills: the current one stretches along the bar
                readonly property real pillLength: active ? (root.opts.pillLabel ? Math.max(Math.round(30 * root.size), label.implicitWidth + 14) : root.dot * 3.2) : root.dot
                readonly property real pillThickness: active && root.opts.pillLabel ? Math.round(18 * root.size) : root.dot
                readonly property real along: {
                    switch (root.style) {
                    case "dots": return root.dot;
                    case "pills": return pillLength;
                    case "vpills": return Math.round(5 * root.size);
                    case "underline": return Math.max(Math.round(root.cell * 0.8), label.implicitWidth + 6);
                    }
                    return Math.max(root.cell, label.implicitWidth + 12);
                }
                readonly property real across: root.style === "dots" ? root.dot
                    : root.style === "pills" ? pillThickness
                    // Vertical pills: upright, the current one tallest, empty ones shortest
                    : root.style === "vpills" ? Math.min(Theme.pillCircle, Math.round((active ? 22 : used || !root.opts.markOccupied ? 14 : 10) * root.size))
                    : root.cell

                width: root.vertical ? across : along
                height: root.vertical ? along : across
                Behavior on width { enabled: root.style === "pills" || root.style === "vpills"; NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
                Behavior on height { enabled: root.style === "pills" || root.style === "vpills"; NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }

                // The cell's own shape: a circle (numbers without the glide), a tile, a dot or a pill
                Rectangle {
                    anchors.centerIn: parent
                    readonly property bool dotLike: root.style === "dots" || root.style === "pills" || root.style === "vpills"
                    visible: root.style !== "underline" && root.style !== "icons"
                        && (root.style !== "numbers" || ws.active && !root.glides)
                    // Without the glide the current dot grows in place
                    readonly property real dotScale: ws.active && !root.glides ? 1.35 : 1
                    width: root.style === "dots" ? root.dot * dotScale : parent.width
                    height: root.style === "dots" ? root.dot * dotScale : parent.height
                    Behavior on width { NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
                    radius: root.style === "boxes" ? Math.round(7 * Settings.bar.roundness) : Math.min(width, height) / 2
                    color: {
                        if (root.style === "boxes")
                            return ws.active ? Theme.accent : ws.used || !root.opts.markOccupied ? Qt.alpha(Theme.surface, 0.9) : "transparent";
                        if (dotLike) {
                            // Gliding dots: the accent dot moves, the others stay plain
                            if (ws.active && !(root.style === "dots" && root.glides))
                                return Theme.accent;
                            if (ws.alert)
                                return Theme.red;
                            return !root.opts.markOccupied || ws.used ? Qt.alpha(Theme.text, 0.75) : "transparent";
                        }
                        return Theme.accent;
                    }
                    // Empty workspaces as rings
                    border.width: (dotLike || root.style === "boxes") && !ws.used && !ws.active && root.opts.markOccupied ? 1.5 : 0
                    border.color: ws.alert ? Theme.red : Qt.alpha(Theme.text, 0.35)
                    Behavior on color { ColorAnimation { duration: root.ms } }
                }

                Label {
                    id: label
                    anchors.centerIn: parent
                    visible: root.style === "numbers" || root.style === "boxes" || root.style === "underline"
                        || root.style === "pills" && ws.active && root.opts.pillLabel
                        || root.style === "icons" && !ws.used
                    text: ws.text
                    color: ws.active
                        ? (root.style === "underline" ? Theme.accent : root.style === "icons" ? Theme.text : Theme.accentText)
                        : ws.restColor
                    font.bold: ws.active
                    font.pixelSize: root.style === "pills" ? Math.round(11 * root.size)
                        : Math.round((Theme.fontSize - (root.style === "icons" ? 2 : 0)) * Math.min(1.1, root.size))
                    Behavior on color { ColorAnimation { duration: root.ms } }
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: root.style === "icons" && ws.used
                    implicitSize: Math.round(18 * root.size)
                    source: visible ? Windows.icon(root.occupants[ws.wsId][0]) : ""
                    asynchronous: true
                    opacity: ws.active ? 1 : 0.7
                }
                // App icons: a red dot on a workspace that wants attention
                Rectangle {
                    visible: root.style === "icons" && ws.alert
                    anchors { right: parent.right; top: parent.top }
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.red
                }

                MouseArea {
                    anchors.fill: parent
                    // Dots are small: easier to hit
                    anchors.margins: -Math.ceil(root.gap / 2)
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton || ws.active)
                            Quickshell.execDetached(["qs", "ipc", "call", "overview", "toggle"]);
                        else
                            Windows.focusWorkspace(ws.wsId);
                    }
                }
            }
        }
    }

    // Scrolling goes through the workspaces in use
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: wheel => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${wheel.angleDelta.y < 0 ? "e+1" : "e-1"}" })`])
    }
}
