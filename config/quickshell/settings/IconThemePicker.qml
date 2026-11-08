import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    property var themes: []
    property bool loading: true
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
        columns: width < 380 ? 1 : 2
        columnSpacing: 10
        rowSpacing: 10

        Repeater {
            model: root.themes

            SettingsStyleCard {
                id: card
                required property var modelData
                selected: (root.pending || Settings.appearance.iconTheme) === modelData.family
                inset: 12
                contentSpacing: 10
                onClicked: root.pending = card.modelData.family === Settings.appearance.iconTheme ? "" : card.modelData.family

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
        }
    }

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
