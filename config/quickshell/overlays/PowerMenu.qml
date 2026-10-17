import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.lock
import qs.services
import qs.widgets

PanelWindow {
    id: root

    Exclusive { panel: root }

    readonly property var actions: [
        { key: "L", label: "Lock", icon: "lock", command: ["loginctl", "lock-session"] },
        { key: "E", label: "Log out", icon: "logout", command: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { key: "S", label: "Suspend", icon: "bedtime", command: ["systemctl", "suspend"] },
        { key: "R", label: "Restart", icon: "restart_alt", command: ["systemctl", "reboot"] },
        { key: "P", label: "Shut down", icon: "power_settings_new", command: ["systemctl", "poweroff"], danger: true }
    ]

    property bool open: false
    property int current: 0
    property string uptime: ""

    function toggle() {
        if (open) {
            open = false;
            return;
        }
        current = 0;
        uptimeView.reload();
        visible = true;
        open = true;
    }

    function run(action) {
        open = false;
        Quickshell.execDetached(action.command);
    }

    FileView {
        id: uptimeView
        path: "/proc/uptime"
        onLoaded: {
            const mins = Math.floor(parseFloat(text().split(" ")[0]) / 60);
            const d = Math.floor(mins / 1440), h = Math.floor(mins / 60) % 24, m = mins % 60;
            root.uptime = "up " + (d > 0 ? d + " d " : "") + (d > 0 || h > 0 ? h + " h " : "") + m + " min";
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            root.toggle();
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-power"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(180) } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Sheet {
        open: root.open
        anchorIds: ["power"]
        sheetWidth: tiles.implicitWidth + 2 * Theme.pad(28, 24)
        sheetHeight: content.implicitHeight + 2 * Theme.pad(26, 24)
        onClosed: root.visible = false
        onDismiss: root.open = false

        Item {
            anchors.fill: parent
            focus: root.open

            Keys.onEscapePressed: root.open = false
            Keys.onLeftPressed: root.current = (root.current + root.actions.length - 1) % root.actions.length
            Keys.onRightPressed: root.current = (root.current + 1) % root.actions.length
            Keys.onTabPressed: root.current = (root.current + 1) % root.actions.length
            Keys.onReturnPressed: root.run(root.actions[root.current])
            Keys.onEnterPressed: root.run(root.actions[root.current])
            Keys.onPressed: event => {
                const action = root.actions.find(a => a.key === event.text.toUpperCase());
                if (action) {
                    root.run(action);
                    event.accepted = true;
                }
            }
        }

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 22

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "See you soon, " + Quickshell.env("USER")
                    font.pixelSize: 22
                    font.bold: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.uptime
                    color: Theme.subtext
                }
            }

            RowLayout {
                id: tiles
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                Repeater {
                    model: root.actions

                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.current === index
                    readonly property color tint: modelData.danger ? Theme.red : Theme.accent
                    readonly property color fill: modelData.danger ? Theme.red : Theme.selectedFill
                    readonly property color fillText: modelData.danger ? Theme.accentText : Theme.selectedText

                    implicitWidth: 120
                    implicitHeight: 132
                    radius: Theme.round(22, width, height)
                    color: selected ? fill : Theme.glassFill(1)
                    border.width: Glass.active ? 0 : 1
                    border.color: selected ? fill : Qt.alpha(Theme.text, 0.08)
                    GlassRim {
                        strength: tile.selected ? 0.5 : 1
                    }
                    scale: selected ? 1.06 : 1
                    Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
                    Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 14

                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            name: tile.modelData.icon
                            filled: tile.selected
                            color: tile.selected ? tile.fillText : tile.tint
                            size: 40
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: tile.modelData.label
                            color: tile.selected ? tile.fillText : Theme.text
                            font.pixelSize: Theme.fontSize + 1
                            font.bold: tile.selected
                        }
                    }

                    Rectangle {
                        anchors { top: parent.top; right: parent.right; margins: Theme.pad(10, 22, parent.width, parent.height) }
                        width: 24
                        height: 24
                        radius: Theme.round(8, width, height)
                        color: tile.selected ? Qt.alpha(Theme.accentText, 0.15) : Qt.alpha(Theme.surface, 0.8)

                        Label {
                            anchors.centerIn: parent
                            text: tile.modelData.key
                            color: tile.selected ? tile.fillText : Theme.subtext
                            font.pixelSize: Theme.fontSize - 2
                            font.bold: true
                        }
                        GlassRim {}
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = tile.index
                        onClicked: root.run(tile.modelData)
                    }
                }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "←→ choose   ↵ confirm   esc cancel"
                color: Theme.overlay
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}
