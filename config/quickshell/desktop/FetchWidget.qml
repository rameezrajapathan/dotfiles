import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    property var info: ({})
    property string uptime: ""

    readonly property string mono: Settings.appearance.monoFont
    readonly property bool wide: width >= 320
    readonly property var rows: [
        ["OS", info.os], ["Kernel", info.kernel], ["Uptime", uptime], ["Packages", info.packages],
        ["Shell", info.shell], ["WM", info.wm], ["CPU", info.cpu], ["Memory", SysStats.memTotal > 0 ? SysStats.gib(SysStats.memUsed) + " / " + SysStats.gib(SysStats.memTotal) + " GiB" : info.memory]
    ].filter(r => r[1])
    readonly property int fitRows: Math.max(1, Math.floor((height - (wide ? 70 : 150)) / (Theme.fontSize + 9)))

    Process {
        running: true
        command: ["sh", "-c", `
            . /etc/os-release 2>/dev/null
            printf 'os=%s\\n' "\${PRETTY_NAME:-Linux}"
            printf 'logo=%s\\n' "\${LOGO:-\${ID:-linux}}"
            printf 'kernel=%s\\n' "$(uname -r)"
            printf 'host=%s\\n' "$(cat /etc/hostname 2>/dev/null || uname -n)"
            if command -v pacman >/dev/null; then n=$(pacman -Qq | wc -l); printf 'packages=%s (pacman)\\n' "$n"
            elif command -v rpm >/dev/null; then n=$(rpm -qa | wc -l); printf 'packages=%s (rpm)\\n' "$n"
            elif command -v dpkg-query >/dev/null; then n=$(dpkg-query -f '.\\n' -W | wc -l); printf 'packages=%s (dpkg)\\n' "$n"; fi
            command -v flatpak >/dev/null && printf 'flatpaks=%s\\n' "$(flatpak list --app 2>/dev/null | wc -l)"
            printf 'shell=%s\\n' "$(basename "\${SHELL:-sh}")"
            printf 'wm=Hyprland %s\\n' "$(hyprctl version -j 2>/dev/null | sed -n 's/.*"tag": *"v\\{0,1\\}\\([^"]*\\)".*/\\1/p' | head -1)"
            printf 'cpu=%s\\n' "$(sed -n 's/^model name\\s*: *//p' /proc/cpuinfo | head -1 | sed 's/([^)]*)//g; s/ CPU//; s/ \\{2,\\}/ /g; s/ [0-9]*-Core Processor//')"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        o[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                if (o.flatpaks && o.flatpaks !== "0")
                    o.packages = (o.packages ? o.packages + ", " : "") + o.flatpaks + " (flatpak)";
                root.info = o;
            }
        }
    }

    FileView {
        id: up
        path: "/proc/uptime"
        onLoaded: {
            const mins = Math.floor(parseFloat(text().split(" ")[0]) / 60);
            const d = Math.floor(mins / 1440), h = Math.floor(mins / 60) % 24, m = mins % 60;
            root.uptime = (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m";
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.live
        onTriggered: up.reload()
    }

    property bool watching: false
    function updateWatch() {
        const want = live && visible;
        if (want !== watching) {
            watching = want;
            SysStats.watch(want);
        }
    }
    onLiveChanged: updateWatch()
    Component.onCompleted: updateWatch()
    Component.onDestruction: if (watching) SysStats.watch(false)

    GridLayout {
        anchors { fill: parent; margins: 18 }
        columns: root.wide ? 2 : 1
        columnSpacing: 18
        rowSpacing: 8

        IconImage {
            Layout.alignment: root.wide ? Qt.AlignTop : Qt.AlignHCenter
            Layout.topMargin: root.wide ? 4 : 0
            implicitSize: root.wide ? Math.min(110, root.height - 60) : Math.min(72, root.height * 0.3)
            source: Quickshell.iconPath(root.info.logo ?? "", "distributor-logo-archlinux")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            Text {
                Layout.alignment: root.wide ? Qt.AlignLeft : Qt.AlignHCenter
                text: "<font color='" + Theme.accent + "'>" + User.userName + "</font>@<font color='" + Theme.accent + "'>" + (root.info.host ?? "") + "</font>"
                textFormat: Text.StyledText
                color: Theme.text
                font.family: root.mono
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Theme.text, 0.15)
                Layout.bottomMargin: 2
            }
            Repeater {
                model: root.rows.slice(0, root.fitRows)
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.preferredWidth: root.wide ? 78 : 66
                        text: modelData[0]
                        color: Theme.accent
                        font.family: root.mono
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData[1]
                        color: Theme.text
                        font.family: root.mono
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                }
            }
            Item { Layout.fillHeight: true }
            Row {
                visible: root.height > 200
                spacing: 4
                Repeater {
                    model: [Theme.red, Theme.yellow, Theme.green, Theme.accent, Theme.accent2, Theme.accent3, Theme.special, Theme.text]
                    Rectangle {
                        required property color modelData
                        width: 18
                        height: 10
                        radius: Theme.round(3, width, height)
                        color: modelData
                    }
                }
            }
        }
    }
}
