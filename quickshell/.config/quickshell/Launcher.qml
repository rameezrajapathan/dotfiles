import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Launcher. Plain text searches apps (most-used first; by name, then description, keywords and
// category). A leading character switches mode:
//   =  calculator (qalc; Enter copies the result)
//   >  run a command (Enter runs it, Shift+Enter in a terminal)
//   :  emoji (Enter copies it)
//   ~  projects: zoxide's folders with a repo or project file (Enter opens the default editor,
//      Shift+Enter a terminal there)
//   +  clipboard history (cliphist; Enter copies, Ctrl+P pins or unpins, Shift+Delete removes,
//      Ctrl+Shift+Delete clears all but the pins; Super + V; hypr/scripts/clipboard.sh)
// Arrows move, Esc closes. Toggled with `qs ipc call launcher toggle`; `open <text>` starts with
// text typed (Super + P opens projects). App launch counts live in
// ~/.local/state/quickshell.
PanelWindow {
    id: root

    // Closes the other panels when this one opens, and the other way round
    Exclusive { panel: root }

    // Grid size and modes come from the Settings app (Launcher page)
    readonly property int cellSize: Settings.launcher.cellSize
    readonly property int appColumns: Settings.launcher.columns
    readonly property string usageFile: Quickshell.env("HOME") + "/.local/state/quickshell/launcher.json"
    readonly property string home: Quickshell.env("HOME")

    property bool open: false
    property var usage: ({})

    readonly property var allModes: ({
        "=": { name: "calc", hint: "Calculator", icon: "calculate" },
        ">": { name: "run", hint: "Run command", icon: "terminal" },
        ":": { name: "emoji", hint: "Emoji", icon: "mood" },
        "~": { name: "projects", hint: "Projects", icon: "folder_code" },
        "+": { name: "clipboard", hint: "Clipboard", icon: "content_paste" }
    })
    // The ones turned on in the Settings app
    readonly property var modes: {
        const on = {};
        for (const [prefix, m] of Object.entries(allModes))
            if (Settings.launcher[m.name])
                on[prefix] = m;
        return on;
    }
    readonly property var modeInfo: modes[search.text.charAt(0)] ?? null
    readonly property string mode: modeInfo?.name ?? "apps"
    readonly property string query: (modeInfo ? search.text.slice(1) : search.text).trim()
    readonly property int columns: mode === "apps" ? appColumns : mode === "emoji" ? 10 : 1

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    property string calcResult: ""
    property var emojis: []
    property var projects: []
    // cliphist entries: { id, text, image (size and type, for binary entries) }
    property var clips: []
    // Pinned clips (files that outlive the history): { file, text, image }
    property var pins: []
    readonly property string clipScript: Quickshell.env("HOME") + "/.config/hypr/scripts/clipboard.sh"
    // Bumped when thumbnails are written, so images reload
    property int thumbRevision: 0
    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-clipboard"

    // Every mode yields items: { title, subtitle, app | emoji | symbol, run(shift) }
    readonly property var results: {
        const q = query.toLowerCase();
        switch (mode) {
        case "calc":
            return q === "" ? [] : [{
                title: calcResult || "…",
                subtitle: query + "  ·  ↵ copy",
                symbol: "calculate",
                run: () => copy(calcResult)
            }];
        case "run":
            return q === "" ? [] : [{
                title: query,
                subtitle: "↵ run  ·  shift+↵ run in a terminal",
                symbol: "terminal",
                run: shift => shift
                    ? Apps.terminal(["sh", "-c", query], ["--hold"])
                    : Quickshell.execDetached(["sh", "-c", query])
            }];
        case "emoji": {
            const words = q.split(/\s+/).filter(w => w);
            return emojis
                .filter(e => words.every(w => e.name.includes(w)))
                .slice(0, 300)
                .map(e => ({ title: e.name, emoji: e.char, run: () => copy(e.char) }));
        }
        case "projects":
            return projects
                .filter(p => p.toLowerCase().includes(q))
                .sort((a, b) => basename(b).toLowerCase().startsWith(q) - basename(a).toLowerCase().startsWith(q))
                .slice(0, 50)
                .map(p => ({
                    title: basename(p),
                    subtitle: p.replace(home, "~") + "  ·  ↵ editor  ·  shift+↵ terminal",
                    symbol: "folder_code",
                    run: shift => shift
                        ? Apps.terminal([], ["--dir=" + p])
                        : Apps.editor(p)
                }));
        case "clipboard":
            return pins
                .filter(p => p.text.toLowerCase().includes(q))
                .map(p => ({
                    title: p.image ? "Image" : p.text,
                    subtitle: "Pinned  ·  ↵ copy  ·  ctrl+p unpin",
                    symbol: "push_pin",
                    thumb: p.image ? "file://" + p.file : "",
                    pin: p,
                    run: () => Quickshell.execDetached([clipScript, "copy-pin", p.file])
                }))
                .concat(clips
                .filter(c => c.text.toLowerCase().includes(q))
                .slice(0, 200)
                .map(c => ({
                    title: c.image ? "Image" : c.text,
                    subtitle: (c.image ? c.image + "  ·  " : "") + "↵ copy  ·  ctrl+p pin  ·  shift+del remove  ·  ctrl+shift+del clear",
                    symbol: c.image ? "image" : "content_paste",
                    thumb: c.image ? "file://" + thumbDir + "/" + c.id + ".png?" + thumbRevision : "",
                    clip: c,
                    run: () => Quickshell.execDetached(["sh", "-c", "cliphist list | grep -m1 \"^" + c.id + "\t\" | cliphist decode | wl-copy"])
                })));
        default:
            return appResults(q).map(e => ({ title: e.name, app: e, run: () => launch(e) }));
        }
    }

    function appResults(q) {
        // Ties fall back to the name; QML's sort isn't stable
        if (q === "")
            return Settings.launcher.mostUsedFirst
                ? apps.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name))
                : apps;
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

    function basename(path) {
        return path.slice(path.lastIndexOf("/") + 1) || path;
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
        projectReader.running = true;
        visible = true;
        open = true;
    }

    function activate(item, shift) {
        if (!item)
            return;
        item.run(shift);
        open = false;
    }

    function copy(text) {
        if (text)
            Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function launch(e) {
        const counts = Object.assign({}, usage);
        counts[e.id] = (counts[e.id] ?? 0) + 1;
        usage = counts;
        usageView.setText(JSON.stringify(counts));
        if (e.runInTerminal)
            Apps.terminal(e.command);
        else
            e.execute();
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

    // Calculator, re-run shortly after typing stops
    onQueryChanged: if (mode === "calc") calcTimer.restart()
    Timer {
        id: calcTimer
        interval: 120
        onTriggered: {
            calc.command = ["qalc", "-t", "--", root.query];
            calc.running = true;
        }
    }
    Process {
        id: calc
        stdout: StdioCollector {
            onStreamFinished: root.calcResult = text.trim()
        }
    }

    // Emoji list from unicode-emoji, read in the background at startup (it takes a moment)
    FileView {
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        printErrors: false
        onLoaded: {
            const list = [];
            // 1F600 ; fully-qualified # 😀 E1.0 grinning face
            for (const line of text().split("\n")) {
                const m = line.match(/; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/);
                if (m)
                    list.push({ char: m[1], name: m[2].toLowerCase() });
            }
            root.emojis = list;
        }
    }

    // Clipboard history, read whenever clipboard mode opens; image entries get thumbnails
    onModeChanged: if (mode === "clipboard") refreshClips()
    function refreshClips() {
        clipReader.running = true;
        pinReader.running = true;
    }
    Process {
        id: pinReader
        command: [root.clipScript, "pins"]
        stdout: StdioCollector {
            onStreamFinished: root.pins = text.split("\n").filter(l => l.includes("\t")).map(l => {
                const [file, body] = [l.slice(0, l.indexOf("\t")), l.slice(l.indexOf("\t") + 1)];
                return { file: file, text: body === "[[ image ]]" ? "image" : body, image: body === "[[ image ]]" };
            })
        }
    }
    Process {
        id: clipReader
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const body = line.slice(tab + 1);
                    // [[ binary data 383 KiB png 1074x917 ]]
                    const bin = body.match(/^\[\[ binary data (.+) ]]$/);
                    list.push({ id: line.slice(0, tab), text: bin ? "image " + bin[1] : body, image: bin ? bin[1] : "" });
                }
                root.clips = list;
                const ids = list.filter(c => c.image).slice(0, 40).map(c => c.id);
                if (ids.length > 0) {
                    thumbWriter.command = ["sh", "-c", `mkdir -p "$0" && for id in "$@"; do
                        [ -s "$0/$id.png" ] || cliphist list | grep -m1 "^$id	" | cliphist decode > "$0/$id.png"
                    done`, root.thumbDir].concat(ids);
                    thumbWriter.running = true;
                }
            }
        }
    }
    Process {
        id: thumbWriter
        onExited: root.thumbRevision++
    }
    Process {
        id: clipDeleter
        onExited: root.refreshClips()
    }
    function deleteClip(item) {
        if (item?.pin)
            clipDeleter.command = [clipScript, "unpin", item.pin.file];
        else if (item?.clip)
            clipDeleter.command = ["sh", "-c", "cliphist list | grep -m1 \"^" + item.clip.id + "\t\" | cliphist delete"];
        else
            return;
        clipDeleter.running = true;
    }
    function togglePin(item) {
        if (item?.pin)
            clipDeleter.command = [clipScript, "unpin", item.pin.file];
        else if (item?.clip)
            clipDeleter.command = [clipScript, "pin", item.clip.id];
        else
            return;
        clipDeleter.running = true;
    }
    function clearClips() {
        clipDeleter.command = [clipScript, "wipe"];
        clipDeleter.running = true;
    }

    // Projects: folders zoxide knows (most used first) that hold a git repo or a project file
    Process {
        id: projectReader
        command: ["sh", "-c", `zoxide query -l | while IFS= read -r d; do
            for f in "$d"/.git "$d"/package.json "$d"/Cargo.toml "$d"/go.mod "$d"/pyproject.toml "$d"/*.sln "$d"/*.csproj; do
                if [ -e "$f" ]; then echo "$d"; break; fi
            done
        done`]
        stdout: StdioCollector {
            onStreamFinished: root.projects = text.split("\n").filter(p => p && p !== root.home)
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggle();
        }
        // Clears the most-used counts (Settings app > Launcher)
        function forget(): void {
            root.usage = {};
            usageView.setText("{}");
        }
        // Opens with text already typed, e.g. "~" for projects or "=" for the calculator
        function open(text: string): void {
            if (!root.open)
                root.toggle();
            search.text = text;
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
        Behavior on opacity { NumberAnimation { duration: Theme.ms(180) } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    // Drops down from under the bar
    Sheet {
        id: card
        open: root.open
        anchorIds: ["launcher"]
        sheetWidth: Math.min(root.width - Theme.barSpaceX - 56, root.appColumns * root.cellSize + 40)
        sheetHeight: Math.min(600, root.height - Theme.barSpaceY - 40)
        onClosed: root.visible = false
        onDismiss: root.open = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

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
                        name: root.modeInfo?.icon ?? "search"
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
                        Keys.onReturnPressed: event => root.activate(root.results[grid.currentIndex], event.modifiers & Qt.ShiftModifier)
                        Keys.onEnterPressed: event => root.activate(root.results[grid.currentIndex], event.modifiers & Qt.ShiftModifier)
                        Keys.onUpPressed: grid.moveCurrentIndexUp()
                        Keys.onDownPressed: grid.moveCurrentIndexDown()
                        Keys.onTabPressed: grid.moveCurrentIndexRight()
                        Keys.onBacktabPressed: grid.moveCurrentIndexLeft()
                        Keys.onPressed: event => {
                            if (root.mode === "clipboard" && event.key === Qt.Key_Delete && event.modifiers & Qt.ShiftModifier) {
                                if (event.modifiers & Qt.ControlModifier)
                                    root.clearClips();
                                else
                                    root.deleteClip(root.results[grid.currentIndex]);
                                event.accepted = true;
                                return;
                            }
                            if (root.mode === "clipboard" && event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier) {
                                root.togglePin(root.results[grid.currentIndex]);
                                event.accepted = true;
                                return;
                            }
                            // Left/Right move the selection in grids; they only move the cursor
                            // while selecting text or in list modes
                            if (event.modifiers & Qt.ShiftModifier || root.columns === 1)
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
                        text: root.mode === "apps" ? root.results.length + " apps" : root.modeInfo.hint
                        color: Theme.overlay
                    }
                }
            }

            // Mode hints while the field is empty
            RowLayout {
                Layout.fillWidth: true
                visible: search.text === ""
                spacing: 8

                Repeater {
                    model: Object.keys(root.modes)

                    Rectangle {
                        id: chip
                        required property string modelData
                        readonly property var info: root.modes[modelData]

                        implicitWidth: chipRow.implicitWidth + 20
                        implicitHeight: 30
                        radius: 15
                        color: chipMouse.containsMouse ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.surface, 0.6)

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: chip.modelData
                                color: Theme.accent
                                font.bold: true
                            }
                            Icon {
                                name: chip.info.icon
                                size: 16
                                color: Theme.subtext
                            }
                            Label {
                                text: chip.info.hint
                                color: Theme.subtext
                                font.pixelSize: Theme.fontSize - 1
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                search.text = chip.modelData;
                                search.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / root.columns
                cellHeight: root.mode === "apps" ? root.cellSize : root.mode === "emoji" ? 76 : 60
                clip: true
                model: root.results
                // One highlight that glides to the selection
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 160
                highlight: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: root.columns === 1 ? 2 : 4
                        radius: root.columns === 1 ? 14 : 18
                        color: Qt.alpha(Theme.accent, 0.22)
                        border.width: 1
                        border.color: Qt.alpha(Theme.accent, 0.5)
                    }
                }
                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: GridView.isCurrentItem
                    readonly property bool list: root.columns === 1

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: cell.list ? 2 : 4
                        radius: cell.list ? 14 : 18
                        color: !cell.selected && mouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.ms(100) } }
                    }

                    // App tile
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 10
                        visible: cell.modelData.app !== undefined

                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: Math.round(root.cellSize * 0.4)
                            source: cell.modelData.app ? root.iconFor(cell.modelData.app) : ""
                            asynchronous: true
                            scale: cell.selected ? 1.08 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
                        }
                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: cell.modelData.title
                            color: cell.selected ? Theme.text : Theme.subtext
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                        }
                    }

                    // Emoji tile
                    Text {
                        anchors.centerIn: parent
                        visible: cell.modelData.emoji !== undefined
                        text: cell.modelData.emoji ?? ""
                        font.pixelSize: 36
                        scale: cell.selected ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
                    }

                    // List row (calculator, command, project)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14
                        visible: cell.list

                        Icon {
                            visible: !cell.modelData.thumb || thumb.status !== Image.Ready
                            name: cell.modelData.symbol ?? ""
                            filled: cell.selected
                            color: cell.selected ? Theme.accent : Theme.subtext
                            size: 24
                        }
                        // Clipboard image preview
                        Image {
                            id: thumb
                            Layout.preferredWidth: 72
                            Layout.preferredHeight: 44
                            visible: !!cell.modelData.thumb && status === Image.Ready
                            source: cell.modelData.thumb ?? ""
                            sourceSize.width: 144
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Label {
                                Layout.fillWidth: true
                                text: cell.modelData.title
                                font.bold: true
                                font.pixelSize: root.mode === "calc" ? Theme.fontSize + 6 : Theme.fontSize + 1
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: cell.modelData.subtitle ?? ""
                                color: Theme.overlay
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideMiddle
                            }
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(cell.modelData, false)
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    text: root.mode === "apps" ? "No apps match “" + search.text + "”"
                        : root.query === "" ? "Type after “" + search.text.charAt(0) + "”"
                        : "No matches"
                    color: Theme.overlay
                }
            }

            // Selected item's details
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                readonly property var item: root.results[grid.currentIndex] ?? null
                visible: item !== null && root.columns > 1

                Label {
                    text: parent.item?.emoji ? parent.item.title : parent.item?.title ?? ""
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    text: parent.item?.app ? (parent.item.app.comment || parent.item.app.genericName || "") : ""
                    color: Theme.overlay
                    elide: Text.ElideRight
                }
                Label {
                    text: root.mode === "emoji" ? "↵ copy   esc close" : "↵ open   esc close"
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }
    }
}
