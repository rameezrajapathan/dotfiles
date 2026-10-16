import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

Item {
    id: root
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    onShownChanged: if (shown) Asus.refresh()

    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round(dev.percentage * 100)
    readonly property var modes: [
        { profile: PowerProfile.PowerSaver, icon: "energy_savings_leaf", title: "Power saver" },
        { profile: PowerProfile.Balanced, icon: "balance", title: "Balanced" },
        { profile: PowerProfile.Performance, icon: "speed", title: "Performance" }
    ].filter(m => m.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

    readonly property var gpuModes: [
        { mode: "ultimate", icon: "rocket_launch", title: "Ultimate", detail: "NVIDIA drives the screen" },
        { mode: "hybrid", icon: "sync_alt", title: "Hybrid", detail: "NVIDIA when needed" },
        { mode: "eco", icon: "energy_savings_leaf", title: "Eco", detail: "NVIDIA off" }
    ]

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

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(20, 24) }
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
                text: "Battery care"
            }
            PanelRow {
                Layout.fillWidth: true
                clickable: false
                icon: "battery_android_frame_5"
                title: "Charge to " + Asus.chargeLimit + "%"
                detail: Asus.chargeLimit < 100 ? "protects the battery" : "no limit"

                Switch {
                    checked: Asus.chargeLimit < 100
                    onToggled: Asus.setChargeLimit(Asus.chargeLimit < 100 ? 100 : 80)
                }
            }
            Pill {
                Layout.leftMargin: 8
                visible: Asus.chargeLimit < 100
                text: "charge to 100% once"
                onClicked: Asus.chargeOnce()
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

            SectionLabel {
                visible: Asus.available
                text: "GPU mode"
            }
            Repeater {
                model: Asus.available ? root.gpuModes : []

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    visible: modelData.mode !== "eco" || Asus.mux === 1
                    icon: modelData.icon
                    title: modelData.title
                    detail: Asus.requestedMode === modelData.mode && Asus.gpuMode !== modelData.mode ? "after restart" : modelData.detail
                    highlighted: Asus.gpuMode === modelData.mode
                    onClicked: if (Asus.gpuMode !== modelData.mode) Asus.setGpuMode(modelData.mode)
                }
            }
            Label {
                visible: Asus.available && (Asus.pendingReboot || (Asus.requestedMode !== "" && Asus.requestedMode !== Asus.gpuMode))
                Layout.leftMargin: 8
                text: "Restart to apply the new GPU mode"
                color: Theme.yellow
                font.pixelSize: Theme.fontSize - 2
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
