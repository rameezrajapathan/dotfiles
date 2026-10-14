import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Super + Tab: every workspace in use (plus the current one) as a scaled-down copy of the
// screen with live window previews in place. Click a window to focus it, a workspace to switch,
// press 1–9 to jump, Esc or a click outside to close. Toggled with `qs ipc call overview toggle`.
PanelWindow {
    id: root

    property bool open: false
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
    readonly property int columns: Math.min(4, Math.max(2, Math.ceil(Math.sqrt(workspaceIds.length))))
    readonly property real cardWidth: Math.min(420, (width - 120 - (columns - 1) * 20) / columns)
    readonly property real cardScale: cardWidth / monitorWidth

    function toggle() {
        if (open) {
            close();
            return;
        }
        Windows.refresh();
        openTimer.restart();
    }

    function close() {
        open = false;
        visible = false;
    }

    Timer {
        id: openTimer
        interval: 60
        onTriggered: {
            root.visible = true;
            root.open = true;
        }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void {
            root.toggle();
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-overview"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: Qt.alpha(Theme.base, 0.75)
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => {
            const n = Number(event.text);
            if (n >= 1 && n <= 9) {
                root.close();
                Windows.focusWorkspace(n);
                event.accepted = true;
            }
        }
    }

    GridLayout {
        anchors.centerIn: parent
        columns: root.columns
        rowSpacing: 20
        columnSpacing: 20

        Repeater {
            model: root.open ? root.workspaceIds : []

            ColumnLayout {
                id: ws
                required property int modelData
                readonly property bool active: modelData === root.activeId
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
                    border.width: ws.active ? 2 : 1
                    border.color: ws.active ? Theme.accent : Qt.alpha(Theme.text, 0.1)

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
                                    captureSource: root.open ? win.modelData.wayland : null
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
