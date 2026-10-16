import QtQuick
import qs.services

Item {
    id: root
    readonly property bool vertical: Theme.barVertical
    property int count: vertical ? 7 : 10
    readonly property var levels: Cava.grouped(count)
    readonly property real gap: vertical ? 2 : 3
    readonly property real stackLength: vertical ? height : width
    readonly property real reach: vertical ? width : height
    readonly property real barThickness: Math.max(2, (stackLength - gap * (count - 1)) / count)

    Grid {
        anchors.centerIn: parent
        columns: root.vertical ? 1 : root.count
        spacing: root.gap
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Repeater {
            model: root.count

            Rectangle {
                required property int index
                readonly property real level: Math.pow(root.levels[index] ?? 0, 0.7)
                readonly property real size: Math.max(root.barThickness, level * root.reach)

                width: root.vertical ? size : root.barThickness
                height: root.vertical ? root.barThickness : size
                radius: Theme.round(root.barThickness / 2, width, height)
                color: Theme.accent
                opacity: 0.45 + 0.55 * level
                Behavior on width { enabled: root.vertical; NumberAnimation { duration: Theme.ms(60) } }
                Behavior on height { enabled: !root.vertical; NumberAnimation { duration: Theme.ms(60) } }
            }
        }
    }
}
