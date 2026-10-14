import Quickshell
import Quickshell.Io
import QtQuick

// Red dot while wf-recorder runs; click to stop.
Label {
    id: root
    property bool active: false

    visible: active
    text: "󰑊 rec"
    color: Theme.red

    Process {
        id: check
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => root.active = code === 0
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
    }
}
