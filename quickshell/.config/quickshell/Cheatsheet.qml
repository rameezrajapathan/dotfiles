import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Keybinding cheatsheet, read live from `hyprctl binds -j`.
// Toggled with `qs ipc call cheatsheet toggle`. Type to filter, Esc or click outside to close.
PanelWindow {
    id: root

    readonly property int columns: 3
    readonly property int columnWidth: 560

    property var binds: []
    readonly property var filtered: {
        const q = search.text.toLowerCase();
        return q === "" ? binds
            : binds.filter(b => b.desc.toLowerCase().includes(q) || b.keys.toLowerCase().includes(q));
    }

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            search.text = "";
            reader.running = true;
            visible = true;
        }
    }

    function keyName(key) {
        const names = {
            Return: "Enter", Escape: "Esc", left: "←", right: "→", up: "↑", down: "↓",
            Page_Up: "PgUp", Page_Down: "PgDn", bracketleft: "[", bracketright: "]",
            minus: "-", equal: "=", slash: "/", question: "?",
            "mouse:272": "Left drag", "mouse:273": "Right drag", mouse_up: "Scroll ↑", mouse_down: "Scroll ↓",
            "code:20": "-", "code:21": "=", "code:61": "/"
        };
        if (key in names)
            return names[key];
        if (key.startsWith("XF86"))
            return key.slice(4).replace(/([a-z])([A-Z0-9])/g, "$1 $2");
        return key.length === 1 ? key.toUpperCase() : key;
    }

    function modNames(mask) {
        const mods = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]];
        return mods.filter(m => mask & m[0]).map(m => m[1]);
    }

    // Turns hyprctl's list into rows: binds sharing modifiers and description are merged
    // ("PgDn / U"), and the 1-9 workspace binds collapse into one row each.
    function load(json) {
        const rows = [];
        const byId = {};
        for (const b of JSON.parse(json)) {
            if (!b.has_description || b.submap !== "" || b.key === "")
                continue;
            let mask = b.modmask;
            let key = keyName(b.key);
            if (b.key === "slash" && mask & 1) {
                key = "?";
                mask &= ~1;
            }
            let desc = b.description;
            const digit = /^[1-9]$/.test(b.key) && desc.endsWith(" " + b.key);
            if (digit) {
                key = "1…9";
                desc = desc.slice(0, -1) + "1–9";
            }
            const id = mask + "|" + desc;
            const row = byId[id];
            if (!row) {
                byId[id] = { mods: modNames(mask), alts: [key], desc: desc };
                rows.push(byId[id]);
            } else if (!row.alts.includes(key)) {
                row.alts.push(key);
            }
        }
        binds = rows.map(r => ({ desc: r.desc, keys: r.mods.concat([r.alts.join(" / ")]).join(" + ") }));
    }

    Process {
        id: reader
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.load(text)
        }
    }

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
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "#99000000"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.columns * root.columnWidth + 40
        height: Math.min(parent.height - 80, layout.implicitHeight + 40)
        color: Theme.base
        radius: 12
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: "Keybindings"
                    font.bold: true
                    font.pixelSize: Theme.fontSize + 3
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 8
                    color: Theme.surface

                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        focus: root.visible
                        Keys.onEscapePressed: root.visible = false

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Type to filter…"
                            color: Theme.overlay
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: columnsRow.implicitHeight
                contentHeight: columnsRow.implicitHeight
                clip: true

                Row {
                    id: columnsRow
                    spacing: 0

                    Repeater {
                        model: root.columns

                        Column {
                            required property int index
                            readonly property int perColumn: Math.ceil(root.filtered.length / root.columns)
                            width: root.columnWidth
                            spacing: 2

                            Repeater {
                                model: root.filtered.slice(index * perColumn, (index + 1) * perColumn)

                                RowLayout {
                                    required property var modelData
                                    width: root.columnWidth - 16
                                    spacing: 12

                                    Label {
                                        Layout.preferredWidth: 230
                                        text: modelData.keys
                                        color: Theme.accent
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.desc
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Label {
                visible: root.filtered.length === 0
                text: "No matching keybindings"
                color: Theme.overlay
            }
        }
    }
}
