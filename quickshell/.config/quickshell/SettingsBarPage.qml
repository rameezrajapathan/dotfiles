import QtQuick
import QtQuick.Layouts

// Settings app > Bar: pill size, what it shows and the clock format.
SettingsPage {
    id: root
    title: "Bar"
    subtitle: "The pill at the top of the screen."

    SettingsSection {
        title: "Size"

        SettingsRow {
            icon: "height"
            title: "Bar height"
            description: "The pill and its circles scale with it."
            SettingsSlider {
                from: 36
                to: 56
                stepSize: 2
                value: Settings.bar.height
                suffix: " px"
                onMoved: v => Settings.bar.height = v
            }
        }
    }

    SettingsSection {
        title: "Items"

        SettingsRow {
            icon: "partly_cloudy_day"
            title: "Weather"
            description: "Temperature next to the clock. Click it for the forecast."
            Switch {
                checked: Settings.bar.weather
                onToggled: Settings.bar.weather = !checked
            }
        }
        SettingsRow {
            icon: "graphic_eq"
            title: "Music spectrum"
            description: "Replaces the clock with moving bars while music plays."
            Switch {
                checked: Settings.bar.musicBars
                onToggled: Settings.bar.musicBars = !checked
            }
        }
    }

    SettingsSection {
        title: "Clock"

        SettingsRow {
            icon: "schedule"
            title: "24-hour time"
            Switch {
                checked: Settings.bar.clock24
                onToggled: Settings.bar.clock24 = !checked
            }
        }
        SettingsRow {
            icon: "timer"
            title: "Show seconds"
            Switch {
                checked: Settings.bar.seconds
                onToggled: Settings.bar.seconds = !checked
            }
        }
    }
}
