import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.services

ColumnLayout {
    id: root
    property var cc
    property bool mic: false

    spacing: 8

    readonly property var sink: StatusInfo.sink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.source] }

    readonly property bool shown: cc?.open ?? false
    onShownChanged: if (shown) Brightness.refresh()

    RowLayout {
        Layout.fillWidth: true
        visible: root.sink?.audio !== undefined && root.sink !== null
        spacing: 8

        CCSlider {
            Layout.fillWidth: true
            icon: StatusInfo.icon("audio")
            value: root.sink?.audio?.volume ?? 0
            dimmed: root.sink?.audio?.muted ?? false
            onMoved: v => {
                root.sink.audio.muted = false;
                root.sink.audio.volume = v;
            }
            onIconClicked: root.sink.audio.muted = !root.sink.audio.muted
        }
        CCIconButton {
            implicitWidth: 44
            implicitHeight: 44
            icon: (root.sink?.description ?? "").toLowerCase().includes("headphone") ? "headphones" : "speaker"
            onClicked: root.cc.openDetail("audio")
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.mic && root.source !== null
        spacing: 8

        CCSlider {
            Layout.fillWidth: true
            icon: (root.source?.audio?.muted ?? false) ? "mic_off" : "mic"
            value: root.source?.audio?.volume ?? 0
            dimmed: root.source?.audio?.muted ?? false
            onMoved: v => {
                root.source.audio.muted = false;
                root.source.audio.volume = v;
            }
            onIconClicked: root.source.audio.muted = !root.source.audio.muted
        }
        CCIconButton {
            implicitWidth: 44
            implicitHeight: 44
            icon: "settings_voice"
            onClicked: root.cc.openDetail("audio")
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Brightness.available
        spacing: 8

        CCSlider {
            Layout.fillWidth: true
            icon: Brightness.value < 0.35 ? "brightness_low" : Brightness.value < 0.7 ? "brightness_medium" : "brightness_high"
            value: Math.max(0, Brightness.value)
            onMoved: v => Brightness.set(v)
        }
        CCIconButton {
            implicitWidth: 44
            implicitHeight: 44
            icon: "monitor"
            onClicked: root.cc.openDetail("display")
        }
    }
}
