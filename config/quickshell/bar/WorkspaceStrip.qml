import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property string style: "numbers"
    property bool vertical: Theme.barVertical

    readonly property var opts: Settings.workspaces
    readonly property real size: Math.max(0.7, Math.min(1.3, opts.size))
    readonly property var info: WorkspaceStyles.info(style)

    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen ?? null) ?? Hyprland.focusedMonitor
    readonly property int current: monitor?.activeWorkspace?.id ?? 1

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

    readonly property var ids: {
        const shown = new Set(Object.keys(occupants).map(Number));
        shown.add(current);
        if (opts.show !== "occupied")
            for (let i = 1; i <= Math.max(1, opts.count); i++)
                shown.add(i);
        return [...shown].filter(i => i > 0).sort((a, b) => a - b);
    }

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

    Rectangle {
        id: highlight
        readonly property Item target: {
            repeater.count;
            return repeater.itemAt(root.ids.indexOf(root.current));
        }
        readonly property bool line: root.style === "underline"
        readonly property real thickness: Math.max(2, Math.round(3 * root.size))
        readonly property real grow: root.style === "dots" ? root.dot * 0.35 / 2 : 0
        z: root.style === "dots" ? 1 : 0
        visible: root.glides && target !== null
        x: grid.x + (target?.x ?? 0) - grow + (line ? (root.vertical ? 0 : ((target?.width ?? 0) - width) / 2) : 0)
        y: grid.y + (target?.y ?? 0) - grow + (line ? (root.vertical ? ((target?.height ?? 0) - height) / 2 : (target?.height ?? 0) - height) : 0)
        width: line ? (root.vertical ? thickness : (target?.width ?? 0) * 0.55) : (target?.width ?? 0) + 2 * grow
        height: line ? (root.vertical ? (target?.height ?? 0) * 0.55 : thickness) : (target?.height ?? 0) + 2 * grow
        radius: Theme.round(Math.min(width, height) / 2, width, height)
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
                readonly property color restColor: alert ? Theme.red
                    : !root.opts.markOccupied || used ? Theme.text : Qt.alpha(Theme.text, 0.4)
                readonly property string text: WorkspaceStyles.label(wsId, root.opts.labels)

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
                    : root.style === "vpills" ? Math.min(Theme.pillCircle, Math.round((active ? 22 : used || !root.opts.markOccupied ? 14 : 10) * root.size))
                    : root.cell

                width: root.vertical ? across : along
                height: root.vertical ? along : across
                Behavior on width { enabled: root.style === "pills" || root.style === "vpills"; NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
                Behavior on height { enabled: root.style === "pills" || root.style === "vpills"; NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.centerIn: parent
                    readonly property bool dotLike: root.style === "dots" || root.style === "pills" || root.style === "vpills"
                    visible: root.style !== "underline" && root.style !== "icons"
                        && (root.style !== "numbers" || ws.active && !root.glides)
                    readonly property real dotScale: ws.active && !root.glides ? 1.35 : 1
                    width: root.style === "dots" ? root.dot * dotScale : parent.width
                    height: root.style === "dots" ? root.dot * dotScale : parent.height
                    Behavior on width { NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: root.ms; easing.type: Easing.OutCubic } }
                    radius: Theme.round(root.style === "boxes" ? 7 : Math.min(width, height) / 2, width, height)
                    color: {
                        if (root.style === "boxes")
                            return ws.active ? Theme.selectedFill : ws.used || !root.opts.markOccupied ? Qt.alpha(Theme.surface, 0.9) : "transparent";
                        if (dotLike) {
                            if (ws.active && !(root.style === "dots" && root.glides))
                                return Theme.selectedFill;
                            if (ws.alert)
                                return Theme.red;
                            return !root.opts.markOccupied || ws.used ? Qt.alpha(Theme.text, 0.75) : "transparent";
                        }
                        return Theme.selectedFill;
                    }
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
                        ? (root.style === "underline" ? Theme.selectedFill : root.style === "icons" ? Theme.text : Theme.selectedText)
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
                Rectangle {
                    visible: root.style === "icons" && ws.alert
                    anchors { right: parent.right; top: parent.top }
                    width: 6
                    height: 6
                    radius: Theme.round(3, width, height)
                    color: Theme.red
                }

                MouseArea {
                    anchors.fill: parent
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

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: wheel => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${wheel.angleDelta.y < 0 ? "e+1" : "e-1"}" })`])
    }
}
