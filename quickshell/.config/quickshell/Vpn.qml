import Quickshell
import Quickshell.Io
import QtQuick

// VPN state from NetworkManager; click to toggle.
Label {
    id: root
    property bool active: false

    text: "󰖂 vpn"
    color: active ? Theme.green : Theme.overlay

    Process {
        id: check
        command: ["nmcli", "-t", "-f", "TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: root.active = text.split("\n").includes("vpn")
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: check.running = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/vpn.sh"])
    }
}
