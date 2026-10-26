import QtQuick
import qs.panels
import qs.services
import qs.widgets

Item {
    id: root
    signal clicked()

    visible: Weather.ready
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Grid {
        id: row
        anchors.centerIn: parent
        columns: Theme.barVertical ? 1 : 2
        spacing: Theme.barVertical ? 0 : 4
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Icon {
            name: Weather.ready ? Weather.icon(Weather.current.code, Weather.current.isDay) : ""
            filled: true
            size: 18
            color: Theme.accent
            gradientFill: true
        }
        Label {
            text: Weather.ready ? Weather.temp(Weather.current.temp) : ""
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Tooltip {
        text: Weather.ready ? "Weather · " + [Weather.place, Weather.label(Weather.current.code)].filter(s => s).join(", ") : ""
        keys: "Super + Ctrl + W"
        side: Theme.awayFromBar
    }
}
