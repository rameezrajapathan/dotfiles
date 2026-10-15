import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Settings app > Default apps: what opens links, folders, text, pictures and so on
// (hypr/scripts/default-apps.py; the keybinds and panels open them through scripts/app.sh).
SettingsPage {
    id: root
    title: "Default apps"
    subtitle: "Which app opens what. Keybinds and panels use these too."

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/default-apps.py"
    property var apps: ({})

    onShownChanged: if (shown) reader.running = true

    function pick(kind, id) {
        const next = Object.assign({}, apps);
        next[kind] = Object.assign({}, next[kind], { current: id });
        apps = next;
        setter.command = ["python3", "-I", script, "set", kind, id];
        setter.running = true;
    }

    Process {
        id: reader
        command: ["python3", "-I", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apps = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: setter
        onExited: reader.running = true
    }

    SettingsSection {
        title: "Essentials"
        Repeater {
            model: [
                { kind: "browser", icon: "language", title: "Web browser" },
                { kind: "terminal", icon: "terminal", title: "Terminal" },
                { kind: "files", icon: "folder", title: "Files" },
                { kind: "editor", icon: "edit_note", title: "Text editor" },
                { kind: "mail", icon: "mail", title: "Email" }
            ]
            SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                below: true
                AppPicker {
                    options: root.apps[modelData.kind]?.options ?? []
                    current: root.apps[modelData.kind]?.current ?? ""
                    onPicked: id => root.pick(modelData.kind, id)
                }
            }
        }
    }

    SettingsSection {
        title: "Media"
        Repeater {
            model: [
                { kind: "images", icon: "image", title: "Pictures" },
                { kind: "video", icon: "movie", title: "Videos" },
                { kind: "music", icon: "music_note", title: "Music" },
                { kind: "pdf", icon: "picture_as_pdf", title: "PDF documents" }
            ]
            SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                below: true
                AppPicker {
                    options: root.apps[modelData.kind]?.options ?? []
                    current: root.apps[modelData.kind]?.current ?? ""
                    onPicked: id => root.pick(modelData.kind, id)
                }
            }
        }
    }
}
