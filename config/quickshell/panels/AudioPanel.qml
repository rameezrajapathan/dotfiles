import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

Item {
    id: root
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.isSink && n.isStream)

    function deviceName(node) {
        return node.description || node.nickname || node.name;
    }

    function streamName(node) {
        const p = node.properties;
        return p["application.name"] || node.description || node.name;
    }

    PwObjectTracker { objects: root.nodes }

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(20, 24) }
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
                    icon: "settings"
                    onClicked: {
                        root.closeRequested();
                        Quickshell.execDetached(["pavucontrol"]);
                    }
                }
            }

            SectionLabel { text: "Output" }
            VolumeRow {
                node: Pipewire.defaultAudioSink
                icon: muted ? "volume_off" : "volume_up"
            }
            Repeater {
                model: root.sinks

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "speaker"
                    title: root.deviceName(modelData)
                    highlighted: modelData === Pipewire.defaultAudioSink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            SectionLabel { text: "Input" }
            VolumeRow {
                node: Pipewire.defaultAudioSource
                icon: muted ? "mic_off" : "mic"
            }
            Repeater {
                model: root.sources

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "mic"
                    title: root.deviceName(modelData)
                    highlighted: modelData === Pipewire.defaultAudioSource
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

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
                        icon: muted ? "volume_off" : "volume_up"
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

        Icon {
            name: row.icon
            color: row.muted ? Theme.overlay : Theme.text

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
