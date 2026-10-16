pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.bar
import qs.widgets

Singleton {
    id: root

    property alias keepAwake: state.keepAwake
    property alias nightLight: state.nightLight
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
    readonly property int nightTemperature: Settings.display.nightTemperature
    onNightTemperatureChanged: if (nightLight) Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(nightTemperature)])

    readonly property string nightSchedule: Settings.display.nightSchedule
    readonly property var sunTimes: {
        const today = Weather.daily?.[0];
        return nightSchedule === "sun" && today?.sunset && today?.sunrise ? today : null;
    }
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
    signal controlCenterRequested(string tab)
    signal calendarRequested()

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

    function pickColor() {
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.3; c=$(hyprpicker -a -f hex) && [ -n \"$c\" ] && notify-send -a 'Color picker' \"$c\" 'Copied to the clipboard'"]);
    }

    PersistentProperties {
        id: state
        reloadableId: "toggles"
        onLoaded: root.followSchedule()
        property bool keepAwake: false
        property bool nightLight: false
        property bool gameMode: false
        property int savedProfile: PowerProfile.Balanced
        property bool savedDnd: false
    }

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
        function workspaces(style: string): void {
            const ids = WorkspaceStyles.styles.map(s => s.id);
            if (style === "next")
                Settings.workspaces.style = ids[(ids.indexOf(Settings.workspaces.style) + 1) % ids.length];
            else if (ids.includes(style))
                Settings.workspaces.style = style;
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            root.calendarRequested();
        }
    }

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
