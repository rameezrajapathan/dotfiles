pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var meetings: []
    property var notified: ({})
    readonly property real now: clock.date.getTime() / 1000
    readonly property var next: meetings.find(m => m.end > now && m.start - now < 12 * 3600) ?? null
    readonly property bool ongoing: next !== null && next.start <= now

    function label(m) {
        if (!m)
            return "";
        if (m.start <= now)
            return "Now: " + m.title;
        const mins = Math.round((m.start - now) / 60);
        return m.title + " in " + (mins < 60 ? mins + " min" : Math.floor(mins / 60) + " h " + (mins % 60) + " min");
    }

    function join(m) {
        Quickshell.execDetached(["xdg-open", m.join || "https://outlook.office.com/calendar"]);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: {
            const m = root.meetings.find(m => m.start - root.now > 0 && m.start - root.now <= 300);
            const key = m ? m.title + m.start : "";
            if (m && !root.notified[key]) {
                root.notified[key] = true;
                Quickshell.execDetached(["notify-send", "-a", "Calendar", "-i", "x-office-calendar",
                    m.title + " in " + Math.round((m.start - root.now) / 60) + " min",
                    m.join ? "Click the meeting in the bar to join" : m.location]);
            }
        }
    }

    Process {
        id: reader
        command: [Quickshell.env("HOME") + "/.local/bin/pikadots-meetings"]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn(text.trim())
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.meetings = JSON.parse(text);
                } catch (e) {
                    root.meetings = [];
                }
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }
}
