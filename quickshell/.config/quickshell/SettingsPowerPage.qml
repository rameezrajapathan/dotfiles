import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Settings app > Power: battery and power mode (the control center's panel) and the idle timers
// (hypridle, restarted through hypr/scripts/idle.sh after a change).
SettingsPage {
    id: root
    title: "Power"
    subtitle: "Battery, power mode, and what happens when you step away."

    readonly property var steps: [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120]

    function label(minutes) {
        return minutes === 0 ? "Never" : minutes < 60 ? minutes + " min" : (minutes / 60) + " h";
    }

    function set(key, minutes) {
        Settings.idle[key] = minutes;
        restartTimer.restart();
    }

    // One restart after the slider settles
    Timer {
        id: restartTimer
        interval: 800
        onTriggered: Quickshell.execDetached(["setsid", "-f", Quickshell.env("HOME") + "/.config/hypr/scripts/idle.sh"])
    }

    SettingsPanelCard {
        visible: UPower.displayDevice.isLaptopBattery
        BatteryPanel { shown: root.shown }
    }

    SettingsSection {
        title: "When idle"
        subtitle: Toggles.keepAwake ? "Keep awake is on: none of this happens until you turn it off." : "Time without keyboard or mouse input."
        canReset: Settings.idle.dimMinutes !== 5 || Settings.idle.lockMinutes !== 10 || Settings.idle.screenOffMinutes !== 11
            || Settings.idle.suspendMinutes !== 30 || !Settings.idle.lockBeforeSleep
        onReset: {
            Settings.idle.dimMinutes = 5;
            Settings.idle.lockMinutes = 10;
            Settings.idle.screenOffMinutes = 11;
            Settings.idle.suspendMinutes = 30;
            Settings.idle.lockBeforeSleep = true;
            restartTimer.restart();
        }

        Repeater {
            model: [
                { key: "dimMinutes", icon: "brightness_medium", title: "Dim the screen" },
                { key: "lockMinutes", icon: "lock", title: "Lock" },
                { key: "screenOffMinutes", icon: "desktop_access_disabled", title: "Turn the screen off" },
                { key: "suspendMinutes", icon: "bedtime", title: "Sleep" }
            ]
            SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                // Snaps to common durations; 0 = never
                RowLayout {
                    implicitWidth: 300
                    spacing: 12
                    Slider {
                        Layout.fillWidth: true
                        value: Math.max(0, root.steps.findIndex(s => s >= Settings.idle[modelData.key])) / (root.steps.length - 1)
                        onMoved: v => root.set(modelData.key, root.steps[Math.round(v * (root.steps.length - 1))])
                    }
                    Label {
                        Layout.preferredWidth: 56
                        horizontalAlignment: Text.AlignRight
                        text: root.label(Settings.idle[modelData.key])
                        color: Theme.subtext
                    }
                }
            }
        }

        SettingsRow {
            icon: "lock_clock"
            title: "Lock before sleeping"
            description: "Also when the lid closes or the laptop suspends from the power menu."
            Switch {
                checked: Settings.idle.lockBeforeSleep
                onToggled: {
                    Settings.idle.lockBeforeSleep = !checked;
                    restartTimer.restart();
                }
            }
        }
        SettingsRow {
            icon: "coffee"
            title: "Keep awake"
            description: "Pause all of the above for now (also in the control center)."
            Switch {
                checked: Toggles.keepAwake
                onToggled: Toggles.keepAwake = !checked
            }
        }
    }
}
