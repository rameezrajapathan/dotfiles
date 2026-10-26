import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    required property var dock
    property string key: ""
    property bool open: false

    readonly property bool vertical: dock.vertical
    readonly property var group: key ? Dock.groups.map[key] ?? null : null
    readonly property var windows: group?.windows ?? []
    readonly property var entry: key && key !== "launcher" ? Dock.entry(key) : null
    readonly property string title: key === "launcher" ? "Apps" : entry?.name ?? group?.appId ?? ""
    readonly property var p: dock.layout.pos[key] ?? null
    readonly property real needed: card.implicitHeight

    readonly property var rows: {
        if (!key)
            return [];
        const out = [];
        const running = windows.length > 0;
        if (key === "launcher") {
            out.push({ icon: "apps", text: "Open the launcher", run: () => Dock.activate("launcher") });
        } else {
            if (entry)
                out.push({
                    icon: running ? "add" : "open_in_new",
                    text: running ? "New window" : "Open",
                    hint: Dock.keybindFor(key),
                    run: () => running ? Dock.newWindow(key) : Dock.launch(key)
                });
            const nw = running ? Dock.newWindowAction(entry) : null;
            for (const a of entry?.actions ?? [])
                if (a !== nw)
                    out.push({ appIcon: a.icon || entry.icon, text: a.name, run: () => Dock.runAction(key, a) });
            if (out.length)
                out.push({ sep: true });
            if (Dock.canPin(key))
                out.push(Dock.isPinned(key)
                    ? { icon: "keep_off", text: "Remove from Dock", run: () => Dock.unpin(key) }
                    : { icon: "keep", text: "Keep in Dock", run: () => Dock.pin(key) });
            if (running)
                out.push({
                    icon: "close",
                    text: windows.length > 1 ? `Close ${windows.length} windows` : "Close window",
                    danger: true,
                    run: () => Dock.closeAll(key)
                });
            out.push({ sep: true });
        }
        out.push({ icon: "tune", text: "Dock settings", run: () => Settings.openRequested("dock") });
        return out;
    }

    onPChanged: if (open && !p) open = false

    property real shownAmount: open ? 1 : 0
    Behavior on shownAmount { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
    visible: shownAmount > 0

    readonly property Item hit: hitItem

    Item {
        id: hitItem
        x: root.open ? card.x : 0
        y: root.open ? card.y : 0
        width: root.open ? card.width : 0
        height: root.open ? card.height : 0
    }

    Rectangle {
        id: card
        readonly property real fromEdge: Dock.gap + root.dock.depth + 10
        readonly property real alongSize: root.vertical ? height : width
        readonly property real centerAlong: root.p ? root.p.along + root.p.size / 2 : 0
        readonly property real alongPos: Math.max(8, Math.min(root.dock.length - alongSize - 8, centerAlong - alongSize / 2))
        readonly property rect r: root.dock.rect(alongPos, alongSize, fromEdge - (1 - root.shownAmount) * 8, root.vertical ? width : height)
        x: r.x
        y: r.y
        width: 270
        height: implicitHeight
        implicitHeight: column.implicitHeight + 16
        opacity: root.shownAmount
        radius: Theme.round(16, width, height)
        color: "transparent"

        GlassPanel {
            radius: card.radius
            tint: Theme.denseTranslucent
            shadow: true
            tracking: root.shownAmount < 1
        }

        ColumnLayout {
            id: column
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 0

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.topMargin: 4
                Layout.bottomMargin: 6
                text: root.title
                font.bold: true
                elide: Text.ElideRight
            }

            Repeater {
                model: root.rows

                Item {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: modelData.sep ? 9 : 34

                    GlassDivider {
                        visible: row.modelData.sep === true
                        vertical: false
                        anchors.centerIn: parent
                        width: parent.width - 20
                        height: 1
                    }

                    Rectangle {
                        visible: !row.modelData.sep
                        anchors.fill: parent
                        radius: Theme.round(10, width, height)
                        color: rowMouse.containsMouse ? Qt.alpha(row.modelData.danger ? Theme.red : Theme.text, 0.14) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Item {
                                implicitWidth: 20
                                implicitHeight: 20

                                Icon {
                                    visible: !row.modelData.appIcon
                                    anchors.centerIn: parent
                                    name: row.modelData.icon ?? ""
                                    size: 18
                                    color: row.modelData.danger ? Theme.red : Theme.text
                                }
                                AppIcon {
                                    visible: !!row.modelData.appIcon
                                    anchors.fill: parent
                                    implicitSize: 20
                                    icon: row.modelData.appIcon ?? ""
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: row.modelData.text ?? ""
                                color: row.modelData.danger ? Theme.red : Theme.text
                                elide: Text.ElideRight
                            }

                            Label {
                                visible: !!row.modelData.hint
                                text: row.modelData.hint ?? ""
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const run = row.modelData.run;
                                root.open = false;
                                run();
                            }
                        }
                    }
                }
            }
        }
    }
}
