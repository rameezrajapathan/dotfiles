import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.overlays
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Launcher"
    subtitle: "The app grid (Super + A) and its modes."

    readonly property var l: Settings.launcher
    readonly property string style: ["bar", "dock", "center", "fullscreen", "spotlight"].includes(l.style) ? l.style : "bar"
    readonly property var styles: [
        { id: "bar", label: "Attached to bar", description: "Grows out of the bar.", r: [0.28, 0.1, 0.44, 0.46] },
        { id: "dock", label: "Attached to dock", description: "Grows out of the dock, which comes in first.", r: [0.28, 0.3, 0.44, 0.44] },
        { id: "center", label: "Centered", description: "A card in the middle of the screen.", r: [0.26, 0.24, 0.48, 0.52] },
        { id: "fullscreen", label: "Fullscreen", description: "Big icons over the whole screen, with categories.", r: [0, 0, 1, 1] },
        { id: "spotlight", label: "Spotlight", description: "Just a search field. Results show as you type.", r: [0.24, 0.2, 0.52, 0.1] }
    ]

    SettingsSection {
        title: "Style"
        subtitle: "Attached to dock opens centered when the dock is off or hidden by a fullscreen window."

        Flow {
            Layout.fillWidth: true
            Layout.margins: Theme.pad(14, 16)
            spacing: 10

            Repeater {
                model: root.styles

                Rectangle {
                    id: styleCard
                    required property var modelData
                    readonly property bool selected: root.style === modelData.id
                    width: 168
                    height: 150
                    radius: Theme.round(14, width, height)
                    color: selected ? Qt.alpha(Theme.accent, 0.16) : styleMouse.containsMouse ? Qt.alpha(Theme.overlay, 0.25) : Qt.alpha(Theme.base, 0.6)
                    border.width: selected ? 2 : 0
                    border.color: Theme.gradientAccent ? "transparent" : Theme.accent
                    GlassRim {}

                    Rectangle {
                        id: screenBox
                        x: 10
                        y: 10
                        width: parent.width - 20
                        height: 88
                        radius: Theme.round(8, width, height)
                        color: Qt.alpha(Theme.overlay, 0.28)
                        clip: true

                        Rectangle {
                            visible: styleCard.modelData.id === "fullscreen"
                            anchors.fill: parent
                            color: Qt.alpha(Theme.base, 0.7)
                        }

                        Rectangle {
                            x: parent.width * 0.3
                            y: 3
                            width: parent.width * 0.4
                            height: 7
                            radius: 3.5
                            color: Theme.text
                            opacity: 0.55
                        }

                        Rectangle {
                            visible: Dock.enabled || styleCard.modelData.id === "dock"
                            x: parent.width * 0.36
                            y: parent.height - 12
                            width: parent.width * 0.28
                            height: 8
                            radius: 4
                            color: Theme.text
                            opacity: 0.55
                        }

                        Rectangle {
                            readonly property var r: styleCard.modelData.r
                            readonly property bool full: styleCard.modelData.id === "fullscreen"
                            x: full ? parent.width * 0.12 : parent.width * r[0]
                            y: full ? parent.height * 0.18 : parent.height * r[1]
                            width: full ? parent.width * 0.76 : parent.width * r[2]
                            height: full ? parent.height * 0.62 : parent.height * r[3]
                            radius: full ? 0 : Theme.round(5, width, height)
                            color: full ? "transparent" : Theme.accent
                            opacity: full ? 1 : 0.85

                            Grid {
                                visible: parent.full
                                anchors.centerIn: parent
                                columns: 6
                                spacing: 7
                                Repeater {
                                    model: 18
                                    Rectangle {
                                        width: 9
                                        height: 9
                                        radius: 3
                                        color: Theme.accent
                                    }
                                }
                            }
                        }

                        Column {
                            visible: styleCard.modelData.id === "spotlight"
                            x: parent.width * 0.24
                            y: parent.height * 0.34
                            spacing: 3
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: screenBox.width * 0.52 * (1 - index * 0.15)
                                    height: 4
                                    radius: 2
                                    color: Theme.text
                                    opacity: 0.35
                                }
                            }
                        }
                    }

                    Column {
                        x: 12
                        y: screenBox.y + screenBox.height + 8
                        width: parent.width - 24
                        spacing: 1

                        Label {
                            width: parent.width
                            text: styleCard.modelData.label
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            width: parent.width
                            text: styleCard.modelData.description
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 3
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: styleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.l.style = styleCard.modelData.id
                    }

                    Tooltip {
                        text: styleCard.modelData.description
                    }
                }
            }
        }

        SettingsRow {
            icon: "play_arrow"
            title: "Try it"
            description: "Opens the launcher in this style. Super + A and the dock's launcher button use it too."
            Pill {
                icon: "open_in_new"
                tip: "Open the launcher"
                tipKeys: "Super + A"
                implicitHeight: 30
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
            }
        }
    }

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
                tip: "Forget usage"
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

    Timer {
        id: watchTimer
        interval: 800
        onTriggered: Quickshell.execDetached([root.clipScript, "watch"])
    }
    readonly property string clipScript: Quickshell.env("HOME") + "/.config/hypr/scripts/clipboard.sh"
    property bool hasPersist: false
    Process {
        running: true
        command: ["sh", "-c", "command -v wl-clip-persist"]
        onExited: code => root.hasPersist = code === 0
    }

    SettingsSection {
        title: "Clipboard"
        subtitle: "Super + V. Ctrl + P pins a clip; pins stay when the history is cleared."

        SettingsRow {
            icon: "history"
            title: "History size"
            description: "Older entries are dropped."
            SettingsSlider {
                from: 100; to: 2000; stepSize: 50
                value: root.l.clipboardSize
                onMoved: v => {
                    root.l.clipboardSize = v;
                    watchTimer.restart();
                }
            }
        }
        SettingsRow {
            icon: "content_paste_go"
            title: "Keep copied text when the app closes"
            description: root.hasPersist ? "Otherwise what you copied is gone once its window closes."
                : "Needs wl-clip-persist (on Arch: sudo pacman -S wl-clip-persist)."
            enabled: root.hasPersist
            opacity: enabled ? 1 : 0.5
            Switch {
                checked: root.l.clipboardPersist
                onToggled: {
                    root.l.clipboardPersist = !checked;
                    watchTimer.restart();
                }
            }
        }
        SettingsRow {
            icon: "delete_sweep"
            title: "Clear history"
            description: "Pinned clips stay."
            Pill {
                icon: "delete"
                onClicked: Quickshell.execDetached([root.clipScript, "wipe"])
            }
        }
    }
}
