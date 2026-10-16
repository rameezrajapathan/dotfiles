import QtQuick
import qs.services

Item {
    id: root
    property var columns: []

    readonly property var heights: ({
        header: 9, tiles: 24, tilesSmall: 22, sliders: 14, media: 11, mediaLarge: 17, notifications: 20,
        status: 5, system: 10, calendar: 24, weather: 14, updates: 8, actions: 6, tray: 4
    })
    readonly property real gap: 3
    readonly property real total: Math.max(1, ...columns.map(c => c.reduce((sum, id) => sum + (heights[id] ?? 8) + gap, 0)))
    readonly property real colWidth: Math.min(46, (width - 12 - (columns.length - 1) * 4) / Math.max(1, columns.length))
    readonly property real panelWidth: columns.length * colWidth + (columns.length - 1) * 4 + 12
    readonly property real scale: (height - 12) / total

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.panelWidth
        height: parent.height
        radius: Theme.round(8, width, height)
        color: Qt.alpha(Theme.base, 0.85)
        border.width: 1
        border.color: Qt.alpha(Theme.overlay, 0.25)

        Row {
            x: 6
            y: 6
            spacing: 4

            Repeater {
                model: root.columns

                Column {
                    id: column
                    required property var modelData
                    width: root.colWidth
                    spacing: root.gap * root.scale

                    Repeater {
                        model: column.modelData

                        Rectangle {
                            required property string modelData
                            width: column.width
                            height: Math.max(2, (root.heights[modelData] ?? 8) * root.scale)
                            radius: Theme.round(Math.min(4, height / 2), width, height)
                            color: modelData.startsWith("tiles") ? Qt.alpha(Theme.accent, 0.75)
                                : modelData === "header" ? Qt.alpha(Theme.text, 0.35)
                                : Qt.alpha(Theme.surface, 0.95)
                        }
                    }
                }
            }
        }
    }
}
