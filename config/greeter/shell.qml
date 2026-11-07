import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    readonly property string dir: Quickshell.env("PIKADOTS_GREETER_DIR") || "/var/lib/pikadots-greeter"
    property var sessions: []
    property var users: []
    property bool leaving: false

    FileView {
        id: themeFile
        path: root.dir + "/theme.json"
        printErrors: false

        JsonAdapter {
            id: themeData
            property string base: "#1e1e2e"
            property string surface: "#313244"
            property string overlay: "#6c7086"
            property string text: "#cdd6f4"
            property string subtext: "#a6adc8"
            property string accent: "#89b4fa"
            property string accentText: "#1e1e2e"
            property string red: "#f38ba8"
            property string yellow: "#f9e2af"
            property string font: "Fira Sans"
            property string displayFont: "Fira Sans"
            property string iconStyle: "Rounded"
            property bool clock24: false
            property real blur: 0.85
            property real roundness: 1
            property string wallpaper: ""
            property string user: ""
            property string session: "hyprland.desktop"
        }
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: {
            const out = [];
            for (const line of text().split("\n")) {
                const f = line.split(":");
                const uid = parseInt(f[2]);
                if (f.length < 7 || uid < 1000 || uid >= 60000 || /(nologin|false)$/.test(f[6]))
                    continue;
                out.push({ name: f[0], full: (f[4] || "").split(",")[0] || f[0] });
            }
            root.users = out;
        }
    }

    Process {
        running: true
        command: ["sh", "-c", 'for f in /usr/share/wayland-sessions/*.desktop; do [ -e "$f" ] || continue; grep -qi "^NoDisplay=true" "$f" && continue; printf "%s\\t%s\\t%s\\n" "${f##*/}" "$(sed -n "s/^Name=//p" "$f" | head -1)" "$(sed -n "s/^Exec=//p" "$f" | head -1)"; done']
        stdout: StdioCollector {
            onStreamFinished: root.sessions = text.split("\n").filter(l => l).map(l => {
                const p = l.split("\t");
                return { file: p[0], name: p[1] || p[0], exec: p[2] };
            }).filter(s => s.exec)
        }
    }

    Variants {
        model: Quickshell.screens
        Greeter {
            theme: themeData
            dir: root.dir
            users: root.users
            sessions: root.sessions
            leaving: root.leaving
            onLeave: root.leaving = true
        }
    }
}
