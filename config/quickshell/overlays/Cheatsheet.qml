import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    Exclusive { panel: root }

    readonly property int columns: 3

    readonly property var cards: {
        const q = search.text.toLowerCase();
        const shown = q === "" ? Keybinds.binds
            : Keybinds.binds.filter(b => b.desc.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q));
        return Keybinds.groups
            .map(g => ({ title: g.title, icon: g.icon, rows: shown.filter(b => b.group === g.title) }))
            .filter(c => c.rows.length > 0);
    }

    function toggle() {
        if (open) {
            open = false;
            return;
        }
        search.text = "";
        Keybinds.refresh();
        visible = true;
        open = true;
    }

    property bool open: false

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void {
            root.toggle();
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-cheatsheet"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.base, 0.82)
        opacity: root.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.ms(160)
                onRunningChanged: if (!running && !root.open) root.visible = false
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        ColumnLayout {
            id: layout
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1500)
            height: Math.min(parent.height - 80, implicitHeight)
            spacing: 18
            scale: root.open ? 1 : 0.96
            Behavior on scale { NumberAnimation { duration: Theme.ms(180); easing.type: Easing.OutCubic } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Icon {
                    name: "keyboard"
                    filled: true
                    color: Theme.accent
                    size: 30
                }
                Label {
                    text: "Keyboard shortcuts"
                    font.pixelSize: 24
                    font.bold: true
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 360
                    implicitHeight: 42
                    radius: Theme.round(21, width, height)
                    color: Theme.baseTranslucent
                    border.width: 1
                    border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Qt.alpha(Theme.text, 0.1)

                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.pad(14, 21, parent.width, parent.height)
                        anchors.rightMargin: Theme.pad(14, 21, parent.width, parent.height)
                        spacing: 10

                        Icon {
                            name: "search"
                            color: Theme.subtext
                        }
                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            focus: root.open
                            Keys.onEscapePressed: root.open = false

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: "Search shortcuts…"
                                color: Theme.overlay
                                font.pixelSize: Theme.fontSize + 1
                            }
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: columnsRow.implicitHeight
                contentHeight: columnsRow.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Row {
                    id: columnsRow
                    width: parent.width
                    spacing: 16

                    readonly property real columnWidth: (width - spacing * (root.columns - 1)) / root.columns
                    readonly property var packed: {
                        const cols = Array.from({ length: root.columns }, () => ({ cards: [], rows: 0 }));
                        for (const card of root.cards) {
                            const col = cols.reduce((a, b) => b.rows < a.rows ? b : a);
                            col.cards.push(card);
                            col.rows += card.rows.length + 2;
                        }
                        return cols.map(c => c.cards);
                    }

                    Repeater {
                        model: root.columns

                        Column {
                            required property int index
                            width: columnsRow.columnWidth
                            spacing: 16

                            Repeater {
                                model: columnsRow.packed[index]

                                CheatsheetCard {}
                            }
                        }
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: root.cards.length === 0
                text: "No shortcuts match “" + search.text + "”"
                color: Theme.subtext
            }
        }
    }
}
