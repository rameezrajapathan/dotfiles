import QtQuick

// Condition icon and temperature next to the clock in the bar's pill; click for WeatherPanel.
// Hidden until the first forecast arrives.
Item {
    id: root
    signal clicked()

    visible: Weather.ready
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // Icon over temperature on a side bar
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
}
