import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Dock"
    subtitle: "Pinned apps and the apps you have open, on a screen edge of their own."

    readonly property var dk: Settings.dock
    readonly property var allApps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay && !Dock.pinned.includes(e.id))
        .map(e => ({ id: e.id, name: e.name, icon: e.icon }))
        .sort((a, b) => a.name.localeCompare(b.name))
    readonly property var swatches: ["", "#ffffff", "#89b4fa", "#a6e3a1", "#f9e2af", "#fab387", "#f38ba8", "#cba6f7"]
    readonly property var swatchNames: ({ "": "Follow the theme", "#ffffff": "White", "#89b4fa": "Blue", "#a6e3a1": "Green", "#f9e2af": "Yellow", "#fab387": "Orange", "#f38ba8": "Red", "#cba6f7": "Purple" })

    SettingsSection {
        title: "Visibility"

        SettingsRow {
            icon: "dock_to_bottom"
            title: "Show the dock"
            description: "Super + D hides it or brings it back for now."
            Switch {
                checked: root.dk.enabled
                onToggled: root.dk.enabled = !checked
            }
        }
        SettingsRow {
            icon: "visibility"
            title: "Hiding"
            description: Dock.mode === "always" ? "Always on screen. Windows make room for it."
                : Dock.mode === "autohide" ? "Hidden until you rest the pointer on the screen edge."
                : "Hides only while a window touches it."
            SettingsSegmented {
                options: [
                    { value: "always", label: "Always" },
                    { value: "autohide", label: "Auto-hide" },
                    { value: "intellihide", label: "Intellihide" }
                ]
                current: Dock.mode
                onPicked: v => root.dk.mode = v
            }
        }
        SettingsRow {
            icon: "monitor"
            title: "Screens"
            description: "Every screen shows all of your open apps."
            SettingsSegmented {
                options: [
                    { value: "all", label: "All screens" },
                    { value: "main", label: "Main only" }
                ]
                current: root.dk.screens === "main" ? "main" : "all"
                onPicked: v => root.dk.screens = v
            }
        }
    }

    SettingsSection {
        title: "Position"

        SettingsRow {
            icon: "border_bottom"
            title: "Screen edge"
            description: "The bar's edge (" + Theme.barPosition + ") is left out."
            SettingsSegmented {
                options: [
                    { value: "bottom", label: "Bottom", icon: "vertical_align_bottom" },
                    { value: "left", label: "Left", icon: "align_horizontal_left" },
                    { value: "right", label: "Right", icon: "align_horizontal_right" }
                ].filter(o => o.value !== Theme.barPosition)
                current: Dock.edge
                onPicked: v => root.dk.position = v
            }
        }
    }

    SettingsSection {
        title: "Look"

        SettingsRow {
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
                current: Dock.glassOptions.includes(root.dk.glass) ? root.dk.glass : "system"
                onPicked: v => root.dk.glass = v
            }
        }
        SettingsRow {
            icon: "photo_size_select_large"
            title: "Icon size"
            SettingsSlider {
                from: 32; to: 80; stepSize: 2
                value: Dock.iconSize
                suffix: " px"
                onMoved: v => root.dk.iconSize = v
            }
        }
        SettingsRow {
            icon: "zoom_in"
            title: "Magnify on hover"
            description: "Icons near the pointer grow."
            Switch {
                checked: root.dk.magnify
                onToggled: root.dk.magnify = !checked
            }
        }
        SettingsRow {
            visible: root.dk.magnify
            icon: "zoom_out_map"
            title: "Magnified size"
            SettingsSlider {
                from: 120; to: 220; stepSize: 10
                value: Math.round(root.dk.magnifyScale * 100)
                suffix: "%"
                onMoved: v => root.dk.magnifyScale = v / 100
            }
        }
        SettingsRow {
            icon: "fiber_manual_record"
            title: "Running indicator"
            description: "How an open app is marked."
            SettingsSegmented {
                options: [
                    { value: "dot", label: "Dot" },
                    { value: "line", label: "Line" },
                    { value: "ring", label: "Ring" },
                    { value: "pill", label: "Pill" },
                    { value: "none", label: "None" }
                ]
                current: Dock.indicator
                onPicked: v => root.dk.indicator = v
            }
        }
        SettingsRow {
            visible: Dock.indicator === "dot" || Dock.indicator === "line"
            icon: "more_horiz"
            title: "One mark per window"
            description: "Up to three."
            Switch {
                checked: root.dk.indicatorCount
                onToggled: root.dk.indicatorCount = !checked
            }
        }
        SettingsRow {
            visible: Dock.indicator !== "none"
            icon: "palette"
            title: "Indicator color"
            description: root.dk.indicatorColor ? root.dk.indicatorColor : "Follows the theme."
            Row {
                spacing: 6

                Repeater {
                    model: root.swatches

                    Rectangle {
                        id: swatch
                        required property string modelData
                        readonly property bool selected: (root.dk.indicatorColor ?? "") === modelData
                        width: 26
                        height: 26
                        radius: 13
                        color: modelData || Dock.indicatorColor
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.text : Qt.alpha(Theme.text, 0.2)

                        Icon {
                            visible: swatch.modelData === ""
                            anchors.centerIn: parent
                            name: "auto_awesome"
                            size: 14
                            color: Theme.base
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dk.indicatorColor = swatch.modelData
                        }
                        Tooltip {
                            text: root.swatchNames[swatch.modelData] ?? swatch.modelData
                        }
                    }
                }
            }
        }
    }

    SettingsSection {
        title: "Behaviour"

        SettingsRow {
            icon: "apps"
            title: "Open apps that aren't pinned"
            description: "Shown after a divider, in the order you opened them."
            Switch {
                checked: root.dk.showRunning
                onToggled: root.dk.showRunning = !checked
            }
        }
        SettingsRow {
            icon: "stack"
            title: "Apps on special workspaces"
            description: "Scratchpads, the drop-down terminal and background apps. Clicking one opens its workspace."
            Switch {
                checked: root.dk.showSpecial
                onToggled: root.dk.showSpecial = !checked
            }
        }
        SettingsRow {
            icon: "preview"
            title: "Window previews after"
            description: "How long to hover an icon."
            SettingsSegmented {
                options: [0, 200, 400, 700, 1000].map(ms => ({ value: ms, label: ms === 0 ? "At once" : ms >= 1000 ? ms / 1000 + " s" : ms + " ms" }))
                current: root.dk.previewDelay
                onPicked: v => root.dk.previewDelay = v
            }
        }
        SettingsRow {
            icon: "motion_play"
            title: "Pulse while opening"
            description: "Until the app's first window shows up."
            Switch {
                checked: root.dk.launchPulse
                onToggled: root.dk.launchPulse = !checked
            }
        }
        SettingsRow {
            icon: "grid_view"
            title: "Launcher button"
            description: "At the start of the dock. Opens the app launcher."
            Switch {
                checked: root.dk.launcherButton
                onToggled: root.dk.launcherButton = !checked
            }
        }
    }

    SettingsSection {
        title: "Pinned apps"
        subtitle: "You can also drag icons in the dock to reorder them, or drag one off the dock to remove it."

        Repeater {
            model: Dock.pinned

            SettingsRow {
                id: pinRow
                required property string modelData
                required property int index
                readonly property var entry: DesktopEntries.byId(modelData)
                appIcon: entry?.icon || "application-x-executable"
                title: entry?.name ?? modelData
                description: entry ? (Dock.keybindFor(modelData) || modelData) : "Not installed"

                Row {
                    spacing: 8
                    Pill {
                        icon: "arrow_upward"
                        tip: "Move up"
                        implicitHeight: 30
                        opacity: pinRow.index > 0 ? 1 : 0.35
                        onClicked: if (pinRow.index > 0) Dock.movePin(pinRow.index, pinRow.index - 1)
                    }
                    Pill {
                        icon: "arrow_downward"
                        tip: "Move down"
                        implicitHeight: 30
                        opacity: pinRow.index < Dock.pinned.length - 1 ? 1 : 0.35
                        onClicked: if (pinRow.index < Dock.pinned.length - 1) Dock.movePin(pinRow.index, pinRow.index + 1)
                    }
                    Pill {
                        icon: "delete"
                        tip: "Unpin"
                        implicitHeight: 30
                        onClicked: Dock.unpin(pinRow.modelData)
                    }
                }
            }
        }

        Label {
            visible: Dock.pinned.length === 0
            Layout.fillWidth: true
            Layout.margins: Theme.pad(18, 16)
            text: "Nothing pinned. Add an app below, or right-click an open app in the dock."
            color: Theme.subtext
        }

        SettingsRow {
            icon: "add"
            title: "Pin an app"
            below: true
            AppPicker {
                options: root.allApps
                placeholder: "Choose an app…"
                onPicked: id => Dock.pin(id)
            }
        }
    }
}
