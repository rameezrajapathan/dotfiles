import Quickshell
import Quickshell.Io
import QtQuick

// Red dot while wf-recorder runs; click to stop.
Icon {
    id: root
    property bool active: false

    visible: active
    name: "radio_button_checked"
    filled: true
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
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
    }
}
