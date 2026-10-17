import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Effects"
    subtitle: "Blur, transparency and motion."

    onShownChanged: if (shown) Hypr.refresh()

    function changed(keys) {
        return keys.some(k => Hypr.changed(k));
    }

    SettingsSection {
        title: "Blur"
        readonly property var keys: ["decoration.blur.enabled", "decoration.blur.size", "decoration.blur.passes", "decoration.blur.vibrancy"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "blur_on"
            title: "Blur behind windows"
            description: "Also used by the bar and panels."
            Switch {
                checked: Hypr.value("decoration.blur.enabled") ?? false
                onToggled: Hypr.set("decoration.blur.enabled", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "blur_medium"
            title: "Strength"
            SettingsSlider {
                from: 1; to: 16
                value: Hypr.value("decoration.blur.size") ?? 1
                onMoved: v => Hypr.set("decoration.blur.size", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "layers"
            title: "Passes"
            description: "More passes look smoother and cost more GPU."
            SettingsSlider {
                from: 1; to: 4
                value: Hypr.value("decoration.blur.passes") ?? 1
                onMoved: v => Hypr.set("decoration.blur.passes", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "auto_awesome"
            title: "Vibrancy"
            description: "How much color the blur keeps."
            SettingsSlider {
                from: 0; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.blur.vibrancy") ?? 0) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.blur.vibrancy", v / 100)
            }
        }
    }

    SettingsSection {
        title: "Transparency"
        readonly property var keys: ["decoration.active_opacity", "decoration.inactive_opacity", "decoration.dim_inactive", "decoration.dim_strength"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "select_window"
            title: "Focused window"
            SettingsSlider {
                from: 50; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.active_opacity") ?? 1) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.active_opacity", v / 100)
            }
        }
        SettingsRow {
            icon: "filter_none"
            title: "Other windows"
            SettingsSlider {
                from: 50; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.inactive_opacity") ?? 1) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.inactive_opacity", v / 100)
            }
        }
        SettingsRow {
            icon: "brightness_4"
            title: "Dim other windows"
            Switch {
                checked: Hypr.value("decoration.dim_inactive") ?? false
                onToggled: Hypr.set("decoration.dim_inactive", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.dim_inactive") ?? false
            icon: "brightness_medium"
            title: "Dim amount"
            SettingsSlider {
                from: 5; to: 80; stepSize: 5
                value: Math.round((Hypr.value("decoration.dim_strength") ?? 0.5) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.dim_strength", v / 100)
            }
        }
    }

    SettingsSection {
        title: "Shadows"
        readonly property var keys: ["decoration.shadow.enabled", "decoration.shadow.range"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "shadow"
            title: "Window shadows"
            Switch {
                checked: Hypr.value("decoration.shadow.enabled") ?? false
                onToggled: Hypr.set("decoration.shadow.enabled", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.shadow.enabled") ?? false
            icon: "contrast_square"
            title: "Shadow size"
            SettingsSlider {
                from: 2; to: 40
                value: Hypr.value("decoration.shadow.range") ?? 4
                suffix: " px"
                onMoved: v => Hypr.set("decoration.shadow.range", v)
            }
        }
    }

    SettingsSection {
        title: "Panels"
        subtitle: "How the control center, calendar, weather, launcher and the other panels come out of the bar."
        canReset: Settings.appearance.panelAnimation !== "slide" || Settings.appearance.panelSpeed !== 1
        onReset: {
            Settings.appearance.panelAnimation = "slide";
            Settings.appearance.panelSpeed = 1;
        }

        SettingsRow {
            visible: Theme.reduceMotion
            icon: "motion_photos_off"
            title: "Reduce motion is on"
            description: "Panels open instantly, whichever style is picked (Settings > Accessibility)."
            Pill {
                text: "Turn off"
                onClicked: {
                    Settings.accessibility.reduceMotion = false;
                    Hypr.set("animations.enabled", true);
                    Quickshell.execDetached(["sh", "-c", "sleep 0.6; exec \"$HOME/.config/hypr/scripts/accessibility.sh\""]);
                }
            }
        }
        SettingsRow {
            icon: "animation"
            title: "Open and close"
            description: PanelMotion.info(PanelMotion.style).description
            below: true

            GridLayout {
                columns: Math.max(1, Math.min(3, Math.floor((width + 10) / 170)))
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: PanelMotion.styles

                    Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool selected: PanelMotion.style === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: cardColumn.implicitHeight + 16
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
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(8, 14, parent.width, parent.height) }
                            spacing: 8

                            PanelMotionPreview {
                                Layout.fillWidth: true
                                style: card.modelData.id
                                running: root.shown && !Theme.reduceMotion
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
                            onClicked: Settings.appearance.panelAnimation = card.modelData.id
                        }
                        GlassRim {}
                    }
                }
            }
        }
        SettingsRow {
            icon: "speed"
            title: "Speed"
            description: "Faster to the right."
            SettingsSlider {
                from: 50
                to: 200
                stepSize: 10
                value: Math.round(Settings.appearance.panelSpeed * 100)
                suffix: "%"
                onMoved: v => Settings.appearance.panelSpeed = Math.round(v) / 100
            }
        }
        SettingsRow {
            icon: "play_circle"
            title: "Try it"
            description: "Opens the control center with this animation."
            Pill {
                text: "Open"
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "toggle", ""])
            }
        }
    }

    SettingsSection {
        title: "Animations"
        readonly property var keys: ["animations.enabled", "pikadots.animationSpeed", "pikadots.workspaceStyle"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "animation"
            title: "Animations"
            Switch {
                checked: Hypr.value("animations.enabled") ?? true
                onToggled: Hypr.set("animations.enabled", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "speed"
            title: "Speed"
            SettingsSegmented {
                options: [
                    { value: 0.6, label: "Fast" },
                    { value: 1, label: "Normal" },
                    { value: 1.6, label: "Relaxed" }
                ]
                current: Hypr.value("pikadots.animationSpeed")
                onPicked: v => Hypr.set("pikadots.animationSpeed", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "swap_horiz"
            title: "Workspace switch"
            SettingsSegmented {
                options: [
                    { value: "slide", label: "Slide" },
                    { value: "slidevert", label: "Vertical" },
                    { value: "slidefade 20%", label: "Slide + fade" },
                    { value: "fade", label: "Fade" }
                ]
                current: Hypr.value("pikadots.workspaceStyle")
                onPicked: v => Hypr.set("pikadots.workspaceStyle", v)
            }
        }
    }
}
