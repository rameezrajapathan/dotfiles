import QtQuick
import qs.services

Item {
    id: root
    required property Item target
    property string edge: "bottom"
    property int count: 1
    property bool active: false
    readonly property string style: Dock.indicator
    readonly property color color: Dock.indicatorColor
    readonly property bool vertical: edge !== "bottom"
    readonly property real mark: style === "line" ? Math.max(8, target.width * 0.28 / Math.max(1, count)) : 5
    readonly property real thin: style === "line" ? 3 : 5

    anchors.fill: parent

    Grid {
        visible: root.style === "dot" || root.style === "line"
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        spacing: 3
        x: root.edge === "bottom" ? (parent.width - width) / 2
            : root.edge === "left" ? -(Dock.pad + width) / 2 - 1
            : parent.width + (Dock.pad - width) / 2 + 1
        y: root.edge === "bottom" ? parent.height + (Dock.pad - height) / 2 + 1 : (parent.height - height) / 2

        Repeater {
            model: root.count

            Rectangle {
                width: root.vertical ? root.thin : root.mark * (root.active && root.style === "line" && root.count === 1 ? 1.6 : 1)
                height: root.vertical ? root.mark * (root.active && root.style === "line" && root.count === 1 ? 1.6 : 1) : root.thin
                radius: Math.min(width, height) / 2
                color: root.color
                opacity: root.active ? 1 : 0.6
                Behavior on width { NumberAnimation { duration: Theme.ms(160) } }
                Behavior on height { NumberAnimation { duration: Theme.ms(160) } }
            }
        }
    }

    Rectangle {
        visible: root.style === "ring" || root.style === "pill"
        z: -1
        anchors.fill: parent
        anchors.margins: root.style === "ring" ? -3 : -4
        radius: Theme.round(width * 0.3, width, height)
        color: root.style === "pill" ? Qt.alpha(root.color, root.active ? 0.3 : 0.18) : "transparent"
        border.width: root.style === "ring" ? 2 : 0
        border.color: Qt.alpha(root.color, root.active ? 1 : 0.6)
    }
}
