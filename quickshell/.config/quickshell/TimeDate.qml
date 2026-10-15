pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// System clock settings through timedatectl (time zone, network time, manual time; changing them
// asks for the admin password through the polkit agent), the list of time zones, detecting the
// zone from the network (ipinfo.io), and UTC offsets for the world clocks (Settings.datetime).
Singleton {
    id: root

    property string timezone: ""
    property bool ntp: true
    property bool synced: false
    property bool canNtp: true
    property var zones: []
    // Zone → offset from UTC in minutes, for the world clocks and the system zone
    property var offsets: ({})
    // Last error from timedatectl, shown on the Date & time page
    property string error: ""
    property bool busy: false
    // The shell's own clock still runs in the old zone after a change, until it restarts
    property int shellOffset: -new Date().getTimezoneOffset()
    readonly property bool shellStale: offsets[timezone] !== undefined && offsets[timezone] !== shellOffset

    function refresh() {
        shellOffset = -new Date().getTimezoneOffset();
        show.running = true;
    }

    function loadZones() {
        if (zones.length === 0)
            list.running = true;
    }

    function run(args) {
        error = "";
        busy = true;
        change.command = ["timedatectl"].concat(args);
        change.running = true;
    }
    function setTimezone(zone) { run(["set-timezone", zone]); }
    function setNtp(on) { run(["set-ntp", on ? "true" : "false"]); }
    // "YYYY-MM-DD HH:MM[:SS]"; only works with network time off
    function setTime(text) { run(["set-time", text]); }

    function detectTimezone() {
        error = "";
        detect.running = true;
    }

    // "14:05" (or "2:05 PM") in `zone`, from its offset
    function timeIn(zone, date) {
        const off = offsets[zone];
        if (off === undefined)
            return "";
        const d = new Date(date.getTime() + (off + date.getTimezoneOffset()) * 60000);
        return Qt.formatTime(d, Settings.bar.clock24 ? "HH:mm" : "h:mm AP");
    }
    // "+5:30", relative to the system zone
    function difference(zone) {
        const off = offsets[zone], here = offsets[timezone];
        if (off === undefined || here === undefined)
            return "";
        const m = off - here;
        if (m === 0)
            return "Same time";
        const h = Math.floor(Math.abs(m) / 60), min = Math.abs(m) % 60;
        return (m > 0 ? "+" : "−") + h + (min ? ":" + String(min).padStart(2, "0") : "") + " h";
    }
    // "Asia/Kolkata" → "Kolkata"
    function city(zone) {
        return zone.slice(zone.lastIndexOf("/") + 1).replace(/_/g, " ");
    }

    Component.onCompleted: refresh()

    // Offsets change with daylight saving; recheck every 10 minutes
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: show
        command: ["timedatectl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        f[line.slice(0, i)] = line.slice(i + 1);
                }
                root.timezone = f.Timezone ?? "";
                root.ntp = f.NTP === "yes";
                root.synced = f.NTPSynchronized === "yes";
                root.canNtp = f.CanNTP !== "no";
                offsetsProc.running = true;
            }
        }
    }

    // Offsets for the system zone and every world clock
    Process {
        id: offsetsProc
        command: ["sh", "-c", "for z; do printf '%s %s\\n' \"$z\" \"$(TZ=\"$z\" date +%z)\"; done", "sh"]
            .concat([root.timezone].concat((Settings.datetime.worldClocks ?? []).map(c => c.zone)).filter(z => z))
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const line of text.trim().split("\n")) {
                    const m = line.match(/^(\S+) ([+-])(\d\d)(\d\d)$/);
                    if (m)
                        o[m[1]] = (m[2] === "-" ? -1 : 1) * (Number(m[3]) * 60 + Number(m[4]));
                }
                root.offsets = o;
            }
        }
    }
    Connections {
        target: Settings.datetime
        function onWorldClocksChanged() { offsetsProc.running = true; }
    }

    Process {
        id: list
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: root.zones = text.split("\n").filter(z => z)
        }
    }

    Process {
        id: change
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim()
        }
        onExited: code => {
            root.busy = false;
            if (code !== 0 && !root.error)
                root.error = "timedatectl failed";
            root.refresh();
        }
    }

    Process {
        id: detect
        command: ["curl", "-fsS", "--max-time", "8", "https://ipinfo.io/timezone"]
        stdout: StdioCollector {
            onStreamFinished: {
                const zone = text.trim();
                if (/^[A-Za-z_]+\/[A-Za-z_\/+-]+$/.test(zone)) {
                    if (zone !== root.timezone)
                        root.setTimezone(zone);
                } else {
                    root.error = "Couldn't find your time zone";
                }
            }
        }
        onExited: code => { if (code !== 0) root.error = "Couldn't reach ipinfo.io"; }
    }
}
