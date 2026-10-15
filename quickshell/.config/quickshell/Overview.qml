import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Super + Tab, coming out of the bar's pill: every workspace in use (plus the current one), in one
// row, as a scaled-down copy of the screen with live window previews in place. Click a window to
// focus it, a workspace to switch, press 1–9 to jump, Esc or a click outside to close. Toggled with
// `qs ipc call overview toggle`.
PanelWindow {
    id: root

    // Closes the other panels when this one opens, and the other way round
    Exclusive { panel: root }

    property bool open: false
    // Selected card (index into workspaceIds)
    property int current: 0
    readonly property var monitor: Hyprland.focusedMonitor?.lastIpcObject ?? null
    readonly property real monitorWidth: monitor ? monitor.width / monitor.scale : 1920
    readonly property real monitorHeight: monitor ? monitor.height / monitor.scale : 1080
    readonly property int activeId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    // Workspace ids with windows, plus the active one, in order
    readonly property var workspaceIds: {
        const ids = new Set(Windows.windows.map(t => t.workspace.id));
        ids.add(activeId);
        return Array.from(ids).sort((a, b) => a - b);
    }
    // All workspaces in one row
    readonly property int columns: Math.max(1, workspaceIds.length)
    readonly property real cardWidth: Math.min(360, (width - 120 - (columns - 1) * 20) / columns)
    readonly property real cardScale: cardWidth / monitorWidth

    function toggle() {
        if (open) {
            close();
            return;
        }
        Windows.refresh();
        openTimer.delta = 0;
        openTimer.restart();
    }

    // Super + Tab: opens on the next workspace, then moves the selection while Super is held
    function step(delta) {
        if (!open) {
            Windows.refresh();
            openTimer.delta = delta;
            openTimer.restart();
            return;
        }
        current = (current + delta + workspaceIds.length) % workspaceIds.length;
    }

    // Releasing Super (or Enter) switches to the selected workspace
    function commit() {
        if (!open)
            return;
        const id = workspaceIds[current];
        close();
        if (id !== undefined && id !== activeId) {
            focusLater.workspace = id;
            focusLater.restart();
        }
    }

    // Hyprland ignores focus changes while this window holds the keyboard (exclusive while open),
    // and it stays mapped while it slides back into the pill; switch once the keyboard is released
    Timer {
        id: focusLater
        property var workspace
        interval: 50
        onTriggered: Windows.focusWorkspace(workspace)
    }

    // Slides back into the pill; the window is hidden when that ends
    function close() {
        open = false;
    }

    // Toplevel data refreshes asynchronously; open a moment later with the new list
    Timer {
        id: openTimer
        property int delta: 0
        interval: 60
        onTriggered: {
            const n = root.workspaceIds.length;
            root.current = (Math.max(0, root.workspaceIds.indexOf(root.activeId)) + delta + n) % n;
            root.visible = true;
            root.open = true;
        }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void {
            root.toggle();
        }
        function next(): void {
            root.step(1);
        }
        function prev(): void {
            root.step(-1);
        }
        function commit(): void {
            root.commit();
        }
        function cancel(): void {
            root.close();
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    // Dim backdrop; below the blur's alpha cutoff so only the sheet is blurred (rules.lua)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.close()
        Keys.onReturnPressed: root.commit()
        Keys.onEnterPressed: root.commit()
        Keys.onTabPressed: root.step(1)
        Keys.onBacktabPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onLeftPressed: root.step(-1)
        Keys.onReleased: event => {
            // Backup for the Hyprland release bind
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Meta)
                root.commit();
        }
        Keys.onPressed: event => {
            const n = Number(event.text);
            if (n >= 1 && n <= 9) {
                root.close();
                Windows.focusWorkspace(n);
                event.accepted = true;
            }
        }
    }

    // Comes out of the bar's pill, like the launcher
    Sheet {
        open: root.open
        sheetWidth: grid.implicitWidth + 48
        sheetHeight: grid.implicitHeight + 48
        onClosed: root.visible = false
        onDismiss: root.close()

        GridLayout {
            id: grid
            anchors.centerIn: parent
            columns: root.columns
            rowSpacing: 20
            columnSpacing: 20

            Repeater {
                // Kept while fading out
                model: root.visible ? root.workspaceIds : []

                ColumnLayout {
                    id: ws
                    required property int modelData
                    required property int index
                    readonly property bool active: modelData === root.activeId
                    readonly property bool selected: index === root.current
                    readonly property var windows: Windows.windows.filter(t => t.workspace.id === modelData)
                        // Floating windows on top
                        .sort((a, b) => (a.lastIpcObject.floating ?? false) - (b.lastIpcObject.floating ?? false))
                    spacing: 6

                    Label {
                        text: "Workspace " + ws.modelData + (ws.windows.length === 0 ? "  ·  empty" : "")
                        color: ws.active ? Theme.accent : Theme.subtext
                        font.bold: ws.active
                    }

                    ClippingRectangle {
                        implicitWidth: root.cardWidth
                        implicitHeight: root.monitorHeight * root.cardScale
                        radius: 14
                        color: Qt.alpha(Theme.surface, 0.6)
                        // Selected: thick accent border, slightly larger; current workspace: faint accent
                        border.width: ws.selected ? 3 : 1
                        border.color: ws.selected ? Theme.accent : ws.active ? Qt.alpha(Theme.accent, 0.5) : Qt.alpha(Theme.text, 0.1)
                        scale: ws.selected ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = ws.index
                            onClicked: {
                                root.close();
                                Windows.focusWorkspace(ws.modelData);
                            }
                        }

                        Repeater {
                            model: ws.windows

                            Item {
                                id: win
                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject

                                x: ((ipc.at?.[0] ?? 0) - (root.monitor?.x ?? 0)) * root.cardScale
                                y: ((ipc.at?.[1] ?? 0) - (root.monitor?.y ?? 0)) * root.cardScale
                                width: (ipc.size?.[0] ?? 100) * root.cardScale
                                height: (ipc.size?.[1] ?? 100) * root.cardScale

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Theme.base
                                    border.width: winMouse.containsMouse ? 2 : 0
                                    border.color: Theme.accent

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: root.visible ? win.modelData.wayland : null
                                        live: false
                                    }
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: Math.min(32, parent.width / 3)
                                    source: Windows.icon(win.modelData)
                                    opacity: 0.9
                                }

                                MouseArea {
                                    id: winMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.close();
                                        Windows.focus(win.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
