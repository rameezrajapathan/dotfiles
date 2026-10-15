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
    readonly property JsonObject datetime: adapter.datetime
    readonly property JsonObject updates: adapter.updates
    readonly property JsonObject drives: adapter.drives
    readonly property JsonObject accessibility: adapter.accessibility
    // Apps started at login: [{ name, icon, command, enabled }] (Startup apps page); reassign to change
    property alias startup: adapter.startup
    property alias windowRules: adapter.windowRules

    signal openRequested(string page)

    // Re-runs theme.sh, which reads the mode and scheme choices from this file
    function retheme() {
        saveTimer.stop();
        file.writeAdapter();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh"]);
    }

    // Terminal and app fonts are applied by hypr/scripts/fonts.sh, which reads this file
    function applyFonts() {
        fontTimer.restart();
    }
    Timer {
        id: fontTimer
        interval: 400
        onTriggered: {
            saveTimer.stop();
            file.writeAdapter();
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/fonts.sh"]);
        }
    }

    // Sets GTK's icon theme and restarts the shell, which only reads its icon theme at start
    function applyIconTheme() {
        saveTimer.stop();
        fontTimer.stop();
        file.writeAdapter();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/icons.sh", "--restart-shell"]);
    }

    // Writes or undoes the Qt/KDE theme in kdeglobals (hypr/scripts/kde-theme.py reads this file)
    function applyQtTheme() {
        saveTimer.stop();
        file.writeAdapter();
        Quickshell.execDetached(["python3", "-I", Quickshell.env("HOME") + "/.config/hypr/scripts/kde-theme.py"]);
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
                // Terminal (kitty) font, applied by hypr/scripts/fonts.sh
                property string monoFont: "FiraCode Nerd Font Mono"
                // Also use the interface font for GTK apps
                property bool appFonts: false
                // Big numbers and headings (lock screen clock, page titles)
                property string displayFont: "Fira Sans"
                property int fontSize: 13
                // Material Symbols weight: 300 light, 400 regular, 500 medium, 600 bold
                property int iconWeight: 400
                // Material Symbols style: Rounded, Outlined or Sharp
                property string iconStyle: "Rounded"
                // App icon theme family (Papirus, breeze, ...); hypr/scripts/icons.sh picks the
                // dark or light variant
                property string iconTheme: "Papirus"
                // Wallpaper colors, icons and fonts for Qt/KDE apps (hypr/scripts/kde-theme.py)
                property bool qtTheme: true
                // Bar pill and panel background opacity
                property real panelOpacity: 0.8
                // auto (from the wallpaper), dark, light
                property string themeMode: "auto"
                // auto, tonal-spot, content, neutral, monochrome, expressive, fidelity, rainbow
                property string scheme: "auto"
            }

            property var hypr: ({})
            property var startup: []
            // Window rules page: [{ cls, name, icon, float, center, size, pin, fullscreen, workspace, silent, opacity, noBlur }]
            property var windowRules: []

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
                // Night light on a schedule: off, sun (sunset to sunrise at Weather's place) or
                // custom (nightFrom–nightTo, 24-hour); Toggles.qml switches it at the edges
                property string nightSchedule: "off"
                property string nightFrom: "20:00"
                property string nightTo: "07:00"
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
                // Clipboard history entries kept, and keeping copied text after its app closes
                // (wl-clip-persist); hypr/scripts/clipboard.sh watch applies both
                property int clipboardSize: 750
                property bool clipboardPersist: true
            }

            property JsonObject lock: JsonObject {
                // Wallpaper blur while awake, 0..1
                property real blur: 0.85
                // Seconds without input before the lock screen rests (0 = never)
                property int restSeconds: 15
                property bool showMedia: true
                property bool showPower: true
            }

            property JsonObject datetime: JsonObject {
                // Bar date item and the calendar's long date (Qt date format)
                property string dateFormat: "ddd d MMM"
                // Calendar weeks start on: 1 Monday, 0 Sunday, 6 Saturday
                property int weekStart: 1
                property bool weekNumbers: false
                // Extra clocks in the calendar: [{ zone: "Europe/London", label: "London" }]
                property var worldClocks: []
            }

            // Checks for pikadots and system updates (Updates.qml)
            // Accessibility page (hypr/scripts/accessibility.sh applies them to GTK and Qt apps)
            property JsonObject accessibility: JsonObject {
                // Text in the shell, GTK and Qt apps; 1 = as set on the Fonts page
                property real textScale: 1
                property bool reduceMotion: false
            }

            // Drives.qml: what happens when a USB drive or SD card is plugged in
            property JsonObject drives: JsonObject {
                property bool automount: true
                property bool openFiles: false
            }

            property JsonObject updates: JsonObject {
                // Hours between checks, 0 = only when the Updates page opens
                property int checkHours: 6
                property bool notify: true
                property bool system: true
            }

            property JsonObject bar: JsonObject {
                // pill: everything in one centered pill; islands: a pill per section;
                // full: one bar across the screen with the sections at its left, middle and right
                property string layout: "pill"
                // Module ids per section (BarModule.qml lists them); a pill joins the three
                property var left: []
                // The "minimalist" style (BarStyles.qml)
                property var center: ["workspaces", "divider", "clock", "meeting", "recording", "divider", "avatar"]
                property var right: []
                // Space the bar takes at the top of the screen; its shapes sit `gap` inside it
                property int height: 46
                property int gap: 4
                // islands and full: space from the screen's sides
                property int sideGap: 8
                // 0 square .. 1 fully round ends
                property real roundness: 1
                property bool border: false
                // The last custom setup, kept while a style is picked so "Custom" can bring it back
                property var custom: null
                property bool musicBars: true
                property bool clock24: false
                property bool seconds: false
            }
        }
    }
}
