import Quickshell
import Quickshell.Hyprland
import QtQuick

// The current workspace as a number in an accent circle, so the pill keeps one size however many
// workspaces there are. The number slides sideways when it changes (a higher number comes in from
// the right, a lower one from the left); a red ring means another workspace wants attention. Click
// for the overview, scroll to go through the workspaces that have windows.
Item {
    id: root

    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen ?? null) ?? Hyprland.focusedMonitor
    readonly property int current: monitor?.activeWorkspace?.id ?? 1
    readonly property bool urgent: Hyprland.workspaces.values.some(ws => ws.urgent && ws.id !== current)

    // The roll: the old number leaves while the new one comes in
    property int previous: 0
    property int last: 0
    property int direction: 1
    Component.onCompleted: last = current
    onCurrentChanged: {
        previous = last;
        direction = current > last ? 1 : -1;
        last = current;
        roll.restart();
    }

    implicitWidth: Theme.pillCircle
    implicitHeight: Theme.pillCircle

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: width / 2
        color: Theme.accent
        border.width: root.urgent ? 2 : 0
        border.color: Theme.red
        scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        clip: true

        Text {
            id: oldNumber
            width: parent.width
            height: parent.height
            text: root.previous
            visible: roll.running
            color: Theme.accentText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
        Text {
            id: newNumber
            width: parent.width
            height: parent.height
            text: root.current
            color: Theme.accentText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }

    ParallelAnimation {
        id: roll
        NumberAnimation {
            target: oldNumber; property: "x"
            from: 0; to: -root.direction * circle.width
            duration: 220; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: newNumber; property: "x"
            from: root.direction * circle.width; to: 0
            duration: 220; easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "overview", "toggle"])
        onWheel: wheel => Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.focus({ workspace = "${wheel.angleDelta.y < 0 ? "e+1" : "e-1"}" })`])
    }
}
