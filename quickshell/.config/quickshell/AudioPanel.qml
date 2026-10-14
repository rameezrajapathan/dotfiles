import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar: output/input device pickers with volume sliders, plus per-app volume.
// A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.isSink && n.isStream)

    function toggle() {
        visible = !visible;
    }

    function deviceName(node) {
        return node.description || node.nickname || node.name;
    }

    function streamName(node) {
        const p = node.properties;
        return p["application.name"] || node.description || node.name;
    }

    PwObjectTracker { objects: root.nodes }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-audio"
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 380
        height: content.implicitHeight + 28
        color: Theme.base
        radius: 10
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4

                Label {
                    Layout.fillWidth: true
                    text: "Audio"
                    font.bold: true
                }
                Pill {
                    text: "settings"
                    onClicked: {
                        root.visible = false;
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            // Output
            SectionLabel { text: "Output" }
            VolumeRow {
                node: Pipewire.defaultAudioSink
                icon: muted ? "󰝟" : "󰕾"
            }
            Repeater {
                model: root.sinks

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "󰓃"
                    title: root.deviceName(modelData)
                    highlighted: modelData === Pipewire.defaultAudioSink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            // Input
            SectionLabel { text: "Input" }
            VolumeRow {
                node: Pipewire.defaultAudioSource
                icon: muted ? "󰍭" : "󰍬"
            }
            Repeater {
                model: root.sources

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "󰍬"
                    title: root.deviceName(modelData)
                    highlighted: modelData === Pipewire.defaultAudioSource
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

            // Apps
            SectionLabel {
                text: "Apps"
                visible: root.streams.length > 0
            }
            Repeater {
                model: root.streams

                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.leftMargin: 8
                        Layout.fillWidth: true
                        text: root.streamName(modelData)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                    VolumeRow {
                        node: modelData
                        icon: muted ? "󰝟" : "󰕾"
                    }
                }
            }
        }
    }

    component SectionLabel: Label {
        Layout.topMargin: 6
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }

    // Mute toggle, slider and percentage for one node.
    component VolumeRow: RowLayout {
        id: row
        property var node
        property string icon
        readonly property bool muted: node?.audio?.muted ?? true
        readonly property real volume: node?.audio?.volume ?? 0

        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        implicitHeight: 32
        spacing: 10
        visible: node !== null

        Label {
            text: row.icon
            color: row.muted ? Theme.overlay : Theme.text
            font.pixelSize: Theme.fontSize + 3

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (row.node?.audio) row.node.audio.muted = !row.node.audio.muted
            }
        }
        Slider {
            Layout.fillWidth: true
            value: row.volume
            dimmed: row.muted
            onMoved: v => { if (row.node?.audio) row.node.audio.volume = v; }
        }
        Label {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(row.volume * 100) + "%"
            color: row.muted ? Theme.overlay : Theme.text
        }
    }
}
