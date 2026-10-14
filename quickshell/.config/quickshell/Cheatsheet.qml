import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Keybinding cheatsheet, read live from `hyprctl binds -j` and grouped into cards by what the
// binds do. Toggled with `qs ipc call cheatsheet toggle` (Super + ?). Type to filter, Esc or a
// click outside closes it.
PanelWindow {
    id: root

    readonly property int columns: 3

    // Card order; each bind goes in the first group whose pattern matches its description
    readonly property var groups: [
        { title: "Apps & system", icon: "apps", pattern: /^Open|launcher|clipboard|Lock|power|wallpaper|keybind|notification/i },
        { title: "Screenshots & recording", icon: "screenshot_region", pattern: /screenshot|record|capture/i },
        { title: "Media & hardware", icon: "graphic_eq", pattern: /volume|mute|media|track|brightness/i },
        { title: "Workspaces & monitors", icon: "space_dashboard", pattern: /workspace|monitor/i },
        { title: "Windows", icon: "select_window", pattern: /./ }
    ]

    property var binds: []
    readonly property var cards: {
        const q = search.text.toLowerCase();
        const shown = q === "" ? binds
            : binds.filter(b => b.desc.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q));
        return groups
            .map(g => ({ title: g.title, icon: g.icon, rows: shown.filter(b => b.group === g.title) }))
            .filter(c => c.rows.length > 0);
    }

    function toggle() {
        if (open) {
            open = false;
            return;
        }
        search.text = "";
        reader.running = true;
        visible = true;
        open = true;
    }

    property bool open: false

    function keyName(key) {
        const names = {
            Return: "Enter", Escape: "Esc", left: "←", right: "→", up: "↑", down: "↓",
            Page_Up: "PgUp", Page_Down: "PgDn", bracketleft: "[", bracketright: "]",
            minus: "−", equal: "=", slash: "/", question: "?", Print: "PrtSc",
            "mouse:272": "Left drag", "mouse:273": "Right drag", mouse_up: "Scroll ↑", mouse_down: "Scroll ↓",
            XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute",
            XF86AudioMicMute: "Mic mute", XF86AudioPlay: "Play", XF86AudioPause: "Pause",
            XF86AudioNext: "Next", XF86AudioPrev: "Prev",
            XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −",
            XF86KbdBrightnessUp: "Kbd light +", XF86KbdBrightnessDown: "Kbd light −"
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
            if (/^[1-9]$/.test(b.key) && desc.endsWith(" " + b.key)) {
                key = "1 – 9";
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
        binds = rows.map(r => ({
            desc: r.desc,
            keys: r.mods.concat([r.alts.join(" / ")]),
            group: groups.find(g => g.pattern.test(r.desc)).title
        }));
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
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.base, 0.82)
        opacity: root.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 160
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
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            // Header: title and search
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
                    radius: 21
                    color: Theme.baseTranslucent
                    border.width: 1
                    border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.6) : Qt.alpha(Theme.text, 0.1)

                    MouseArea {
                        anchors.fill: parent
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
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

            // Cards, packed into the shortest column
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
                    // Greedy packing: each card goes to the column with the fewest rows so far
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
