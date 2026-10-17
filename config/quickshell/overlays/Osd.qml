import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    readonly property int segments: 20
    property string kind: "volume"
    property real brightness: 0
    property real keyboard: 0
    property bool open: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool muted: kind === "volume" ? (sink?.audio?.muted ?? false)
        : kind === "mic" ? (source?.audio?.muted ?? false)
        : false
    readonly property real value: kind === "volume" ? (sink?.audio?.volume ?? 0)
        : kind === "mic" ? (source?.audio?.volume ?? 0)
        : kind === "brightness" ? brightness
        : keyboard
    readonly property string icon: {
        switch (kind) {
        case "volume":
            return muted ? "volume_off" : value < 0.01 ? "volume_mute" : value < 0.5 ? "volume_down" : "volume_up";
        case "mic":
            return muted ? "mic_off" : "mic";
        case "brightness":
            return value < 0.34 ? "brightness_low" : value < 0.67 ? "brightness_medium" : "brightness_high";
        default:
            return value > 0 ? "keyboard" : "keyboard_off";
        }
    }

    function show(what) {
        kind = what;
        if (what === "brightness")
            brightnessReader.running = true;
        else if (what === "keyboard")
            keyboardReader.running = true;
        visible = true;
        open = true;
        hideTimer.restart();
    }

    PwObjectTracker { objects: [root.sink, root.source] }

    Process {
        id: brightnessReader
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5)
                    root.brightness = Number(f[2]) / Number(f[4]);
            }
        }
    }
    Process {
        id: keyboardReader
        command: ["brightnessctl", "-m", "-d", "*::kbd_backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5)
                    root.keyboard = Number(f[2]) / Number(f[4]);
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.open = false
    }

    IpcHandler {
        target: "osd"
        function volume(): void {
            root.show("volume");
        }
        function mic(): void {
            root.show("mic");
        }
        function brightness(): void {
            root.show("brightness");
        }
        function keyboard(): void {
            root.show("keyboard");
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 90
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    implicitWidth: 400
    implicitHeight: 72
    color: "transparent"
    visible: false
    mask: Region {}

    Rectangle {
        id: pill
        width: parent.width
        height: parent.height
        radius: Theme.round(height / 2, width, height)
        color: "transparent"
        border.width: 1
        border.color: Theme.gradientAccent || Glass.active ? "transparent" : Qt.alpha(Theme.accent, 0.3)
        GlassPanel {
            radius: pill.radius
            tint: Theme.denseTranslucent
        }
        GradientBorder {
            strength: 0.3
        }

        opacity: root.open ? 1 : 0
        y: root.open ? 0 : 16
        Behavior on y { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.ms(180)
                onRunningChanged: if (!running && !root.open) root.visible = false
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 22
            spacing: 16

            Rectangle {
                implicitWidth: 44
                implicitHeight: 44
                radius: Theme.round(22, width, height)
                color: root.muted ? Qt.alpha(Theme.red, 0.18) : Qt.alpha(Theme.accent, 0.2)
                Behavior on color { ColorAnimation { duration: Theme.ms(150) } }

                Icon {
                    anchors.centerIn: parent
                    name: root.icon
                    filled: true
                    size: 24
                    color: root.muted ? Theme.red : Theme.accent
                }
            }

            Row {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.segments

                    Rectangle {
                        required property int index
                        readonly property bool lit: !root.muted
                            && root.value * root.segments > index + 0.001
                        readonly property real full: 10 + 14 * index / (root.segments - 1)

                        anchors.verticalCenter: parent.verticalCenter
                        width: (parent.width - parent.spacing * (root.segments - 1)) / root.segments
                        height: lit ? full : 6
                        radius: Theme.round(width / 2, width, height)
                        color: lit ? Theme.accent : Qt.alpha(Theme.text, 0.15)

                        Behavior on height { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
                    }
                }
            }

            Label {
                Layout.preferredWidth: 52
                horizontalAlignment: Text.AlignRight
                text: root.muted ? "Muted" : Math.round(root.value * 100) + "%"
                color: root.muted ? Theme.red : Theme.text
                font.bold: true
            }
        }
    }
}
