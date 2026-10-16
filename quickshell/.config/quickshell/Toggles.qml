pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// Quick settings state, kept across shell reloads: keep awake (the bars hold an IdleInhibitor
// while it's on, so hypridle doesn't dim, lock or suspend), night light (hyprsunset) and the
// color picker, and game mode. Do Not Disturb lives in NotificationService.
Singleton {
    id: root

    property alias keepAwake: state.keepAwake
    property alias nightLight: state.nightLight
    // No animations, blur, shadows, rounding or gaps (settings.lua checks the marker file, so a
    // Hyprland reload keeps it), the performance power profile and Do Not Disturb; turning it off
    // puts back the profile and Do Not Disturb as they were
    property alias gameMode: state.gameMode
    readonly property string gameModeMarker: Quickshell.env("XDG_RUNTIME_DIR") + "/pikadots-gamemode"

    function setGameMode(on) {
        if (on === gameMode)
            return;
        gameMode = on;
        if (on) {
            state.savedProfile = PowerProfiles.profile;
            state.savedDnd = NotificationService.dnd;
            if (PowerProfiles.hasPerformanceProfile)
                PowerProfiles.profile = PowerProfile.Performance;
            NotificationService.dnd = true;
        } else {
            PowerProfiles.profile = state.savedProfile;
            NotificationService.dnd = state.savedDnd;
        }
        Quickshell.execDetached(["sh", "-c", (on ? "touch \"$1\"" : "rm -f \"$1\"") + " && hyprctl reload", "sh", gameModeMarker]);
    }
    // Settings app > Displays; a running hyprsunset follows changes through its IPC
    readonly property int nightTemperature: Settings.display.nightTemperature
    onNightTemperatureChanged: if (nightLight) Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(nightTemperature)])

    // Night light schedule: turns it on or off when the time crosses an edge, so switching it by
    // hand in between holds until the next edge. Sunset to sunrise uses Weather's place and falls
    // back to the custom times until Weather has one.
    readonly property string nightSchedule: Settings.display.nightSchedule
    readonly property var sunTimes: {
        const today = Weather.daily?.[0];
        return nightSchedule === "sun" && today?.sunset && today?.sunrise ? today : null;
    }
    // [from, to] in minutes after midnight, or null with no schedule
    readonly property var nightWindow: {
        if (nightSchedule === "off")
            return null;
        if (sunTimes)
            return [sunTimes.sunset.getHours() * 60 + sunTimes.sunset.getMinutes(),
                sunTimes.sunrise.getHours() * 60 + sunTimes.sunrise.getMinutes()];
        const minutes = t => {
            const [h, m] = t.split(":").map(Number);
            return h * 60 + (m || 0);
        };
        return [minutes(Settings.display.nightFrom), minutes(Settings.display.nightTo)];
    }
    readonly property bool nightScheduled: {
        if (!nightWindow)
            return false;
        const now = clock.date.getHours() * 60 + clock.date.getMinutes();
        const [from, to] = nightWindow;
        // A range past midnight (20:00–07:00) wraps
        return from <= to ? now >= from && now < to : now >= from || now < to;
    }
    function followSchedule() {
        if (nightSchedule !== "off")
            nightLight = nightScheduled;
    }
    onNightScheduledChanged: followSchedule()
    onNightScheduleChanged: followSchedule()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    signal panelToggleRequested()
    // `qs ipc call controlcenter toggle <tab>` (account, music, notifications, network, bluetooth,
    // audio, display, battery, system, capture, github; "" = last tab)
    signal controlCenterRequested(string tab)
    // `qs ipc call calendar toggle`
    signal calendarRequested()

    // A click on a bar item (BarModule.qml) from outside a bar: a Sheet's copy of it
    function barAction(name) {
        if (name.startsWith("cc:"))
            controlCenterRequested(name.slice(3));
        else if (name === "calendar")
            calendarRequested();
        else if (name === "weather")
            Weather.panelToggleRequested();
        else
            Quickshell.execDetached(["qs", "ipc", "call", name, "toggle"]);
    }

    // Copies the picked color as hex and shows it in a notification
    function pickColor() {
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.3; c=$(hyprpicker -a -f hex) && [ -n \"$c\" ] && notify-send -a 'Color picker' \"$c\" 'Copied to the clipboard'"]);
    }

    PersistentProperties {
        id: state
        reloadableId: "toggles"
        // A fresh start (not a reload) picks up where the schedule is now
        onLoaded: root.followSchedule()
        property bool keepAwake: false
        property bool nightLight: false
        property bool gameMode: false
        property int savedProfile: PowerProfile.Balanced
        property bool savedDnd: false
    }

    // After a shell restart: game mode is on if the marker is still there
    Process {
        running: true
        command: ["test", "-e", root.gameModeMarker]
        onExited: code => state.gameMode = code === 0
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

    // qs ipc call bar position <top|bottom|left|right>; bar cycle goes round the edges
    IpcHandler {
        target: "bar"
        function position(edge: string): void {
            if (["top", "bottom", "left", "right"].includes(edge))
                Settings.bar.position = edge;
        }
        function cycle(): void {
            const edges = ["top", "right", "bottom", "left"];
            Settings.bar.position = edges[(edges.indexOf(Theme.barPosition) + 1) % 4];
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
        function gameMode(): void {
            root.setGameMode(!root.gameMode);
        }
    }
}
