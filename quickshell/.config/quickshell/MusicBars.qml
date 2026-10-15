import QtQuick

// Small cava spectrum for the bar's pill, mirrored around the middle; fills whatever size it's
// given (the clock's slot).
Item {
    id: root
    property int count: 10
    readonly property var levels: Cava.grouped(count)
    readonly property real gap: 3
    readonly property real barWidth: Math.max(2, (width - gap * (count - 1)) / count)

    Row {
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: root.count

            Rectangle {
                required property int index
                // Lifted a little: quiet parts would barely move at this size
                readonly property real level: Math.pow(root.levels[index] ?? 0, 0.7)

                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                height: Math.max(width, level * root.height)
                radius: width / 2
                color: Theme.accent
                opacity: 0.45 + 0.55 * level
                Behavior on height { NumberAnimation { duration: 60 } }
            }
        }
    }
}
