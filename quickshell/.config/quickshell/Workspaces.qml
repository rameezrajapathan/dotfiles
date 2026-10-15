import Quickshell
import Quickshell.Hyprland
import QtQuick

// The current workspace as a number in an accent circle, so the pill keeps one size however many
// workspaces there are. The number changes with the same animation as Hyprland's workspace switch
// (Settings app > Effects: slide, vertical, slide + fade or fade, at the same speed and curve): a
// higher number comes in from the right (or below), a lower one from the left (or above). A red
// ring means another workspace wants attention. Click for the overview, scroll to go through the
// workspaces that have windows.
Item {
    id: root

    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen ?? null) ?? Hyprland.focusedMonitor
    readonly property int current: monitor?.activeWorkspace?.id ?? 1
    readonly property bool urgent: Hyprland.workspaces.values.some(ws => ws.urgent && ws.id !== current)

    // The roll: the old number leaves while the new one comes in
    property int previous: 0
    property int last: 0
    property int direction: 1
    property real progress: 1
    Component.onCompleted: last = current
    onCurrentChanged: {
        previous = last;
        direction = current > last ? 1 : -1;
        last = current;
        roll.restart();
    }

    // Hyprland's workspace animation, e.g. "slide", "slidevert", "slidefade 20%", "fade"
    readonly property var style: {
        const parts = String(Hypr.value("pikadots.workspaceStyle")).split(" ");
        const name = parts[0];
        return {
            vertical: name.endsWith("vert"),
            fade: name.startsWith("fade") || name.startsWith("slidefade"),
            // How far it travels, as a share of the circle
            distance: name.startsWith("fade") ? 0 : parts[1] ? parseFloat(parts[1]) / 100 : 1
        };
    }
    readonly property bool animated: Hypr.value("animations.enabled") ?? true
    // settings.lua's workspaces speed (5 = 500 ms) times the speed setting
    readonly property int duration: animated ? 100 * 5 * Hypr.value("pikadots.animationSpeed") : 0
    // How far a number is from the center: the old one moves away as the new one arrives
    readonly property real outOffset: -direction * style.distance * circle.width * progress
    readonly property real inOffset: direction * style.distance * circle.width * (1 - progress)

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
            x: root.style.vertical ? 0 : root.outOffset
            y: root.style.vertical ? root.outOffset : 0
            opacity: root.style.fade ? Math.max(0, 1 - root.progress) : 1
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
            x: root.style.vertical ? 0 : root.inOffset
            y: root.style.vertical ? root.inOffset : 0
            opacity: root.style.fade ? Math.min(1, root.progress) : 1
            color: Theme.accentText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
        }
    }

    NumberAnimation {
        id: roll
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.duration
        // Hyprland's "default" bezier
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0.9, 0.1, 1.05, 1, 1]
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
