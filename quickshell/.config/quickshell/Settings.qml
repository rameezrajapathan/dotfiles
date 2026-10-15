pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Preferences from the Settings app (SettingsApp.qml), kept in ~/.config/pikadots/settings.json.
// Every default is how the shell looked before the app existed, so a missing file changes nothing.
// `qs ipc call settings open <page|"">` opens the app (Super + Comma).
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/pikadots/settings.json"
    readonly property JsonObject appearance: adapter.appearance
    readonly property JsonObject bar: adapter.bar
    // Hyprland options changed in the app, "general.gaps_in" → 5 (Hypr.qml); reassign to change
    property alias hypr: adapter.hypr
    readonly property JsonObject idle: adapter.idle
    readonly property JsonObject display: adapter.display
    readonly property JsonObject notifications: adapter.notifications
    readonly property JsonObject launcher: adapter.launcher
    readonly property JsonObject lock: adapter.lock
    // Apps started at login: [{ name, icon, command, enabled }] (Startup apps page); reassign to change
    property alias startup: adapter.startup

    signal openRequested(string page)

    // Re-runs theme.sh, which reads the mode and scheme choices from this file
    function retheme() {
        saveTimer.stop();
        file.writeAdapter();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh"]);
    }

    IpcHandler {
        target: "settings"
        function open(page: string): void {
            root.openRequested(page);
        }
    }

    Timer {
        id: saveTimer
        interval: 200
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        // Small file; written before theme.sh reads it
        blockWrites: true
        // Saved once after a batch of changes: writing on every property drops some of them
        onAdapterUpdated: saveTimer.restart()

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string font: "FiraCode Nerd Font Propo"
                // Big numbers and headings (lock screen clock, page titles)
                property string displayFont: "Fira Sans"
                property int fontSize: 13
                // Material Symbols weight: 300 light, 400 regular, 500 medium, 600 bold
                property int iconWeight: 400
                // Bar pill and panel background opacity
                property real panelOpacity: 0.8
                // auto (from the wallpaper), dark, light
                property string themeMode: "auto"
                // auto, tonal-spot, content, neutral, monochrome, expressive, fidelity, rainbow
                property string scheme: "auto"
            }

            property var hypr: ({})
            property var startup: []

            // hypridle timers in minutes, 0 = never (hypr/scripts/idle.sh reads these)
            property JsonObject idle: JsonObject {
                property int dimMinutes: 5
                property int lockMinutes: 10
                property int screenOffMinutes: 11
                property int suspendMinutes: 30
                property bool lockBeforeSleep: true
            }

            property JsonObject display: JsonObject {
                property int nightTemperature: 4500
            }

            property JsonObject notifications: JsonObject {
                // top-right, top, top-left, bottom-right, bottom-left
                property string position: "top-right"
                // Seconds a popup stays when the app doesn't say
                property int timeout: 6
                // Use the app's own timeout when it gives one
                property bool appTimeout: true
                property int maxPopups: 5
                property int width: 400
                // Do Not Disturb every day between these times ("HH:mm")
                property bool schedule: false
                property string from: "22:00"
                property string to: "07:00"
            }

            property JsonObject launcher: JsonObject {
                property int columns: 6
                property int cellSize: 128
                property bool mostUsedFirst: true
                property bool calc: true
                property bool run: true
                property bool emoji: true
                property bool projects: true
                property bool clipboard: true
            }

            property JsonObject lock: JsonObject {
                // Wallpaper blur while awake, 0..1
                property real blur: 0.85
                // Seconds without input before the lock screen rests (0 = never)
                property int restSeconds: 15
                property bool showMedia: true
                property bool showPower: true
            }

            property JsonObject bar: JsonObject {
                property int height: 44
                property bool weather: true
                property bool musicBars: true
                property bool clock24: false
                property bool seconds: false
            }
        }
    }
}
