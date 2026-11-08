import Quickshell
import QtQuick
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    readonly property var glyphs: ({
        "0": ["111", "101", "101", "101", "111"],
        "1": ["110", "010", "010", "010", "111"],
        "2": ["111", "001", "111", "100", "111"],
        "3": ["111", "001", "111", "001", "111"],
        "4": ["101", "101", "111", "001", "001"],
        "5": ["111", "100", "111", "001", "111"],
        "6": ["111", "100", "111", "101", "111"],
        "7": ["111", "001", "001", "001", "001"],
        "8": ["111", "101", "111", "101", "111"],
        "9": ["111", "101", "111", "001", "111"],
        ":": ["0", "c", "0", "c", "0"]
    })

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: root.live
    }

    readonly property string hh: String(TimeDate.use24h ? clock.date.getHours() : clock.date.getHours() % 12 || 12).padStart(2, "0")
    readonly property string mm: Qt.formatTime(clock.date, "mm")
    readonly property string ss: Qt.formatTime(clock.date, "ss")
    readonly property bool tall: height > width * 0.75
    readonly property bool withSeconds: !tall && width / height > 3.2
    readonly property var lines: tall ? [hh, mm] : [hh + ":" + mm + (withSeconds ? ":" + ss : "")]
    readonly property bool blink: clock.date.getSeconds() % 2 === 0
    readonly property bool showDate: tall ? height > 330 : height > 180

    readonly property var cells: {
        const rows = [];
        lines.forEach((line, li) => {
            if (li > 0)
                rows.push(null);
            for (let r = 0; r < 5; r++) {
                let row = "";
                for (let i = 0; i < line.length; i++) {
                    if (i > 0)
                        row += "0";
                    row += glyphs[line[i]][r];
                }
                rows.push(row);
            }
        });
        const cols = Math.max(...rows.filter(r => r).map(r => r.length));
        const out = [];
        for (const r of rows)
            for (let c = 0; c < cols; c++)
                out.push(r ? (r[c] ?? "0") : "0");
        return { cols: cols, rows: rows.length, list: out };
    }

    readonly property real room: showDate ? 40 : 0
    readonly property real block: Math.max(3, Math.floor(Math.min((width - 36) / cells.cols, (height - 32 - room) / cells.rows)))
    readonly property real gap: Math.max(1, Math.round(block * 0.16))

    Grid {
        id: matrix
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.showDate ? -18 : 0
        columns: root.cells.cols
        spacing: 0

        Repeater {
            model: root.cells.list
            Item {
                required property string modelData
                required property int index
                readonly property bool lit: modelData === "1" || (modelData === "c" && root.blink)
                readonly property real along: root.cells.cols > 1 ? (index % root.cells.cols) / (root.cells.cols - 1) : 0
                width: root.block
                height: root.block
                Rectangle {
                    anchors { fill: parent; margins: root.gap / 2 }
                    radius: Theme.round(width * 0.28, width, height)
                    color: parent.lit ? (Theme.multiColor || Theme.gradientAccent ? Theme.mix(Theme.accent, Theme.accentEnd, parent.along) : Theme.accent) : Qt.alpha(Theme.text, 0.05)
                    Behavior on color { ColorAnimation { duration: Theme.ms(180) } }
                }
            }
        }
    }

    Label {
        visible: root.showDate
        anchors { horizontalCenter: parent.horizontalCenter; top: matrix.bottom; topMargin: 12 }
        text: Qt.formatDate(clock.date, "dddd d MMMM") + (TimeDate.use24h ? "" : "  ·  " + Qt.formatTime(clock.date, "AP"))
        color: Theme.subtext
        font.weight: Font.DemiBold
        font.letterSpacing: 0.5
    }
}
