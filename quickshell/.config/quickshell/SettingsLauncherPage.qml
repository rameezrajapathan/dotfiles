import Quickshell
import QtQuick
import QtQuick.Layouts

// Settings app > Launcher: the app grid and the typed modes (=, >, :, ~, +).
SettingsPage {
    id: root
    title: "Launcher"
    subtitle: "The app grid (Super + A) and its modes."

    readonly property var l: Settings.launcher

    SettingsSection {
        title: "Apps"

        SettingsRow {
            icon: "grid_view"
            title: "Columns"
            SettingsSlider {
                from: 4; to: 8
                value: root.l.columns
                onMoved: v => root.l.columns = v
            }
        }
        SettingsRow {
            icon: "photo_size_select_large"
            title: "Icon size"
            SettingsSlider {
                from: 96; to: 160; stepSize: 8
                value: root.l.cellSize
                suffix: " px"
                onMoved: v => root.l.cellSize = v
            }
        }
        SettingsRow {
            icon: "trending_up"
            title: "Most used first"
            description: "Otherwise apps are in alphabetical order."
            Switch {
                checked: root.l.mostUsedFirst
                onToggled: root.l.mostUsedFirst = !checked
            }
        }
        SettingsRow {
            icon: "history"
            title: "Forget app usage"
            description: "Starts counting again from zero."
            Pill {
                icon: "delete_sweep"
                implicitHeight: 30
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "forget"])
            }
        }
    }

    SettingsSection {
        title: "Modes"
        subtitle: "Type the character first, e.g. =2+2 or :smile."

        Repeater {
            model: [
                { key: "calc", prefix: "=", icon: "calculate", title: "Calculator", description: "Math and unit conversion (qalc). Enter copies the result." },
                { key: "run", prefix: ">", icon: "terminal", title: "Run a command", description: "Shift + Enter runs it in a terminal." },
                { key: "emoji", prefix: ":", icon: "mood", title: "Emoji", description: "Search by name, Enter copies." },
                { key: "projects", prefix: "~", icon: "folder_code", title: "Projects", description: "Git folders you've visited (zoxide), opened in the editor." },
                { key: "clipboard", prefix: "+", icon: "content_paste", title: "Clipboard history", description: "Text and images you copied." }
            ]
            SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.prefix + "  " + modelData.title
                description: modelData.description
                Switch {
                    checked: root.l[modelData.key]
                    onToggled: root.l[modelData.key] = !checked
                }
            }
        }
    }
}
