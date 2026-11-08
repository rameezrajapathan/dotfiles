import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Default apps"
    subtitle: "Which app opens what. Keybinds and panels use these too."

    onShownChanged: if (shown) DefaultApps.load()

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
                    options: DefaultApps.apps[modelData.kind]?.options ?? []
                    current: DefaultApps.apps[modelData.kind]?.current ?? ""
                    onPicked: id => DefaultApps.set(modelData.kind, id)
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
                    options: DefaultApps.apps[modelData.kind]?.options ?? []
                    current: DefaultApps.apps[modelData.kind]?.current ?? ""
                    onPicked: id => DefaultApps.set(modelData.kind, id)
                }
            }
        }
    }
}
