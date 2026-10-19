pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar
import qs.settings

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/pikadots/settings.json"
    readonly property JsonObject appearance: adapter.appearance
    readonly property JsonObject glass: adapter.glass
    readonly property JsonObject bar: adapter.bar
    readonly property JsonObject workspaces: adapter.workspaces
    readonly property JsonObject controlCenter: adapter.controlCenter
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
    property alias startup: adapter.startup
    property alias windowRules: adapter.windowRules

    signal openRequested(string page)

    function retheme() {
        saveTimer.stop();
        file.writeAdapter();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh"]);
    }

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

    function applyIconTheme() {
        saveTimer.stop();
        fontTimer.stop();
        file.writeAdapter();
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/icons.sh", "--restart-shell"]);
    }

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
        blockWrites: true
        onAdapterUpdated: saveTimer.restart()

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string font: "FiraCode Nerd Font Propo"
                property string monoFont: "FiraCode Nerd Font Mono"
                property bool appFonts: false
                property string displayFont: "Fira Sans"
                property int fontSize: 13
                property int iconWeight: 400
                property string iconStyle: "Rounded"
                property real roundness: 1
                property string iconTheme: "Papirus"
                property bool qtTheme: true
                property string panelAnimation: "slide"
                property real panelSpeed: 1
                property real panelOpacity: 0.8
                property string themeMode: "auto"
                property string scheme: "auto"
                property bool gradient: false
            }

            property JsonObject glass: JsonObject {
                property string preset: "frosted"
                property var custom: ({})
                property real lightAngle: -40
                property bool color: false
            }

            property var hypr: ({})
            property var startup: []
            property var windowRules: []

            property JsonObject idle: JsonObject {
                property int dimMinutes: 5
                property int lockMinutes: 10
                property int screenOffMinutes: 11
                property int suspendMinutes: 30
                property bool lockBeforeSleep: true
            }

            property JsonObject display: JsonObject {
                property int nightTemperature: 4500
                property string nightSchedule: "off"
                property string nightFrom: "20:00"
                property string nightTo: "07:00"
            }

            property JsonObject notifications: JsonObject {
                property string position: "top-right"
                property int timeout: 6
                property bool appTimeout: true
                property int maxPopups: 5
                property int width: 400
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
                property int clipboardSize: 750
                property bool clipboardPersist: true
            }

            property JsonObject lock: JsonObject {
                property real blur: 0.85
                property int restSeconds: 15
                property bool showMedia: true
                property bool showPower: true
            }

            property JsonObject datetime: JsonObject {
                property string dateFormat: "ddd d MMM"
                property int weekStart: 1
                property bool weekNumbers: false
                property var worldClocks: []
            }

            property JsonObject accessibility: JsonObject {
                property real textScale: 1
                property bool reduceMotion: false
            }

            property JsonObject drives: JsonObject {
                property bool automount: true
                property bool openFiles: false
            }

            property JsonObject updates: JsonObject {
                property int checkHours: 6
                property bool notify: true
                property bool system: true
            }

            property JsonObject controlCenter: JsonObject {
                property string style: "glance"
                property var custom: null
                property var tiles: ["network", "bluetooth", "vpn", "dnd", "night", "profile"]
            }

            property JsonObject workspaces: JsonObject {
                property string style: "focus"
                property string labels: "arabic"
                property string show: "fixed"
                property int count: 5
                property bool markOccupied: true
                property bool glide: true
                property bool pillLabel: false
                property real size: 1
            }

            property JsonObject bar: JsonObject {
                property string layout: "pill"
                property string position: "top"
                property var left: []
                property var center: ["workspaces", "divider", "clock", "meeting", "recording", "divider", "avatar"]
                property var right: []
                property int height: 46
                property int gap: 4
                property int sideGap: 8
                property bool border: false
                property bool attached: false
                property var custom: null
                property bool musicBars: true
                property bool clock24: false
                property bool seconds: false
            }
        }
    }
}
