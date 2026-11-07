import QtQuick
import QtQuick.Layouts
import qs.panels
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property var now: Weather.current
    readonly property var today: Weather.daily[0] ?? null
    onLiveChanged: if (live) Weather.refreshIfStale()
    Component.onCompleted: Weather.refreshIfStale()

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Desktop.showing = false;
            Weather.panelToggleRequested();
        }
    }

    Label {
        visible: !Weather.ready
        anchors.centerIn: parent
        width: parent.width - 32
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: Weather.loading ? "Loading weather…" : Weather.error || "No weather yet"
        color: Theme.overlay
    }

    component Now: ColumnLayout {
        spacing: 0
        Row {
            spacing: 4
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Weather.autoLocation ? "near_me" : "pin_drop"
                filled: Weather.autoLocation
                size: 14
                color: Theme.accent
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 150)
                text: Weather.place
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 1
                elide: Text.ElideRight
            }
        }
        Label {
            text: root.now ? Weather.temp(root.now.temp) : ""
            font.pixelSize: 56
            font.weight: Font.Light
        }
        Item { Layout.fillHeight: true }
        Icon {
            name: root.now ? Weather.icon(root.now.code, root.now.isDay) : ""
            size: 30
            color: Theme.accent
            gradientFill: true
            horizontalAlignment: Text.AlignLeft
        }
        Label {
            Layout.maximumWidth: 170
            text: root.now ? Weather.label(root.now.code) : ""
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Label {
            text: root.today ? "↑ " + Weather.temp(root.today.max) + "  ↓ " + Weather.temp(root.today.min) : ""
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 1
        }
    }

    Now {
        visible: Weather.ready && root.size === "small"
        anchors { fill: parent; margins: 20 }
    }

    RowLayout {
        visible: Weather.ready && root.size === "medium"
        anchors { fill: parent; margins: 20 }
        spacing: 12

        Now {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: 150
        }
        WeatherHourly {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            visible: Weather.hourly.length > 0
        }
    }

    ColumnLayout {
        visible: Weather.ready && root.size === "large"
        anchors { fill: parent; margins: 20 }
        spacing: 10

        Now {
            Layout.fillWidth: true
            Layout.preferredHeight: 170
        }
        WeatherHourly {
            Layout.fillWidth: true
            visible: Weather.hourly.length > 0
        }
        Repeater {
            model: Weather.daily.slice(1, 5)
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10
                Label {
                    Layout.preferredWidth: 44
                    text: Qt.formatDate(modelData.date, "ddd")
                    color: Theme.subtext
                }
                Icon {
                    name: Weather.icon(modelData.code, true)
                    size: 20
                    color: Theme.accent
                }
                Label {
                    Layout.fillWidth: true
                    text: modelData.precip >= 20 ? modelData.precip + "%" : ""
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 2
                }
                Label {
                    text: Weather.temp(modelData.min)
                    color: Theme.subtext
                }
                Label {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: Weather.temp(modelData.max)
                    font.weight: Font.DemiBold
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
