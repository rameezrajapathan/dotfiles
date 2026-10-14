import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// App launcher: a grid of installed apps with icons. Most-used apps come first; typing filters
// by name, then by description, keywords and category. Arrows move, Enter launches, Esc closes.
// Toggled with `qs ipc call launcher toggle`. Launch counts live in ~/.local/state/quickshell.
PanelWindow {
    id: root

    readonly property int columns: 6
    readonly property int cellSize: 128
    readonly property string usageFile: Quickshell.env("HOME") + "/.local/state/quickshell/launcher.json"

    property bool open: false
    property var usage: ({})

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        // Ties fall back to the name; QML's sort isn't stable
        if (q === "")
            return apps.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name));
        const scored = [];
        for (const e of apps) {
            const s = score(e, q);
            if (s >= 0)
                scored.push({ e: e, s: s });
        }
        return scored
            .sort((a, b) => a.s - b.s || (usage[b.e.id] ?? 0) - (usage[a.e.id] ?? 0) || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

    // Lower is better; -1 means no match
    function score(e, q) {
        const name = e.name.toLowerCase();
        if (name.startsWith(q))
            return 0;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 1;
        if (name.includes(q))
            return 2;
        const extra = [e.genericName, e.comment].concat(e.keywords, e.categories).join(" ").toLowerCase();
        return extra.includes(q) ? 3 : -1;
    }

    function iconFor(e) {
        if (e.icon.startsWith("/"))
            return "file://" + e.icon;
        return Quickshell.iconPath(Quickshell.hasThemeIcon(e.icon) ? e.icon : "application-x-executable");
    }

    function toggle() {
        if (open) {
            open = false;
            return;
        }
        search.text = "";
        grid.currentIndex = 0;
        grid.positionViewAtBeginning();
        visible = true;
        open = true;
    }

    function launch(e) {
        if (!e)
            return;
        const counts = Object.assign({}, usage);
        counts[e.id] = (counts[e.id] ?? 0) + 1;
        usage = counts;
        usageView.setText(JSON.stringify(counts));
        if (e.runInTerminal)
            Quickshell.execDetached(["kitty", "--"].concat(e.command));
        else
            e.execute();
        open = false;
    }

    FileView {
        id: usageView
        path: root.usageFile
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (err) {
                root.usage = {};
            }
        }
    }

    // FileView can't create the folder for the usage file
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"])

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggle();
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    // Dim backdrop; below the blur's alpha cutoff so only the card is blurred (rules.lua)
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: root.columns * root.cellSize + 40
        height: 600
        radius: 24
        color: Theme.baseTranslucent
        border.color: Qt.alpha(Theme.text, 0.08)
        border.width: 1

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity {
            NumberAnimation {
                duration: 160
                onRunningChanged: if (!running && !root.open) root.visible = false
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Search field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 52
                radius: 16
                color: Qt.alpha(Theme.surface, 0.7)
                border.width: 2
                border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.6) : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 14

                    Icon {
                        name: "search"
                        color: Theme.accent
                        size: 24
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 4
                        focus: root.open
                        onTextChanged: grid.currentIndex = 0

                        Keys.onEscapePressed: root.open = false
                        Keys.onReturnPressed: root.launch(root.results[grid.currentIndex])
                        Keys.onEnterPressed: root.launch(root.results[grid.currentIndex])
                        Keys.onUpPressed: grid.moveCurrentIndexUp()
                        Keys.onDownPressed: grid.moveCurrentIndexDown()
                        Keys.onTabPressed: grid.moveCurrentIndexRight()
                        Keys.onBacktabPressed: grid.moveCurrentIndexLeft()
                        Keys.onPressed: event => {
                            // Left/Right move the selection; they only move the cursor while selecting text
                            if (event.modifiers & Qt.ShiftModifier)
                                return;
                            if (event.key === Qt.Key_Left) {
                                grid.moveCurrentIndexLeft();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                grid.moveCurrentIndexRight();
                                event.accepted = true;
                            }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Search apps…"
                            color: Theme.overlay
                            font.pixelSize: Theme.fontSize + 4
                        }
                    }

                    Label {
                        text: root.results.length + " apps"
                        color: Theme.overlay
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / root.columns
                cellHeight: root.cellSize
                clip: true
                model: root.results
                highlightMoveDuration: 0
                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: GridView.isCurrentItem

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 18
                        color: cell.selected ? Qt.alpha(Theme.accent, 0.22)
                            : mouse.containsMouse ? Qt.alpha(Theme.surface, 0.8)
                            : "transparent"
                        border.width: cell.selected ? 1 : 0
                        border.color: Qt.alpha(Theme.accent, 0.5)
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 10

                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: 52
                            source: root.iconFor(cell.modelData)
                            asynchronous: true
                            scale: cell.selected ? 1.08 : 1
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: cell.modelData.name
                            color: cell.selected ? Theme.text : Theme.subtext
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(cell.modelData)
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    text: "No apps match “" + search.text + "”"
                    color: Theme.overlay
                }
            }

            // Selected app's description
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                readonly property var app: root.results[grid.currentIndex] ?? null
                visible: app !== null

                Label {
                    text: parent.app?.name ?? ""
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    text: parent.app?.comment || parent.app?.genericName || ""
                    color: Theme.overlay
                    elide: Text.ElideRight
                }
                Label {
                    text: "↵ open   esc close"
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}
