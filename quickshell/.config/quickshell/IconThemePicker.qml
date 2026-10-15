import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// Installed app icon themes (hypr/scripts/icon-themes.py), one card each with sample icons. Picking
// one asks to apply it: the shell restarts to load it (Settings.applyIconTheme), then reopens
// this page.
ColumnLayout {
    id: root
    property var themes: []
    property bool loading: true
    // Picked but not applied yet
    property string pending: ""

    spacing: 12

    Process {
        running: true
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/icon-themes.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themes = JSON.parse(text);
                } catch (e) {
                    root.themes = [];
                }
                root.loading = false;
            }
        }
    }

    Label {
        visible: root.loading
        text: "Looking for icon themes…"
        color: Theme.subtext
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            model: root.themes

            Rectangle {
                id: card
                required property var modelData
                readonly property bool selected: (root.pending || Settings.appearance.iconTheme) === modelData.family

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: cardColumn.implicitHeight + 24
                radius: 14
                color: selected ? Qt.alpha(Theme.accent, 0.16) : cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.9) : Qt.alpha(Theme.base, 0.45)
                border.width: selected ? 2 : 1
                border.color: selected ? Theme.accent : Qt.alpha(Theme.overlay, 0.25)
                Behavior on color { ColorAnimation { duration: 120 } }

                ColumnLayout {
                    id: cardColumn
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.family
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            visible: card.modelData.variants.length > 1
                            text: card.modelData.variants.length > 2 ? "light · dark" : "+ dark"
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 3
                        }
                        CheckBadge { visible: card.selected }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Repeater {
                            model: card.modelData.samples
                            Item {
                                required property string modelData
                                Layout.fillWidth: true
                                implicitHeight: 34
                                Image {
                                    anchors.centerIn: parent
                                    width: 32
                                    height: 32
                                    source: "file://" + parent.modelData
                                    sourceSize: Qt.size(64, 64)
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                    // Symbolic icons are drawn in dark grey; show them in the text color
                                    layer.enabled: parent.modelData.includes("symbolic")
                                    layer.effect: MultiEffect {
                                        colorization: 1
                                        colorizationColor: Theme.text
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pending = card.modelData.family === Settings.appearance.iconTheme ? "" : card.modelData.family
                }
            }
        }
    }

    // Applying restarts the shell, so it waits for a click
    RowLayout {
        visible: root.pending !== ""
        Layout.fillWidth: true
        spacing: 10

        Icon { name: "restart_alt"; size: 18; color: Theme.accent }
        Label {
            Layout.fillWidth: true
            text: "The shell restarts for a moment to load " + root.pending + "."
            color: Theme.subtext
            wrapMode: Text.WordWrap
        }
        Pill {
            text: "Cancel"
            implicitHeight: 30
            onClicked: root.pending = ""
        }
        Pill {
            text: "Apply"
            active: true
            implicitHeight: 30
            onClicked: {
                Settings.appearance.iconTheme = root.pending;
                Settings.applyIconTheme();
            }
        }
    }

    Label {
        visible: !root.loading
        Layout.fillWidth: true
        text: "More themes: put them in ~/.local/share/icons and reopen this page."
        color: Theme.overlay
        font.pixelSize: Theme.fontSize - 2
        wrapMode: Text.WordWrap
    }
}
