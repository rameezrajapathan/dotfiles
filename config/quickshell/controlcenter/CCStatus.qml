import QtQuick
import qs.services

Flow {
    id: root
    property var cc

    spacing: 6

    readonly property bool watching: cc?.open ?? false
    onWatchingChanged: SysStats.watch(watching)
    Component.onDestruction: if (watching) SysStats.watch(false)

    CCChip {
        icon: "memory"
        text: "CPU " + Math.round(SysStats.cpu * 100) + "%"
        onClicked: root.cc.openDetail("system")
    }
    CCChip {
        visible: SysStats.memTotal > 0
        icon: "memory_alt"
        text: SysStats.gib(SysStats.memUsed) + " / " + Math.round(SysStats.memTotal / 1073741824) + " GB"
        onClicked: root.cc.openDetail("system")
    }
    CCChip {
        visible: Drives.volumes.length > 0
        icon: "usb"
        text: Drives.volumes.length + (Drives.volumes.length === 1 ? " drive" : " drives")
        onClicked: root.cc.openDetail("drives")
    }
    CCChip {
        visible: Updates.count > 0
        highlight: true
        icon: "system_update_alt"
        text: Updates.count + (Updates.count === 1 ? " update" : " updates")
        onClicked: {
            root.cc.close();
            Settings.openRequested("updates");
        }
    }
    CCChip {
        visible: GitHub.signedIn && GitHub.unread > 0
        highlight: true
        icon: "commit"
        text: GitHub.unread + " on GitHub"
        onClicked: root.cc.openDetail("github")
    }
    CCChip {
        visible: Recorder.active
        highlight: true
        tint: Theme.red
        icon: "radio_button_checked"
        text: "Recording " + Recorder.elapsedText
        onClicked: root.cc.openDetail("capture")
    }
}
