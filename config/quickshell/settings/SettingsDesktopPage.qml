import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Desktop"
    subtitle: "Desktop widgets that live on your wallpaper, and the menu you get from a right click on it."

    readonly property var dt: Settings.desktop
    readonly property string screenName: Desktop.focusedScreen
    readonly property int count: Desktop.layout(screenName).length

    SettingsSection {
        title: "Desktop widgets"

        SettingsSwitchRow {
            icon: "widgets"
            title: "Show desktop widgets"
            description: "They sit behind your windows. Super + H brings them forward, or swipe down with four fingers."
            target: root.dt
            key: "enabled"
        }
        SettingsRow {
            visible: root.dt.enabled
            icon: "edit"
            title: "Arrange desktop widgets"
            description: root.count === 0 ? "This screen has none yet." : root.count === 1 ? "One desktop widget on this screen." : root.count + " desktop widgets on this screen."
            RowLayout {
                spacing: 8
                Pill {
                    visible: root.count === 0
                    text: "Add starter widgets"
                    implicitHeight: 32
                    onClicked: Desktop.addStarter(root.screenName)
                }
                Pill {
                    text: "Edit widgets"
                    active: true
                    implicitHeight: 32
                    onClicked: Desktop.edit(true)
                }
            }
        }
        SettingsRow {
            visible: root.dt.enabled
            icon: "blur_on"
            title: "Glass"
            description: "System follows Appearance."
            SettingsSegmented {
                options: [
                    { value: "system", label: "System" },
                    { value: "frosted", label: "Frosted" },
                    { value: "clear", label: "Clear" },
                    { value: "solid", label: "Solid" }
                ]
                current: Dock.glassOptions.includes(root.dt.glass) ? root.dt.glass : "system"
                onPicked: v => root.dt.glass = v
            }
        }
    }

    SettingsSection {
        title: "Desktop menu"

        SettingsSwitchRow {
            icon: "right_click"
            title: "Right-click menu"
            description: "Change the wallpaper, edit widgets, open a terminal or settings from the empty desktop."
            target: root.dt
            key: "menu"
        }
    }

    SettingsSection {
        title: "Photo frame"
        visible: root.dt.enabled

        SettingsRow {
            icon: "folder"
            title: "Folder"
            description: "Pictures shown by the photo frame widget. Middle click a frame to skip ahead."
            SettingsTextField {
                implicitWidth: 280
                text: root.dt.photos
                placeholder: Desktop.photoFolder.replace(Quickshell.env("HOME"), "~")
                onAccepted: t => root.dt.photos = t.trim().replace(/^~(?=\/|$)/, Quickshell.env("HOME"))
            }
        }
        SettingsRow {
            icon: "timer"
            title: "Next picture every"
            SettingsSlider {
                from: 1; to: 60; stepSize: 1
                value: root.dt.photoMinutes
                suffix: " min"
                onMoved: v => root.dt.photoMinutes = v
            }
        }
    }

    SettingsSection {
        title: "Notes and to-dos"

        SettingsRow {
            icon: "description"
            title: "Where they're kept"
            description: "Each note is a Markdown file in ~/.local/state/pikadots/notes, the to-do list is ~/.local/state/pikadots/todo.json. Nothing is synced."
            Pill {
                text: "Open folder"
                implicitHeight: 32
                onClicked: Qt.openUrlExternally("file://" + Desktop.notesDir)
            }
        }
    }
}
