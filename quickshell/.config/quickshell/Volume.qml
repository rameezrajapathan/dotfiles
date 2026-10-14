import Quickshell.Services.Pipewire
import QtQuick

Label {
    id: root
    signal clicked()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true

    PwObjectTracker { objects: [sink] }

    font.pixelSize: Theme.fontSize + 3
    text: muted ? "󰝟" : volume < 0.34 ? "󰕿" : volume < 0.67 ? "󰖀" : "󰕾"
    color: muted ? Theme.overlay : Theme.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                root.clicked();
            else if (sink?.audio)
                sink.audio.muted = !sink.audio.muted;
        }
        onWheel: wheel => {
            if (!sink?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.03 : -0.03;
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
        }
    }
}
