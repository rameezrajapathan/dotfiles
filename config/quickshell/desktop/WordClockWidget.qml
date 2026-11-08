import Quickshell
import QtQuick
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    readonly property var grid: [
        "ITLISASAMPM",
        "ACQUARTERDC",
        "TWENTYFIVEX",
        "HALFSTENFTO",
        "PASTERUNINE",
        "ONESIXTHREE",
        "FOURFIVETWO",
        "EIGHTELEVEN",
        "SEVENTWELVE",
        "TENSEOCLOCK"
    ]
    readonly property var words: ({
        it: [0, 0, 2], is: [0, 3, 2], a: [1, 0, 1], quarter: [1, 2, 7], twenty: [2, 0, 6], fiveM: [2, 6, 4],
        half: [3, 0, 4], tenM: [3, 5, 3], to: [3, 9, 2], past: [4, 0, 4], oclock: [9, 5, 6],
        h1: [5, 0, 3], h2: [6, 8, 3], h3: [5, 6, 5], h4: [6, 0, 4], h5: [6, 4, 4], h6: [5, 3, 3],
        h7: [8, 0, 5], h8: [7, 0, 5], h9: [4, 7, 4], h10: [9, 0, 3], h11: [7, 5, 6], h12: [8, 5, 6]
    })

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.live
    }

    readonly property var lit: {
        const d = clock.date;
        const m = Math.floor(d.getMinutes() / 5) * 5;
        const on = ["it", "is"];
        const parts = {
            0: ["oclock"], 5: ["fiveM", "past"], 10: ["tenM", "past"], 15: ["a", "quarter", "past"],
            20: ["twenty", "past"], 25: ["twenty", "fiveM", "past"], 30: ["half", "past"],
            35: ["twenty", "fiveM", "to"], 40: ["twenty", "to"], 45: ["a", "quarter", "to"],
            50: ["tenM", "to"], 55: ["fiveM", "to"]
        }[m];
        let h = d.getHours() % 12;
        if (m >= 35)
            h = (h + 1) % 12;
        on.push(...parts, "h" + (h === 0 ? 12 : h));
        const set = {};
        for (const w of on) {
            const [r, c, n] = words[w];
            for (let i = 0; i < n; i++)
                set[r * 11 + c + i] = true;
        }
        return set;
    }
    readonly property int extra: clock.date.getMinutes() % 5

    readonly property real cellW: (width - 40) / 11
    readonly property real cellH: (height - 40) / 10
    readonly property real letter: Math.max(7, Math.min(cellW * 1.05, cellH * 0.8))

    Grid {
        anchors.centerIn: parent
        columns: 11

        Repeater {
            model: 110
            Text {
                required property int index
                readonly property bool on: root.lit[index] === true
                width: root.cellW
                height: root.cellH
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.grid[Math.floor(index / 11)][index % 11]
                color: on ? Theme.text : Qt.alpha(Theme.text, 0.13)
                font.family: Theme.displayFont
                font.pixelSize: root.letter
                font.weight: on ? Font.Bold : Font.Normal
                Behavior on color { ColorAnimation { duration: Theme.ms(400) } }
            }
        }
    }

    Repeater {
        model: 4
        Rectangle {
            required property int index
            width: 6
            height: 6
            radius: 3
            x: index % 2 === 0 ? 12 : root.width - 18
            y: index < 2 ? 12 : root.height - 18
            color: index < root.extra ? Theme.accent : Qt.alpha(Theme.text, 0.13)
        }
    }
}
