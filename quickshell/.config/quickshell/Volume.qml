import Quickshell.Services.Pipewire
import QtQuick

Label {
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true

    PwObjectTracker { objects: [sink] }

    text: muted ? "󰝟 mute" : (volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾") + " " + Math.round(volume * 100) + "%"
    color: muted ? Theme.overlay : Theme.text

    MouseArea {
        anchors.fill: parent
        onClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
        onWheel: wheel => {
            if (!sink?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.03 : -0.03;
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
        }
    }
}
