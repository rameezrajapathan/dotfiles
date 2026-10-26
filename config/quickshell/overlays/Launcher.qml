import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    Exclusive { panel: root }

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
    readonly property var styles: ["bar", "dock", "center", "fullscreen", "spotlight"]
    property string activeStyle: "bar"
    readonly property bool spotlight: activeStyle === "spotlight"
    readonly property bool fullscreen: activeStyle === "fullscreen"
    readonly property int cell: Math.round(cellSize * (fullscreen ? 1.35 : 1))
    readonly property int fsWidth: Math.min(1500, width - 160)
    readonly property int fsColumns: Math.max(4, Math.floor(fsWidth / cell))
    readonly property int columns: mode === "apps" ? (spotlight ? 1 : fullscreen ? fsColumns : appColumns) : mode === "emoji" ? (spotlight ? 8 : 10) : 1
    readonly property int cardWidth: Math.min(width - Theme.barSpaceX - 56, appColumns * cellSize + 40)
    readonly property int cardHeight: Math.min(600, height - Theme.barSpaceY - 40)

    property string category: ""
    readonly property var categoryNames: [
        ["", "All"], ["Network", "Internet"], ["Development", "Development"], ["Graphics", "Graphics"],
        ["AudioVideo", "Media"], ["Office", "Office"], ["Game", "Games"], ["Education", "Education"],
        ["Science", "Science"], ["Utility", "Utilities"], ["System", "System"], ["Settings", "Settings"]
    ]
    readonly property var categoryChips: categoryNames.filter(c => !c[0] || apps.some(e => e.categories.includes(c[0])))

    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    property string calcResult: ""
    property var emojis: []
    property var projects: []
    property var clips: []
    property var pins: []
    readonly property string clipScript: Quickshell.env("HOME") + "/.config/hypr/scripts/clipboard.sh"
    property int thumbRevision: 0
    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-clipboard"

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
            return appResults(q).map(e => ({ title: e.name, subtitle: e.comment || e.genericName || "", app: e, run: () => launch(e) }));
        }
    }

    function appResults(q) {
        const pool = fullscreen && category ? apps.filter(e => e.categories.includes(category)) : apps;
        if (q === "")
            return Settings.launcher.mostUsedFirst
                ? pool.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name))
                : pool;
        const scored = [];
        for (const e of pool) {
            const s = score(e, q);
            if (s >= 0)
                scored.push({ e: e, s: s });
        }
        return scored
            .sort((a, b) => a.s - b.s || (usage[b.e.id] ?? 0) - (usage[a.e.id] ?? 0) || a.e.name.localeCompare(b.e.name))
            .map(x => x.e);
    }

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

    function toggle(style) {
        if (dockWait.running) {
            dockWait.stop();
            finish();
            return;
        }
        if (open) {
            open = false;
            return;
        }
        const want = styles.includes(style) ? style : styles.includes(Settings.launcher.style) ? Settings.launcher.style : "bar";
        const name = screen?.name ?? "";
        activeStyle = want === "dock" && !Dock.availableOn(name) ? "center" : want;
        search.text = "";
        category = "";
        grid.currentIndex = 0;
        grid.positionViewAtBeginning();
        projectReader.running = true;
        visible = true;
        if (activeStyle === "dock") {
            Dock.holdScreen = name;
            if (!Dock.places[name]?.shown) {
                dockWait.restart();
                return;
            }
        }
        open = true;
    }

    Timer {
        id: dockWait
        interval: Theme.ms(280)
        onTriggered: root.open = true
    }

    function finish() {
        if (open)
            return;
        visible = false;
        Dock.holdScreen = "";
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
        if (Background.reveal(e))
            return;
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

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"])

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

    FileView {
        path: "/usr/share/unicode/emoji/emoji-test.txt"
        printErrors: false
        onLoaded: {
            const list = [];
            for (const line of text().split("\n")) {
                const m = line.match(/; fully-qualified\s+# (\S+) E[\d.]+ (.+)$/);
                if (m)
                    list.push({ char: m[1], name: m[2].toLowerCase() });
            }
            root.emojis = list;
        }
    }

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
            root.toggle("");
        }
        function toggleStyle(style: string): void {
            root.toggle(style);
        }
        function style(name: string): void {
            if (root.styles.includes(name))
                Settings.launcher.style = name;
        }
        function forget(): void {
            root.usage = {};
            usageView.setText("{}");
        }
        function open(text: string): void {
            if (!root.open)
                root.toggle("");
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

    Rectangle {
        anchors.fill: parent
        color: root.fullscreen ? Qt.alpha(Theme.base, 0.62) : "black"
        opacity: root.open ? (root.fullscreen ? 1 : root.activeStyle === "dock" ? 0 : 0.3) : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(root.fullscreen ? 240 : 180) } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    property real shown: root.open && root.activeStyle !== "bar" ? 1 : 0
    Behavior on shown { NumberAnimation { duration: Theme.ms(root.open ? 280 : 180); easing.type: Easing.OutCubic } }
    onShownChanged: if (shown === 0 && activeStyle !== "bar") finish()

    readonly property int spotlightHeight: {
        const m = 2 * Theme.pad(20, 24);
        if (search.text === "")
            return m + 52 + (Object.keys(modes).length ? 14 + 30 : 0);
        const rows = Math.max(1, Math.min(columns === 1 ? 7 : 4, Math.ceil(grid.count / columns)));
        return m + 52 + 14 + rows * grid.cellHeight;
    }

    readonly property var dockPlace: Dock.places[screen?.name ?? ""] ?? null
    readonly property rect floatTarget: {
        const W = width;
        const H = height;
        if (spotlight) {
            const w = Math.min(720, W - 80);
            return Qt.rect((W - w) / 2, Math.round(H * 0.2), w, spotlightHeight);
        }
        const p = dockPlace;
        if (activeStyle === "dock" && p) {
            const gap = 12;
            if (p.edge === "bottom") {
                const h = Math.min(cardHeight, p.y - gap - Theme.barSpaceY - 24);
                return Qt.rect(Math.max(16, Math.min(W - cardWidth - 16, p.x + p.width / 2 - cardWidth / 2)), p.y - gap - h, cardWidth, h);
            }
            const w = Math.min(cardWidth, (p.edge === "left" ? W - p.x - p.width : p.x) - gap - 24);
            const y = Math.max(16, Math.min(H - cardHeight - 16, p.y + p.height / 2 - cardHeight / 2));
            return Qt.rect(p.edge === "left" ? p.x + p.width + gap : p.x - gap - w, y, w, cardHeight);
        }
        return Qt.rect((W - cardWidth) / 2, (H - cardHeight) / 2, cardWidth, cardHeight);
    }
    readonly property rect floatFrom: {
        const t = floatTarget;
        const p = dockPlace;
        if (activeStyle === "dock" && p)
            return Qt.rect(p.x, p.y, p.width, p.height);
        if (spotlight)
            return Qt.rect(t.x, t.y - 12, t.width, t.height);
        return Qt.rect(t.x + t.width * 0.03, t.y + t.height * 0.03, t.width * 0.94, t.height * 0.94);
    }

    Sheet {
        id: card
        open: root.open && root.activeStyle === "bar"
        anchorIds: ["launcher"]
        sheetWidth: root.cardWidth
        sheetHeight: root.cardHeight
        onClosed: if (root.activeStyle === "bar") root.finish()
        onDismiss: root.open = false

        Item {
            id: barSlot
            anchors.fill: parent
        }
    }

    Rectangle {
        id: floatCard
        readonly property real t: root.shown
        readonly property bool morph: root.activeStyle === "dock"
        visible: root.activeStyle !== "bar" && !root.fullscreen && t > 0
        x: root.floatFrom.x + (root.floatTarget.x - root.floatFrom.x) * t
        y: root.floatFrom.y + (root.floatTarget.y - root.floatFrom.y) * t
        width: root.floatFrom.width + (root.floatTarget.width - root.floatFrom.width) * t
        height: root.floatFrom.height + (root.floatTarget.height - root.floatFrom.height) * t
        Behavior on height {
            enabled: root.spotlight && floatCard.t === 1
            NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic }
        }
        opacity: morph ? 1 : t
        radius: Theme.round(morph ? 22 + 2 * t : 24, width, height)
        color: "transparent"

        GlassPanel {
            radius: floatCard.radius
            tint: Theme.baseTranslucent
            shadow: true
            tracking: floatCard.t < 1 || root.spotlight
        }

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: floatSlot
            anchors.fill: parent
            clip: true
            opacity: floatCard.morph ? Math.max(0, (floatCard.t - 0.45) / 0.55) : 1
        }
    }

    Item {
        id: fsSlot
        visible: root.fullscreen && root.shown > 0
        width: root.fsWidth
        x: (root.width - width) / 2
        y: Theme.barSpaceY + 64
        height: root.height - y - 48
        opacity: root.shown
        scale: 1.04 - 0.04 * root.shown
    }

    Item {
        id: body
        parent: root.activeStyle === "bar" ? barSlot : root.fullscreen ? fsSlot : floatSlot
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.fullscreen ? 0 : Theme.pad(20, 24)
            spacing: 14

            Rectangle {
                id: searchBox
                Layout.fillWidth: true
                Layout.maximumWidth: root.fullscreen ? 720 : -1
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 52
                radius: Theme.round(16, width, height)
                color: Theme.glassFill(2)
                GlassRim {
                    visible: !search.activeFocus && Glass.rim > 0
                }
                border.width: 2
                border.color: Theme.gradientAccent && (search.activeFocus) ? "transparent" : search.activeFocus ? Qt.alpha(Theme.accent, 0.6) : "transparent"
                GradientBorder {
                    active: search.activeFocus
                    strength: 0.6
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.pad(18, 16, parent.width, parent.height)
                    anchors.rightMargin: Theme.pad(18, 16, parent.width, parent.height)
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

            RowLayout {
                id: modeChips
                Layout.fillWidth: !root.fullscreen
                Layout.alignment: Qt.AlignHCenter
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
                        radius: Theme.round(15, width, height)
                        color: chipMouse.containsMouse ? Qt.alpha(Theme.accent, 0.22) : Theme.glassFill(2)
                        GlassRim {
                            strength: 0.7
                        }

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

            Row {
                id: categoryRow
                Layout.alignment: Qt.AlignHCenter
                visible: root.fullscreen && root.mode === "apps"
                spacing: 8

                Repeater {
                    model: root.categoryChips

                    Rectangle {
                        id: catChip
                        required property var modelData
                        readonly property bool selected: root.category === modelData[0]
                        implicitWidth: catLabel.implicitWidth + 24
                        implicitHeight: 30
                        radius: Theme.round(15, width, height)
                        color: selected ? Theme.selectedFill : catMouse.containsMouse ? Qt.alpha(Theme.accent, 0.22) : Theme.glassFill(2)
                        gradient: Theme.accentFill(selected)
                        GlassRim {
                            strength: 0.7
                        }

                        Label {
                            id: catLabel
                            anchors.centerIn: parent
                            text: catChip.modelData[1]
                            color: catChip.selected ? Theme.selectedText : Theme.subtext
                            font.pixelSize: Theme.fontSize - 1
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.category = catChip.modelData[0];
                                grid.currentIndex = 0;
                                search.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            GridView {
                id: grid
                visible: !(root.spotlight && search.text === "")
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignTop
                readonly property real space: parent.height - searchBox.implicitHeight - 14
                    - (modeChips.visible ? modeChips.implicitHeight + 14 : 0)
                    - (categoryRow.visible ? categoryRow.implicitHeight + 14 : 0)
                    - (footerRow.visible ? footerRow.implicitHeight + 14 : 0)
                Layout.maximumHeight: Math.max(cellHeight, Math.floor(space / cellHeight) * cellHeight)
                cellWidth: width / root.columns
                cellHeight: root.mode === "apps" ? (root.columns === 1 ? 60 : root.cell) : root.mode === "emoji" ? 76 : 60
                clip: true
                model: root.results
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 160
                highlight: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: root.columns === 1 ? 2 : 4
                        radius: Theme.round(root.columns === 1 ? 14 : 18, width, height)
                        color: Qt.alpha(Theme.accent, 0.22)
                        border.width: 1
                        border.color: Theme.gradientAccent ? "transparent" : Qt.alpha(Theme.accent, 0.5)
                        GradientBorder {
                            strength: 0.5
                        }
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
                        radius: Theme.round(cell.list ? 14 : 18, width, height)
                        color: !cell.selected && mouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.ms(100) } }
                        GlassRim {}
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 10
                        visible: cell.modelData.app !== undefined && !cell.list

                        IconImage {
                            Layout.alignment: Qt.AlignHCenter
                            implicitSize: Math.round(root.cell * 0.4)
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

                    Text {
                        anchors.centerIn: parent
                        visible: cell.modelData.emoji !== undefined
                        text: cell.modelData.emoji ?? ""
                        font.pixelSize: 36
                        scale: cell.selected ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.pad(16, 14)
                        anchors.rightMargin: Theme.pad(16, 14)
                        spacing: 14
                        visible: cell.list

                        IconImage {
                            visible: cell.modelData.app !== undefined
                            implicitSize: 32
                            source: cell.modelData.app ? root.iconFor(cell.modelData.app) : ""
                            asynchronous: true
                        }
                        Icon {
                            visible: cell.modelData.app === undefined && (!cell.modelData.thumb || thumb.status !== Image.Ready)
                            name: cell.modelData.symbol ?? ""
                            filled: cell.selected
                            color: cell.selected ? Theme.accent : Theme.subtext
                            size: 24
                        }
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

            RowLayout {
                id: footerRow
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
