import QtQuick
import QtQuick.Layouts

// Settings app > Bar: a ready-made style or a custom one: layout (one pill, islands or a full
// bar), size, spacing, roundness, border and the items in each section; plus the clock format.
SettingsPage {
    id: root
    title: "Bar"
    subtitle: "Pick a style, or change anything below to make your own."

    SettingsSection {
        title: "Style"

        SettingsRow {
            icon: "style"
            title: "Bar style"
            description: BarStyles.current === "custom" ? "Custom: your own setup." : (BarStyles.presets.find(p => p.id === BarStyles.current)?.description ?? "")
            below: true

            GridLayout {
                columns: 3
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: BarStyles.presets.concat([{
                        id: "custom", label: "Custom", icon: "tune",
                        description: Settings.bar.custom || BarStyles.current === "custom" ? "Your own setup" : "Change anything below"
                    }])

                    Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool selected: BarStyles.current === modelData.id
                        // Custom shows the current setup when it's in use, else the saved one
                        readonly property var config: modelData.id !== "custom" ? modelData
                            : selected ? BarStyles.snapshot()
                            : Settings.bar.custom ?? BarStyles.snapshot()

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardColumn.implicitHeight + 16
                        radius: 14
                        color: selected ? Qt.alpha(Theme.accent, 0.16) : cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.45)
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.accent : Qt.alpha(Theme.overlay, 0.25)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            id: cardColumn
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 58
                                radius: 9
                                color: "transparent"
                                clip: true
                                BarPreview {
                                    anchors.fill: parent
                                    config: card.config
                                }
                            }
                            RowLayout {
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                spacing: 6
                                Icon {
                                    name: card.modelData.icon
                                    size: 17
                                    filled: card.selected
                                    color: Theme.accent
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: card.modelData.label
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                CheckBadge {
                                    visible: card.selected
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarStyles.apply(card.modelData.id)
                        }
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Shape"

        SettingsRow {
            icon: "view_day"
            title: "Layout"
            description: "One pill, a pill per section, or one bar across the screen."
            SettingsSegmented {
                options: [
                    { value: "pill", label: "Pill", icon: "radio_button_unchecked" },
                    { value: "islands", label: "Islands", icon: "bubble_chart" },
                    { value: "full", label: "Full width", icon: "width_full" }
                ]
                current: Settings.bar.layout
                onPicked: v => Settings.bar.layout = v
            }
        }
        SettingsRow {
            icon: "height"
            title: "Height"
            description: "Room the bar takes at the top of the screen."
            SettingsSlider {
                from: 28
                to: 60
                stepSize: 2
                value: Settings.bar.height
                suffix: " px"
                onMoved: v => Settings.bar.height = v
            }
        }
        SettingsRow {
            icon: "vertical_align_top"
            title: "Space above"
            description: "0 sticks the bar to the screen's edge."
            SettingsSlider {
                from: 0
                to: 12
                value: Settings.bar.gap
                suffix: " px"
                onMoved: v => Settings.bar.gap = v
            }
        }
        SettingsRow {
            visible: Settings.bar.layout !== "pill"
            icon: "settings_ethernet"
            title: "Space at the sides"
            SettingsSlider {
                from: 0
                to: 40
                stepSize: 2
                value: Settings.bar.sideGap
                suffix: " px"
                onMoved: v => Settings.bar.sideGap = v
            }
        }
        SettingsRow {
            icon: "rounded_corner"
            title: "Roundness"
            description: "Square corners to fully round ends."
            SettingsSlider {
                from: 0
                to: 100
                stepSize: 5
                value: Math.round(Settings.bar.roundness * 100)
                suffix: "%"
                onMoved: v => Settings.bar.roundness = Math.round(v) / 100
            }
        }
        SettingsRow {
            icon: "border_style"
            title: "Outline"
            description: "A thin line around the bar's shapes."
            Switch {
                checked: Settings.bar.border
                onToggled: Settings.bar.border = !checked
            }
        }
    }

    SettingsSection {
        title: "Items"
        subtitle: "Click a section, then add items to it. Hover an item to move or remove it."

        Item {
            Layout.fillWidth: true
            implicitHeight: editor.implicitHeight + 28

            BarModuleEditor {
                id: editor
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            }
        }
    }

    SettingsSection {
        title: "Clock"

        SettingsRow {
            icon: "schedule"
            title: "24-hour time"
            Switch {
                checked: Settings.bar.clock24
                onToggled: Settings.bar.clock24 = !checked
            }
        }
        SettingsRow {
            icon: "timer"
            title: "Show seconds"
            Switch {
                checked: Settings.bar.seconds
                onToggled: Settings.bar.seconds = !checked
            }
        }
        SettingsRow {
            icon: "graphic_eq"
            title: "Music spectrum"
            description: "Replaces the clock with moving bars while music plays."
            Switch {
                checked: Settings.bar.musicBars
                onToggled: Settings.bar.musicBars = !checked
            }
        }
    }
}
