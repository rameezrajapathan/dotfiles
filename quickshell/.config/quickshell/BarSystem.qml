import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// CPU and memory use, read from /proc every two seconds. Click for the System tab.
Item {
    id: root
    signal clicked()

    property int cpu: 0
    property int memory: 0
    property var last: null

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            // cpu  user nice system idle iowait irq softirq steal
            const n = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = n[3] + n[4];
            const total = n.reduce((a, b) => a + b, 0);
            if (root.last && total > root.last.total)
                root.cpu = Math.round(100 * (1 - (idle - root.last.idle) / (total - root.last.total)));
            root.last = { idle, total };
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const kb = key => Number((t.match(new RegExp(key + ":\\s+(\\d+)")) ?? [0, 0])[1]);
            root.memory = Math.round(100 * (1 - kb("MemAvailable") / kb("MemTotal")));
        }
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon { name: "memory"; size: 18; color: Theme.accent }
        Label { text: root.cpu + "%" }
        Item { implicitWidth: 4 }
        Icon { name: "memory_alt"; size: 18; color: Theme.accent }
        Label { text: root.memory + "%" }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
