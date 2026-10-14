import Quickshell
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar: battery status and power-profiles-daemon mode switcher.
// A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round(dev.percentage * 100)
    readonly property var modes: [
        { profile: PowerProfile.PowerSaver, icon: "󰌪", title: "Power saver" },
        { profile: PowerProfile.Balanced, icon: "󰾅", title: "Balanced" },
        { profile: PowerProfile.Performance, icon: "󰓅", title: "Performance" }
    ].filter(m => m.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

    function toggle() {
        visible = !visible;
    }

    function duration(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.round(seconds % 3600 / 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    readonly property string status: {
        switch (dev.state) {
        case UPowerDeviceState.Charging:
            return dev.timeToFull > 0 ? "charging, full in " + duration(dev.timeToFull) : "charging";
        case UPowerDeviceState.FullyCharged:
            return "fully charged";
        case UPowerDeviceState.Discharging:
            return dev.timeToEmpty > 0 ? duration(dev.timeToEmpty) + " left" : "on battery";
        default:
            return "plugged in";
        }
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-battery"
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 320
        height: content.implicitHeight + 28
        color: Theme.base
        radius: 10
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4

                Label {
                    Layout.fillWidth: true
                    text: "Battery"
                    font.bold: true
                }
                Label {
                    text: root.percent + "%"
                    font.bold: true
                }
            }

            Label {
                text: root.status
                color: Theme.subtext
            }

            SectionLabel {
                text: "Power mode"
            }
            Repeater {
                model: root.modes

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: modelData.icon
                    title: modelData.title
                    highlighted: PowerProfiles.profile === modelData.profile
                    onClicked: PowerProfiles.profile = modelData.profile
                }
            }

            Label {
                visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                Layout.leftMargin: 8
                text: "Performance limited: " + PerformanceDegradationReason.toString(PowerProfiles.degradationReason)
                color: Theme.yellow
                font.pixelSize: Theme.fontSize - 2
            }
        }
    }

    component SectionLabel: Label {
        Layout.topMargin: 6
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }
}
