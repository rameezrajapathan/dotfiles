import QtQuick
import QtQuick.Layouts
import qs.panels
import qs.services
import qs.widgets

CCCard {
    id: root
    property var cc

    readonly property var now: Weather.current
    readonly property var today: Weather.daily[0] ?? null

    clickable: true
    onClicked: {
        cc.close();
        Weather.panelToggleRequested();
    }
    implicitHeight: column.implicitHeight + 32
    readonly property bool shown: cc?.open ?? false
    onShownChanged: if (shown) Weather.refreshIfStale()

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(16, 22) }
        spacing: 2

        Label {
            visible: !Weather.ready
            text: Weather.loading ? "Loading weather…" : Weather.error || "No weather yet"
            color: Theme.overlay
        }

        Row {
            visible: Weather.ready && Weather.place !== ""
            spacing: 5
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Weather.autoLocation ? "near_me" : "pin_drop"
                filled: Weather.autoLocation
                size: 14
                color: Theme.accent
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.place
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
            }
        }

        RowLayout {
            visible: Weather.ready
            Layout.fillWidth: true
            spacing: 14

            Label {
                text: root.now ? Weather.temp(root.now.temp) : ""
                font.pixelSize: 48
                font.weight: Font.Light
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    text: root.now ? Weather.label(root.now.code) : ""
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: root.today ? "↑ " + Weather.temp(root.today.max) + "   ↓ " + Weather.temp(root.today.min) : ""
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }
            Icon {
                name: root.now ? Weather.icon(root.now.code, root.now.isDay) : ""
                size: 48
                weight: 200
                color: Theme.accent
            }
        }

        WeatherHourly {
            visible: Weather.ready && Weather.hourly.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.leftMargin: -6
            Layout.rightMargin: -6
        }
    }
}
