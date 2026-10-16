import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Startup apps"
    subtitle: "Started every time you log in, after the desktop itself."

    readonly property string luaPath: Quickshell.env("HOME") + "/.local/state/pikadots/autostart.lua"
    readonly property var allApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .map(e => ({ id: e.id, name: e.name, icon: e.icon }))
        .sort((a, b) => a.name.localeCompare(b.name))

    function save(list) {
        Settings.startup = list;
        const lines = ["-- Written by the Settings app (Startup apps page); run by hypr/autostart.lua at login"];
        for (const a of list)
            if (a.enabled)
                lines.push(`hl.exec_cmd(${JSON.stringify(a.command)}) -- ${a.name.replace(/\n/g, " ")}`);
        luaFile.setText(lines.join("\n") + "\n");
    }

    function add(item) {
        save(Settings.startup.concat([Object.assign({ enabled: true }, item)]));
    }

    function update(index, changes) {
        const list = Settings.startup.slice();
        list[index] = Object.assign({}, list[index], changes);
        save(list);
    }

    function remove(index) {
        const list = Settings.startup.slice();
        list.splice(index, 1);
        save(list);
    }

    FileView {
        id: luaFile
        path: root.luaPath
        printErrors: false
    }

    SettingsSection {
        title: "Your startup apps"

        Repeater {
            model: Settings.startup

            SettingsRow {
                id: item
                required property var modelData
                required property int index
                appIcon: modelData.icon || "utilities-terminal"
                title: modelData.name
                description: modelData.command

                Row {
                    spacing: 8
                    Pill {
                        icon: "play_arrow"
                        implicitHeight: 30
                        onClicked: Quickshell.execDetached(["sh", "-c", item.modelData.command])
                    }
                    Pill {
                        icon: "delete"
                        implicitHeight: 30
                        onClicked: root.remove(item.index)
                    }
                    Switch {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: item.modelData.enabled
                        onToggled: root.update(item.index, { enabled: !checked })
                    }
                }
            }
        }

        Label {
            visible: Settings.startup.length === 0
            Layout.fillWidth: true
            Layout.margins: 18
            text: "Nothing yet. Add an app or a command below."
            color: Theme.subtext
        }
    }

    SettingsSection {
        title: "Add"

        SettingsRow {
            icon: "apps"
            title: "An app"
            description: "Opens like it does from the launcher."
            below: true
            AppPicker {
                options: root.allApps
                placeholder: "Choose an app…"
                onPicked: id => {
                    const app = root.allApps.find(a => a.id === id);
                    root.add({ name: app.name, icon: app.icon, command: "gtk-launch " + id });
                }
            }
        }
        SettingsRow {
            icon: "terminal"
            title: "A command"
            description: "Runs in a shell, e.g. syncthing --no-browser. Press Enter to add."
            below: true
            SettingsTextField {
                id: commandField
                placeholder: "command"
                onAccepted: t => {
                    if (t.trim()) {
                        root.add({ name: t.trim().split(/\s+/)[0].replace(/^.*\//, ""), icon: "", command: t.trim() });
                        commandField.clear();
                    }
                }
            }
        }
    }
}
