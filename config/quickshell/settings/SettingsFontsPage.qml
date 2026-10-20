import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Fonts & icons"
    subtitle: "Pick a font theme, or choose each font yourself. Changes apply right away."

    Process {
        id: folderTool
        property bool found: false
        running: true
        command: ["sh", "-c", "command -v papirus-folders"]
        onExited: code => found = code === 0
    }

    SettingsSection {
        title: "Font theme"
        subtitle: "Interface, heading and terminal fonts that go well together."

        Item {
            Layout.fillWidth: true
            implicitHeight: themeGrid.implicitHeight + 28

            GridLayout {
                id: themeGrid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 16) }
                columns: Math.max(1, Math.min(3, Math.floor((width + 10) / 170)))
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: FontThemes.themes

                    Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool selected: FontThemes.current === modelData.id

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardColumn.implicitHeight + 24
                        radius: Theme.round(14, width, height)
                        color: selected ? Qt.alpha(Theme.accent, 0.16) : cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.45)
                        border.width: selected ? 2 : 1
                        border.color: Theme.gradientAccent && (selected) ? "transparent" : selected ? Theme.accent : Qt.alpha(Theme.overlay, 0.25)
                        GradientBorder {
                            active: selected
                        }
                        Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                        ColumnLayout {
                            id: cardColumn
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(12, 14, parent.width, parent.height) }
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
                                Layout.preferredHeight: Math.ceil(fontMetricsVibe.height * 2)
                                text: card.modelData.vibe
                                color: Theme.subtext
                                font.family: card.modelData.font
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop

                                FontMetrics {
                                    id: fontMetricsVibe
                                    font.family: card.modelData.font
                                    font.pixelSize: 13
                                }
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
                                Layout.preferredHeight: 28
                                color: Theme.overlay
                                font.family: Theme.font
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: FontThemes.apply(card.modelData)
                        }
                        GlassRim {}
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

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.pad(16, 16)
            Layout.topMargin: 4
            columns: 10
            columnSpacing: 0
            rowSpacing: 8

            Repeater {
                model: {
                    const names = ["wifi", "bluetooth", "volume_up", "battery_android_frame_5", "notifications", "dark_mode", "music_note", "photo_camera", "folder", "settings"];
                    return names.map(name => ({ name, filled: false })).concat(names.map(name => ({ name, filled: true })));
                }
                Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 52
                    Rectangle {
                        anchors.centerIn: parent
                        width: 50
                        height: 50
                        radius: Theme.round(16, width, height)
                        color: Qt.alpha(Theme.base, 0.6)
                        Icon {
                            anchors.centerIn: parent
                            name: parent.parent.modelData.name
                            filled: parent.parent.modelData.filled
                            size: 28
                        }
                        GlassRim {}
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
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 16) }
            }
        }

        SettingsRow {
            visible: folderTool.found && Settings.appearance.iconTheme.startsWith("Papirus")
            icon: "folder"
            title: "Folder color follows accent"
            description: "Recolors Papirus folders to the closest papirus-folders color when the wallpaper changes. Asks for your password when the color changes."
            Switch {
                checked: Settings.appearance.folderAccent
                onToggled: {
                    Settings.appearance.folderAccent = !checked;
                    Settings.applyFolderColor();
                }
            }
        }
    }
}
