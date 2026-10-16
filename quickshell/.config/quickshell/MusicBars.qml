import QtQuick

// Small cava spectrum for the bar's pill, mirrored around the middle; fills whatever size it's
// given (the clock's slot). On a side bar the slot is narrow and tall, so the bars lie across it,
// stacked top to bottom, and grow sideways.
Item {
    id: root
    readonly property bool vertical: Theme.barVertical
    property int count: vertical ? 7 : 10
    readonly property var levels: Cava.grouped(count)
    readonly property real gap: vertical ? 2 : 3
    // Along the stack: the slot's width on a top bar, its height on a side one
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
                // Lifted a little: quiet parts would barely move at this size
                readonly property real level: Math.pow(root.levels[index] ?? 0, 0.7)
                readonly property real size: Math.max(root.barThickness, level * root.reach)

                width: root.vertical ? size : root.barThickness
                height: root.vertical ? root.barThickness : size
                radius: root.barThickness / 2
                color: Theme.accent
                opacity: 0.45 + 0.55 * level
                Behavior on width { enabled: root.vertical; NumberAnimation { duration: Theme.ms(60) } }
                Behavior on height { enabled: !root.vertical; NumberAnimation { duration: Theme.ms(60) } }
            }
        }
    }
}
