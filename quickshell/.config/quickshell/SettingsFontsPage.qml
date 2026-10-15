import QtQuick
import QtQuick.Layouts

// Settings app > Fonts & icons: font themes (FontThemes.qml), or the interface, display and
// terminal fonts one by one; text size; shell symbol style and weight; app icon theme.
SettingsPage {
    id: root
    title: "Fonts & icons"
    subtitle: "Pick a font theme, or choose each font yourself. Changes apply right away."

    SettingsSection {
        title: "Font theme"
        subtitle: "Interface, heading and terminal fonts that go well together."

        Item {
            Layout.fillWidth: true
            implicitHeight: themeGrid.implicitHeight + 28

            GridLayout {
                id: themeGrid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                columns: 3
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: FontThemes.themes

                    Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool selected: FontThemes.current === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardColumn.implicitHeight + 24
                        radius: 14
                        color: selected ? Qt.alpha(Theme.accent, 0.16) : cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.45)
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.accent : Qt.alpha(Theme.overlay, 0.25)
                        Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                        ColumnLayout {
                            id: cardColumn
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Aa"
                                    color: Theme.accent
                                    font.family: card.modelData.displayFont
                                    font.pixelSize: 30
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                                CheckBadge {
                                    visible: card.selected
                                    Layout.alignment: Qt.AlignTop
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.label
                                color: Theme.text
                                font.family: card.modelData.displayFont
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.vibe
                                color: Theme.subtext
                                font.family: card.modelData.font
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                text: "~/code $ ls -la"
                                color: Qt.alpha(Theme.text, 0.7)
                                font.family: card.modelData.monoFont
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: [card.modelData.font, card.modelData.displayFont, card.modelData.monoFont]
                                    .filter((f, i, a) => a.indexOf(f) === i).join(" · ")
                                color: Theme.overlay
                                font.family: Theme.font
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: FontThemes.apply(card.modelData)
                        }
                    }
                }
            }
        }

        SettingsRow {
            icon: "apps"
            title: "Use in apps"
            description: "GTK, Qt and KDE apps use the interface and terminal fonts too."
            Switch {
                checked: Settings.appearance.appFonts
                onToggled: {
                    Settings.appearance.appFonts = !checked;
                    Settings.applyFonts();
                }
            }
        }
    }

    SettingsSection {
        title: FontThemes.current === "custom" ? "Fonts · custom" : "Fonts"

        SettingsRow {
            icon: "text_fields"
            title: "Interface font"
            description: "Labels, menus and panels."
            below: true
            FontPicker {
                current: Settings.appearance.font
                onPicked: f => {
                    Settings.appearance.font = f;
                    if (Settings.appearance.appFonts)
                        Settings.applyFonts();
                }
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
            icon: "terminal"
            title: "Terminal font"
            description: "kitty, and GTK apps' monospace text with \"Use in apps\"."
            below: true
            FontPicker {
                current: Settings.appearance.monoFont
                monospace: true
                sample: "fn main() { println!(\"0O 1lI {}\", 42); } →"
                onPicked: f => {
                    Settings.appearance.monoFont = f;
                    Settings.applyFonts();
                }
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
        title: "Shell icons"
        subtitle: "Material Symbols, used across the bar, panels and this app."

        SettingsRow {
            icon: "interests"
            title: "Symbol style"
            SettingsSegmented {
                options: [
                    { value: "Rounded", label: "Rounded" },
                    { value: "Outlined", label: "Outlined" },
                    { value: "Sharp", label: "Sharp" }
                ]
                current: Settings.appearance.iconStyle
                onPicked: v => Settings.appearance.iconStyle = v
            }
        }

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

    SettingsSection {
        title: "App icons"
        subtitle: "The icon theme for apps, folders and the launcher. Follows light and dark mode when the theme has both."

        Item {
            Layout.fillWidth: true
            implicitHeight: picker.implicitHeight + 28

            IconThemePicker {
                id: picker
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            }
        }
    }
}
