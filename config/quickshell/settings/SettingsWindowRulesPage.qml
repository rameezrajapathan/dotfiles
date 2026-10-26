import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Window rules"
    subtitle: "How an app's windows open. Applies to windows opened after a change."

    readonly property string luaPath: Quickshell.env("HOME") + "/.local/state/pikadots/window-rules.lua"
    readonly property string terminalScript: Quickshell.env("HOME") + "/.config/hypr/scripts/terminal-app.sh"
    property string message

    readonly property var choices: {
        const seen = {};
        const list = [];
        const add = (cls, name, icon, entry, terminal) => {
            if (!cls || seen[cls])
                return;
            seen[cls] = true;
            list.push({ id: cls, name: name, icon: icon, entry: entry, terminal: terminal });
        };
        for (const t of ToplevelManager.toplevels.values) {
            const entry = DesktopEntries.heuristicLookup(t.appId);
            add(t.appId, entry?.name ?? t.appId, entry?.icon ?? t.appId, entry && !entry.runInTerminal ? entry.id : "", false);
        }
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
            .sort((a, b) => a.name.localeCompare(b.name));
        for (const e of apps)
            add(e.startupClass || e.id.replace(/\.desktop$/, ""), e.name, e.icon, e.id, e.runInTerminal);
        return list;
    }

    readonly property var spots: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]
    readonly property var spotNames: ({
        "top-left": "Top left", "top": "Top", "top-right": "Top right",
        "left": "Left", "center": "Center", "right": "Right",
        "bottom-left": "Bottom left", "bottom": "Bottom", "bottom-right": "Bottom right"
    })
    function positionOf(r) {
        return r.position ?? (r.center ? "center" : "");
    }

    property var expanded: ({})
    function setExpanded(cls, on) {
        const e = Object.assign({}, expanded);
        e[cls] = on;
        expanded = e;
    }

    function summary(r) {
        const parts = [];
        if (r.terminal)
            parts.push("Terminal app");
        if (r.float) {
            const pos = positionOf(r);
            parts.push("Floating");
            if (pos === "exact")
                parts.push("at " + (r.x ?? 0) + ", " + (r.y ?? 0));
            else if (pos)
                parts.push(spotNames[pos]);
            if (/^\d+ \d+$/.test(r.size ?? ""))
                parts.push(r.size.replace(" ", "×"));
            if (r.pin)
                parts.push("every workspace");
        }
        if (r.fullscreen)
            parts.push("Fullscreen");
        if (r.workspace)
            parts.push("workspace " + r.workspace + (r.silent ? " (stay)" : ""));
        if (r.opacity < 1)
            parts.push(Math.round(r.opacity * 100) + "% opacity");
        if (r.noBlur)
            parts.push("no blur");
        return parts.length ? parts.join(" · ") : "No changes yet";
    }

    readonly property int edgeGap: parseInt(String(Hypr.value("general.gaps_out") ?? 10).split(/[ ,]/)[0]) || 10
    readonly property int topGap: Theme.barHeight + edgeGap
    readonly property var screenSize: {
        const s = Quickshell.screens[0];
        return s ? Math.round(s.width) + " × " + Math.round(s.height) : "";
    }

    function moveFor(spot) {
        const col = spot.endsWith("left") ? "left" : spot.endsWith("right") ? "right" : "middle";
        const row = spot.startsWith("top") ? "top" : spot.startsWith("bottom") ? "bottom" : "middle";
        const x = { left: `${edgeGap}`, middle: "(monitor_w-window_w)/2", right: `monitor_w-window_w-${edgeGap}` }[col];
        const y = { top: `${topGap}`, middle: `${Theme.barHeight}+(monitor_h-${Theme.barHeight}-window_h)/2`, bottom: `monitor_h-window_h-${edgeGap}` }[row];
        return `(${x}) (${y})`;
    }

    function entryId(s) {
        return (s ?? "").replace(/\.desktop$/, "");
    }

    function regexEscape(s) {
        return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    function luaRule(r) {
        const fields = [`match = { class = ${JSON.stringify("^" + regexEscape(r.cls) + "$")} }`];
        if (r.float) {
            fields.push("float = true");
            const pos = positionOf(r);
            if (pos === "center")
                fields.push("center = true");
            else if (pos === "exact" && Number.isFinite(r.x) && Number.isFinite(r.y))
                fields.push(`move = "${r.x} ${r.y}"`);
            else if (spots.includes(pos))
                fields.push(`move = "${moveFor(pos)}"`);
            if (/^\d+ \d+$/.test(r.size ?? ""))
                fields.push(`size = "${r.size}"`);
            if (r.pin)
                fields.push("pin = true");
        }
        if (r.fullscreen)
            fields.push("fullscreen = true");
        if (r.workspace)
            fields.push(`workspace = "${r.workspace}${r.silent ? " silent" : ""}"`);
        if (r.opacity < 1)
            fields.push(`opacity = "${r.opacity.toFixed(2)}"`);
        if (r.noBlur)
            fields.push("no_blur = true");
        return `hl.window_rule({ ${fields.join(", ")} }) -- ${r.name.replace(/\n/g, " ")}`;
    }

    function save(list) {
        Settings.windowRules = list;
        const lines = ["-- Written by the Settings app (Window rules page); loaded at the end of hypr/rules.lua"];
        for (const r of list)
            lines.push(luaRule(r));
        luaFile.setText(lines.join("\n") + "\n");
        reloadTimer.restart();
    }

    function indexOf(cls) {
        return Settings.windowRules.findIndex(r => r.cls === cls);
    }

    function update(index, changes) {
        const list = Settings.windowRules.slice();
        list[index] = Object.assign({}, list[index], changes);
        save(list);
    }

    function remove(index) {
        const r = Settings.windowRules[index];
        if (r.terminal && r.entry)
            terminalApp(["remove", r.entry]);
        const list = Settings.windowRules.slice();
        list.splice(index, 1);
        save(list);
    }

    function newRule(fields) {
        return Object.assign({
            float: true, position: "center", x: 0, y: 0, size: "", pin: false, fullscreen: false,
            workspace: "", silent: false, opacity: 1, noBlur: false, terminal: false, entry: "", command: ""
        }, fields);
    }

    function add(choice) {
        if (!choice)
            return;
        message = "";
        if (!choice.terminal) {
            if (indexOf(choice.id) < 0) {
                setExpanded(choice.id, true);
                save(Settings.windowRules.concat([newRule({ cls: choice.id, name: choice.name, icon: choice.icon, entry: choice.entry })]));
            }
            return;
        }
        const cls = "pikadots-" + entryId(choice.entry).toLowerCase().replace(/[^a-z0-9]+/g, "-");
        if (indexOf(cls) >= 0)
            return;
        terminalApp(["wrap", entryId(choice.entry) + ".desktop", cls], out => {
            setExpanded(cls, true);
            save(Settings.windowRules.concat([newRule({
                cls: cls, name: choice.name, icon: choice.icon, terminal: true, entry: entryId(out.trim().split("\n").pop())
            })]));
        });
    }

    function addCommand(command) {
        const cmd = command.trim();
        if (!cmd)
            return;
        message = "";
        const word = cmd.split(/\s+/)[0].split("/").pop();
        const slug = word.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "app";
        let cls = "pikadots-" + slug;
        for (let n = 2; indexOf(cls) >= 0; n++)
            cls = "pikadots-" + slug + "-" + n;
        const name = word.charAt(0).toUpperCase() + word.slice(1);
        const icon = Quickshell.hasThemeIcon(slug) ? slug : "utilities-terminal";
        terminalApp(["add", cls, name, icon, cmd], () => {
            commandField.clear();
            setExpanded(cls, true);
            save(Settings.windowRules.concat([newRule({ cls: cls, name: name, icon: icon, terminal: true, entry: cls, command: cmd })]));
        });
    }

    function open(r) {
        if (r.entry)
            Quickshell.execDetached(["gtk-launch", entryId(r.entry)]);
        else
            DesktopEntries.heuristicLookup(r.cls)?.execute();
    }

    function terminalApp(args, done) {
        const proc = scriptProcess.createObject(root, {
            command: ["sh", "-c", '"$0" "$@" 2>&1; echo "exit:$?"', terminalScript].concat(args)
        });
        proc.done = text => {
            const lines = text.trim().split("\n");
            const code = Number((lines.pop() ?? "").replace("exit:", ""));
            const out = lines.join("\n");
            if (code === 0)
                done?.(out);
            else
                root.message = out || "terminal-app.sh failed";
            proc.destroy();
        };
        proc.running = true;
    }

    Component {
        id: scriptProcess
        Process {
            id: proc
            property var done
            stdout: StdioCollector {
                onStreamFinished: proc.done(text)
            }
        }
    }

    property string capturing
    Process {
        id: capture
        command: ["sh", "-c", "printf '{\"clients\":%s,\"monitors\":%s}' \"$(hyprctl -j clients)\" \"$(hyprctl -j monitors)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const index = root.indexOf(root.capturing);
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    return;
                }
                const c = data.clients.filter(c => c.class === root.capturing)
                    .sort((a, b) => a.focusHistoryID - b.focusHistoryID)[0];
                const m = c && data.monitors.find(m => m.id === c.monitor);
                if (index < 0 || !c || !m)
                    return;
                root.update(index, {
                    float: true, position: "exact",
                    x: c.at[0] - m.x, y: c.at[1] - m.y,
                    size: c.size[0] + " " + c.size[1]
                });
            }
        }
    }

    function hasWindow(cls) {
        return ToplevelManager.toplevels.values.some(t => t.appId === cls);
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false
    }

    Timer {
        id: reloadTimer
        interval: 700
        onTriggered: Quickshell.execDetached(["hyprctl", "reload"])
    }

    Repeater {
        model: Settings.windowRules

        SettingsSection {
            id: rule
            required property var modelData
            required property int index
            readonly property var r: modelData
            readonly property string position: root.positionOf(r)
            readonly property bool open: root.expanded[r.cls] === true
            title: index === 0 ? "Rules" : ""

            SettingsRow {
                appIcon: rule.r.icon || "application-x-executable"
                title: rule.r.name
                description: root.summary(rule.r)
                RowLayout {
                    spacing: 6
                    Pill {
                        icon: "play_arrow"
                        tip: "Open the app"
                        implicitHeight: 30
                        onClicked: root.open(rule.r)
                    }
                    Pill {
                        icon: rule.open ? "expand_less" : "edit"
                        tip: rule.open ? "Close editor" : "Edit rule"
                        active: rule.open
                        implicitHeight: 30
                        onClicked: root.setExpanded(rule.r.cls, !rule.open)
                    }
                    Pill {
                        icon: "delete"
                        tip: "Remove rule"
                        implicitHeight: 30
                        onClicked: root.remove(rule.index)
                    }
                }
            }

            SettingsRow {
                visible: rule.open
                icon: rule.r.terminal ? "terminal" : "label"
                title: rule.r.terminal ? "Terminal app" : "Window class"
                description: rule.r.terminal ? (rule.r.command || rule.r.name) + " · in the launcher, opens as " + rule.r.cls : rule.r.cls
            }

            SettingsRow {
                visible: rule.open
                icon: "tune"
                title: "Opens"
                below: true
                Flow {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "float", label: "Floating", show: true },
                            { key: "pin", label: "On every workspace", show: rule.r.float },
                            { key: "fullscreen", label: "Fullscreen", show: true },
                            { key: "noBlur", label: "No blur", show: true }
                        ].filter(o => o.show)
                        ToggleChip {
                            required property var modelData
                            text: modelData.label
                            checked: rule.r[modelData.key] === true
                            onClicked: root.update(rule.index, { [modelData.key]: !checked })
                        }
                    }
                }
            }

            SettingsRow {
                visible: rule.open && rule.r.float
                icon: "picture_in_picture"
                title: "Position"
                description: rule.position === "" ? "Wherever the app or Hyprland puts it."
                    : rule.position === "exact" ? "Pixels from the screen's top-left corner (this screen is " + root.screenSize + ")."
                    : root.spotNames[rule.position] + ", kept clear of the bar and the screen edges."
                below: true

                RowLayout {
                    spacing: 16

                    Rectangle {
                        implicitWidth: spotGrid.implicitWidth + 12
                        implicitHeight: spotGrid.implicitHeight + 12
                        radius: Theme.round(10, width, height)
                        color: Qt.alpha(Theme.base, 0.6)
                        border.width: Glass.active ? 0 : 1
                        border.color: Qt.alpha(Theme.overlay, 0.3)

                        Grid {
                            id: spotGrid
                            anchors.centerIn: parent
                            columns: 3
                            spacing: 4
                            Repeater {
                                model: root.spots
                                Rectangle {
                                    id: spot
                                    required property string modelData
                                    readonly property bool selected: rule.position === modelData
                                    width: 34
                                    height: 22
                                    radius: Theme.round(6, width, height)
                                    color: selected ? Theme.selectedFill : spotMouse.containsMouse ? Qt.alpha(Theme.overlay, 0.45) : Qt.alpha(Theme.overlay, 0.18)
                                    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
                                    MouseArea {
                                        id: spotMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.update(rule.index, { position: spot.modelData, center: false })
                                    }
                                    Tooltip {
                                        text: root.spotNames[spot.modelData] ?? ""
                                    }
                                    GlassRim {}
                                }
                            }
                        }
                        GlassRim {}
                    }

                    ColumnLayout {
                        spacing: 8
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            ToggleChip {
                                text: "Auto"
                                checked: rule.position === ""
                                onClicked: root.update(rule.index, { position: "", center: false })
                            }
                            ToggleChip {
                                text: "Exact"
                                checked: rule.position === "exact"
                                onClicked: root.update(rule.index, { position: "exact", center: false })
                            }
                            ToggleChip {
                                visible: root.hasWindow(rule.r.cls)
                                text: "Use the open window"
                                onClicked: {
                                    root.capturing = rule.r.cls;
                                    capture.running = true;
                                }
                            }
                        }
                        RowLayout {
                            visible: rule.position === "exact"
                            spacing: 8
                            Label { text: "X"; color: Theme.subtext }
                            SettingsTextField {
                                implicitWidth: 80
                                text: String(rule.r.x ?? 0)
                                onAccepted: t => {
                                    if (/^\d+$/.test(t.trim()))
                                        root.update(rule.index, { x: Number(t.trim()) });
                                }
                            }
                            Label { text: "Y"; color: Theme.subtext }
                            SettingsTextField {
                                implicitWidth: 80
                                text: String(rule.r.y ?? 0)
                                onAccepted: t => {
                                    if (/^\d+$/.test(t.trim()))
                                        root.update(rule.index, { y: Number(t.trim()) });
                                }
                            }
                        }
                    }
                }
            }

            SettingsRow {
                visible: rule.open && rule.r.float
                icon: "aspect_ratio"
                title: "Size"
                description: "Width and height in pixels, e.g. 1000 700. Empty: the app's own."
                SettingsTextField {
                    implicitWidth: 140
                    text: rule.r.size
                    placeholder: "auto"
                    onAccepted: t => {
                        const v = t.trim().replace(/\s*[x×,]\s*|\s+/, " ");
                        if (v === "" || /^\d+ \d+$/.test(v))
                            root.update(rule.index, { size: v });
                    }
                }
            }

            SettingsRow {
                visible: rule.open
                icon: "space_dashboard"
                title: "Workspace"
                description: rule.r.workspace ? (rule.r.silent ? "Opens there without switching to it." : "Opens there and switches to it.") : "Wherever you are."
                below: true
                ColumnLayout {
                    spacing: 8
                    SettingsChips {
                        options: [{ value: "", label: "Current" }].concat([1, 2, 3, 4, 5, 6, 7, 8, 9].map(n => ({ value: String(n), label: String(n) })))
                        current: rule.r.workspace
                        onPicked: v => root.update(rule.index, { workspace: v })
                    }
                    ToggleChip {
                        visible: rule.r.workspace !== ""
                        text: "Stay where I am"
                        checked: rule.r.silent
                        onClicked: root.update(rule.index, { silent: !checked })
                    }
                }
            }

            SettingsRow {
                visible: rule.open
                icon: "opacity"
                title: "Opacity"
                SettingsSlider {
                    from: 50; to: 100; stepSize: 5
                    value: Math.round(rule.r.opacity * 100)
                    suffix: "%"
                    onMoved: v => root.update(rule.index, { opacity: v / 100 })
                }
            }
        }
    }

    SettingsSection {
        title: Settings.windowRules.length ? "Add another" : "Add a rule"
        subtitle: "Open windows are listed first. Terminal apps get a launcher entry that opens them with a class of their own."

        SettingsRow {
            icon: "add"
            title: "App"
            below: true
            AppPicker {
                options: root.choices.filter(c => !Settings.windowRules.some(r => r.cls === c.id || (r.terminal && root.entryId(r.entry) === root.entryId(c.entry))))
                placeholder: "Choose an app…"
                onPicked: id => root.add(root.choices.find(c => c.id === id))
            }
        }

        SettingsRow {
            icon: "terminal"
            title: "Terminal app"
            description: "A command to run in the terminal, like cava or peaclock."
            RowLayout {
                spacing: 6
                SettingsTextField {
                    id: commandField
                    implicitWidth: 200
                    placeholder: "cava"
                    onEntered: t => root.addCommand(t)
                }
                Pill {
                    icon: "add"
                    tip: "Add"
                    implicitHeight: 30
                    onClicked: root.addCommand(commandField.currentText)
                }
            }
        }

        SettingsRow {
            visible: root.message !== ""
            icon: "error"
            title: "Couldn't add it"
            description: root.message
        }
    }

    component ToggleChip: Rectangle {
        id: chip
        property alias text: label.text
        property bool checked: false
        signal clicked()

        implicitWidth: label.implicitWidth + 26
        implicitHeight: 30
        radius: Theme.round(height / 2, width, height)
        color: checked ? Theme.selectedFill : mouse.containsMouse ? Qt.alpha(Theme.overlay, 0.35) : Qt.alpha(Theme.base, 0.6)
        border.width: checked ? 0 : 1
        border.color: Qt.alpha(Theme.overlay, 0.3)

        Label {
            id: label
            anchors.centerIn: parent
            color: chip.checked ? Theme.selectedText : Theme.text
            font.pixelSize: Theme.fontSize - 1
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }
}
