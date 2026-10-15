import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Settings app > Window rules: how a given app's windows open (floating, centered, size, which
// workspace, opacity, pinned). Matched by window class. Written to
// ~/.local/state/pikadots/window-rules.lua, which hypr/rules.lua loads; Hyprland reloads after a
// change, so rules apply to windows opened from then on.
SettingsPage {
    id: root
    title: "Window rules"
    subtitle: "How an app's windows open. Applies to windows opened after a change."

    readonly property string luaPath: Quickshell.env("HOME") + "/.local/state/pikadots/window-rules.lua"

    // Apps to pick from: open windows first (their class is known for sure), then installed apps
    readonly property var choices: {
        const seen = {};
        const list = [];
        const add = (cls, name, icon) => {
            if (!cls || seen[cls])
                return;
            seen[cls] = true;
            list.push({ id: cls, name: name, icon: icon });
        };
        for (const t of ToplevelManager.toplevels.values) {
            const entry = DesktopEntries.heuristicLookup(t.appId);
            add(t.appId, entry?.name ?? t.appId, entry?.icon ?? t.appId);
        }
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
            .sort((a, b) => a.name.localeCompare(b.name));
        for (const e of apps)
            add(e.startupClass || e.id.replace(/\.desktop$/, ""), e.name, e.icon);
        return list;
    }

    function regexEscape(s) {
        return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    function luaRule(r) {
        const fields = [`match = { class = ${JSON.stringify("^" + regexEscape(r.cls) + "$")} }`];
        if (r.float) {
            fields.push("float = true");
            if (r.center)
                fields.push("center = true");
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

    function update(index, changes) {
        const list = Settings.windowRules.slice();
        list[index] = Object.assign({}, list[index], changes);
        save(list);
    }

    function remove(index) {
        const list = Settings.windowRules.slice();
        list.splice(index, 1);
        save(list);
    }

    function add(choice) {
        if (Settings.windowRules.some(r => r.cls === choice.id))
            return;
        save(Settings.windowRules.concat([{
            cls: choice.id, name: choice.name, icon: choice.icon,
            float: true, center: true, size: "", pin: false, fullscreen: false,
            workspace: "", silent: false, opacity: 1, noBlur: false
        }]));
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false
    }

    // One reload after a burst of changes (slider drags, typing)
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
            title: r.name

            SettingsRow {
                appIcon: rule.r.icon || "application-x-executable"
                title: "Window class"
                description: rule.r.cls
                Pill {
                    icon: "delete"
                    implicitHeight: 30
                    onClicked: root.remove(rule.index)
                }
            }

            SettingsRow {
                icon: "tune"
                title: "Opens"
                below: true
                Flow {
                    spacing: 6
                    Repeater {
                        model: [
                            { key: "float", label: "Floating", show: true },
                            { key: "center", label: "Centered", show: rule.r.float },
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
                visible: rule.r.float
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
        subtitle: "Open windows are listed first."

        SettingsRow {
            icon: "add"
            title: "App"
            below: true
            AppPicker {
                options: root.choices.filter(c => !Settings.windowRules.some(r => r.cls === c.id))
                placeholder: "Choose an app…"
                onPicked: id => root.add(root.choices.find(c => c.id === id))
            }
        }
    }

    component ToggleChip: Rectangle {
        id: chip
        property alias text: label.text
        property bool checked: false
        signal clicked()

        implicitWidth: label.implicitWidth + 26
        implicitHeight: 30
        radius: height / 2
        color: checked ? Theme.accent : mouse.containsMouse ? Qt.alpha(Theme.overlay, 0.35) : Qt.alpha(Theme.base, 0.6)
        border.width: checked ? 0 : 1
        border.color: Qt.alpha(Theme.overlay, 0.3)

        Label {
            id: label
            anchors.centerIn: parent
            color: chip.checked ? Theme.accentText : Theme.text
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
