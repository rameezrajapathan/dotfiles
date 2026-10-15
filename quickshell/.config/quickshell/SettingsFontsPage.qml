import QtQuick
import QtQuick.Layouts

// Settings app > Fonts & icons: interface and display fonts, text size, icon weight.
SettingsPage {
    id: root
    title: "Fonts & icons"
    subtitle: "Every installed font is listed. Changes apply to the whole shell right away."

    SettingsSection {
        title: "Fonts"

        SettingsRow {
            icon: "text_fields"
            title: "Interface font"
            description: "Labels, menus and panels."
            below: true
            FontPicker {
                current: Settings.appearance.font
                onPicked: f => Settings.appearance.font = f
            }
        }

        SettingsRow {
            icon: "format_size"
            title: "Display font"
            description: "Page titles and the lock screen clock."
            below: true
            FontPicker {
                current: Settings.appearance.displayFont
                sample: "12:45 · Good morning"
                onPicked: f => Settings.appearance.displayFont = f
            }
        }

        SettingsRow {
            icon: "format_line_spacing"
            title: "Text size"
            SettingsSlider {
                from: 11
                to: 17
                value: Settings.appearance.fontSize
                suffix: " px"
                onMoved: v => Settings.appearance.fontSize = v
            }
        }
    }

    SettingsSection {
        title: "Icons"
        subtitle: "Material Symbols Rounded, used across the shell."

        SettingsRow {
            icon: "line_weight"
            title: "Icon weight"
            SettingsSegmented {
                options: [
                    { value: 300, label: "Light" },
                    { value: 400, label: "Regular" },
                    { value: 500, label: "Medium" },
                    { value: 600, label: "Bold" }
                ]
                current: Settings.appearance.iconWeight
                onPicked: v => Settings.appearance.iconWeight = v
            }
        }

        // Preview
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 4
            spacing: 0

            Repeater {
                model: ["wifi", "bluetooth", "volume_up", "battery_android_frame_5", "notifications", "dark_mode", "music_note", "photo_camera", "folder", "settings"]
                Item {
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: 44
                    Rectangle {
                        anchors.centerIn: parent
                        width: 42
                        height: 42
                        radius: 13
                        color: Qt.alpha(Theme.base, 0.6)
                        Icon { anchors.centerIn: parent; name: parent.parent.modelData; size: 22 }
                    }
                }
            }
        }
    }
}
