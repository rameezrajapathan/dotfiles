import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property string labels: Settings.workspaces.labels

    readonly property var monitor: Hyprland.monitorFor(QsWindow.window?.screen ?? null) ?? Hyprland.focusedMonitor
    readonly property int current: monitor?.activeWorkspace?.id ?? 1
    readonly property bool urgent: Hyprland.workspaces.values.some(ws => ws.urgent && ws.id !== current)

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

    readonly property var style: {
        const parts = String(Hypr.value("pikadots.workspaceStyle")).split(" ");
        const name = parts[0];
        return {
            vertical: name.endsWith("vert"),
            fade: name.startsWith("fade") || name.startsWith("slidefade"),
            distance: name.startsWith("fade") ? 0 : parts[1] ? parseFloat(parts[1]) / 100 : 1
        };
    }
    readonly property bool animated: Hypr.value("animations.enabled") ?? true
    readonly property int duration: animated ? 100 * 5 * Hypr.value("pikadots.animationSpeed") : 0
    readonly property real outOffset: -direction * style.distance * circle.width * progress
    readonly property real inOffset: direction * style.distance * circle.width * (1 - progress)

    implicitWidth: Theme.pillCircle
    implicitHeight: Theme.pillCircle

    Rectangle {
        id: circle
        anchors.fill: parent
        radius: Theme.round(width / 2, width, height)
        color: Theme.selectedFill
        gradient: Theme.accentFill(true)
        border.width: root.urgent ? 2 : 0
        border.color: Theme.red
        scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
        clip: true

        GlassRim {}

        Text {
            id: oldNumber
            width: parent.width
            height: parent.height
            text: WorkspaceStyles.label(root.previous, root.labels)
            visible: roll.running
            x: root.style.vertical ? 0 : root.outOffset
            y: root.style.vertical ? root.outOffset : 0
            opacity: root.style.fade ? Math.max(0, 1 - root.progress) : 1
            color: Theme.selectedText
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
            text: WorkspaceStyles.label(root.current, root.labels)
            x: root.style.vertical ? 0 : root.inOffset
            y: root.style.vertical ? root.inOffset : 0
            opacity: root.style.fade ? Math.min(1, root.progress) : 1
            color: Theme.selectedText
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
