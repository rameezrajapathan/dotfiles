import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.lock
import qs.services
import qs.widgets

OverlayWindow {
    id: root

    layerNamespace: "quickshell-power"
    hideWhenFaded: false

    readonly property var actions: [
        { key: "L", label: "Lock", icon: "lock", command: ["loginctl", "lock-session"] },
        { key: "E", label: "Log out", icon: "logout", command: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
        { key: "S", label: "Suspend", icon: "bedtime", command: ["systemctl", "suspend"] },
        { key: "R", label: "Restart", icon: "restart_alt", command: ["systemctl", "reboot"] },
        { key: "P", label: "Shut down", icon: "power_settings_new", command: ["systemctl", "poweroff"], danger: true }
    ]

    property int current: 0
    readonly property string uptime: "up " + SysStats.uptimeText(false)

    onOpening: {
        current = 0;
        SysStats.refreshUptime();
    }

    function run(action) {
        open = false;
        Quickshell.execDetached(action.command);
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            root.toggle();
        }
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
