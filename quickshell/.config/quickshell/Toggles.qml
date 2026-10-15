pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Quick settings state, kept across shell reloads: keep awake (the bars hold an IdleInhibitor
// while it's on, so hypridle doesn't dim, lock or suspend), night light (hyprsunset) and the
// color picker. Do Not Disturb lives in NotificationService.
Singleton {
    id: root

    property alias keepAwake: state.keepAwake
    property alias nightLight: state.nightLight
    // Settings app > Displays; a running hyprsunset follows changes through its IPC
    readonly property int nightTemperature: Settings.display.nightTemperature
    onNightTemperatureChanged: if (nightLight) Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(nightTemperature)])

    signal panelToggleRequested()
    // `qs ipc call controlcenter toggle <tab>` (account, music, notifications, network, bluetooth,
    // audio, display, battery, system, capture, github; "" = last tab)
    signal controlCenterRequested(string tab)
    // `qs ipc call calendar toggle`
    signal calendarRequested()

    // Copies the picked color as hex and shows it in a notification
    function pickColor() {
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.3; c=$(hyprpicker -a -f hex) && [ -n \"$c\" ] && notify-send -a 'Color picker' \"$c\" 'Copied to the clipboard'"]);
    }

    PersistentProperties {
        id: state
        reloadableId: "toggles"
        property bool keepAwake: false
        property bool nightLight: false
    }

    Process {
        running: root.nightLight
        command: ["hyprsunset", "-t", String(root.nightTemperature)]
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(tab: string): void {
            root.controlCenterRequested(tab);
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            root.calendarRequested();
        }
    }

    // `toggle` opens the Account tab, which holds the quick settings now
    IpcHandler {
        target: "quicksettings"
        function toggle(): void {
            root.panelToggleRequested();
        }
        function pickColor(): void {
            root.pickColor();
        }
        function dnd(): void {
            NotificationService.dnd = !NotificationService.dnd;
        }
        function keepAwake(): void {
            root.keepAwake = !root.keepAwake;
        }
        function nightLight(): void {
            root.nightLight = !root.nightLight;
        }
    }
}
