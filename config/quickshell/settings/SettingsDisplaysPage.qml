import QtQuick
import QtQuick.Layouts
import qs.panels
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Displays"
    subtitle: "Resolution, refresh rate, scale and arrangement. Saved per monitor."

    function validTime(t) {
        return /^([01]?\d|2[0-3]):[0-5]\d$/.test(t.trim());
    }

    SettingsPanelCard {
        DisplayPanel { shown: root.shown }
    }

    SettingsSection {
        title: "Night light"

        SettingsRow {
            icon: "nightlight"
            title: "Night light"
            description: Toggles.nightSchedule === "off" ? "Warmer colors that are easier on the eyes at night."
                : "Switching it here holds until the schedule's next change."
            Switch {
                checked: Toggles.nightLight
                onToggled: Toggles.nightLight = !checked
            }
        }
        SettingsRow {
            icon: "schedule"
            title: "Schedule"
            description: Toggles.nightSchedule === "sun"
                ? (Toggles.sunTimes ? "Today " + Qt.formatTime(Toggles.sunTimes.sunset, "h:mm AP") + " to "
                    + Qt.formatTime(Toggles.sunTimes.sunrise, "h:mm AP") + ", at the place set for Weather."
                    : "Needs a place in Settings > Weather; the custom times apply until then.")
                : Toggles.nightSchedule === "custom" ? "Every day between two times." : "Only when you turn it on."
            SettingsSegmented {
                options: [
                    { value: "off", label: "Off" },
                    { value: "sun", label: "Sunset", icon: "wb_twilight" },
                    { value: "custom", label: "Custom", icon: "schedule" }
                ]
                current: Toggles.nightSchedule
                onPicked: v => Settings.display.nightSchedule = v
            }
        }
        SettingsRow {
            visible: Toggles.nightSchedule === "custom" || (Toggles.nightSchedule === "sun" && !Toggles.sunTimes)
            icon: "bedtime"
            title: "From – to"
            description: "24-hour times, e.g. 20:00 and 07:00."
            Row {
                spacing: 8
                SettingsTextField {
                    implicitWidth: 90
                    text: Settings.display.nightFrom
                    onAccepted: t => { if (root.validTime(t)) Settings.display.nightFrom = t.trim(); }
                }
                Label { text: "–"; anchors.verticalCenter: parent.verticalCenter; color: Theme.subtext }
                SettingsTextField {
                    implicitWidth: 90
                    text: Settings.display.nightTo
                    onAccepted: t => { if (root.validTime(t)) Settings.display.nightTo = t.trim(); }
                }
            }
        }
        SettingsRow {
            icon: "thermostat"
            title: "Warmth"
            description: "Lower is warmer."
            SettingsSlider {
                from: 2500; to: 6000; stepSize: 100
                value: Settings.display.nightTemperature
                suffix: " K"
                onMoved: v => Settings.display.nightTemperature = v
            }
        }
    }
}
