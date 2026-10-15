import Quickshell
import QtQuick
import QtQuick.Layouts

// Settings app > Lock screen: what it shows and how it rests.
SettingsPage {
    id: root
    title: "Lock screen"
    subtitle: "Your wallpaper, the clock and a password field. It uses the bar's 12/24-hour setting."

    readonly property var lk: Settings.lock

    SettingsSection {
        title: "Look"

        SettingsRow {
            icon: "blur_on"
            title: "Wallpaper blur"
            SettingsSlider {
                from: 0; to: 100; stepSize: 5
                value: Math.round(root.lk.blur * 100)
                suffix: "%"
                onMoved: v => root.lk.blur = v / 100
            }
        }
        SettingsRow {
            icon: "music_note"
            title: "Now playing"
            description: "Shows the current track with controls."
            Switch {
                checked: root.lk.showMedia
                onToggled: root.lk.showMedia = !checked
            }
        }
        SettingsRow {
            icon: "power_settings_new"
            title: "Power buttons"
            description: "Sleep, restart and shut down without unlocking."
            Switch {
                checked: root.lk.showPower
                onToggled: root.lk.showPower = !checked
            }
        }
        SettingsRow {
            icon: "hotel"
            title: "Rest after"
            description: "Without input the blur softens and the password side dims."
            SettingsSegmented {
                options: [0, 10, 15, 30, 60].map(s => ({ value: s, label: s === 0 ? "Never" : s + " s" }))
                current: root.lk.restSeconds
                onPicked: v => root.lk.restSeconds = v
            }
        }
    }

    SettingsSection {
        title: "Locking"

        SettingsRow {
            icon: "timer"
            title: "Lock when idle"
            description: Settings.idle.lockMinutes > 0 ? "After " + Settings.idle.lockMinutes + " minutes without input." : "Never."
            Pill {
                text: "Change"
                implicitHeight: 30
                onClicked: Settings.openRequested("power")
            }
        }
        SettingsRow {
            icon: "lock"
            title: "Lock now"
            description: "Super + Alt + L"
            Pill {
                icon: "lock"
                implicitHeight: 30
                onClicked: Quickshell.execDetached(["loginctl", "lock-session"])
            }
        }
    }
}
