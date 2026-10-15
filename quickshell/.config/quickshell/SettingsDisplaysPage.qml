import QtQuick
import QtQuick.Layouts

// Settings app > Displays: the control center's display panel, plus night light.
SettingsPage {
    id: root
    title: "Displays"
    subtitle: "Resolution, refresh rate, scale and arrangement. Saved per monitor."

    SettingsPanelCard {
        DisplayPanel { shown: root.shown }
    }

    SettingsSection {
        title: "Night light"

        SettingsRow {
            icon: "nightlight"
            title: "Night light"
            description: "Warmer colors that are easier on the eyes at night."
            Switch {
                checked: Toggles.nightLight
                onToggled: Toggles.nightLight = !checked
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
