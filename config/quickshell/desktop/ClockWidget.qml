import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property bool clock24: Settings.bar.clock24
    readonly property var zones: (Settings.datetime.worldClocks ?? []).slice(0, size === "large" ? 4 : 3)

    SystemClock {
        id: clock
        precision: root.size === "medium" ? SystemClock.Minutes : SystemClock.Seconds
        enabled: root.live
    }

    component Hand: Item {
        property real length: 0.3
        property real thickness: 4
        property color tint: Theme.text
        property real angle: 0
        property real diameter: 160
        anchors.fill: parent
        rotation: angle
        Rectangle {
            x: (parent.width - width) / 2
            y: parent.height / 2 - height + thickness
            width: thickness
            height: diameter * length + thickness
            radius: thickness / 2
            color: tint
            antialiasing: true
        }
    }

    component Dial: Item {
        id: dial
        property real diameter: 160
        readonly property date now: clock.date
        width: diameter
        height: diameter

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.alpha(Theme.surface, 0.35)
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.08)
        }

        Repeater {
            model: 12
            Item {
                required property int index
                anchors.fill: parent
                rotation: index * 30
                Rectangle {
                    x: (parent.width - width) / 2
                    y: dial.diameter * 0.06
                    width: index % 3 === 0 ? 3 : 2
                    height: index % 3 === 0 ? dial.diameter * 0.08 : dial.diameter * 0.045
                    radius: width / 2
                    color: index % 3 === 0 ? Theme.text : Theme.overlay
                }
            }
        }

        Hand {
            diameter: dial.diameter
            length: 0.26
            thickness: Math.max(4, dial.diameter * 0.035)
            angle: (dial.now.getHours() % 12) * 30 + dial.now.getMinutes() * 0.5
        }
        Hand {
            diameter: dial.diameter
            length: 0.38
            thickness: Math.max(3, dial.diameter * 0.025)
            angle: dial.now.getMinutes() * 6 + dial.now.getSeconds() * 0.1
        }
        Hand {
            diameter: dial.diameter
            length: 0.42
            thickness: 2
            tint: Theme.accent
            angle: dial.now.getSeconds() * 6
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.max(8, dial.diameter * 0.06)
            height: width
            radius: width / 2
            color: Theme.accent
        }
    }

    Dial {
        visible: root.size === "small"
        anchors.centerIn: parent
        diameter: Math.min(root.width, root.height) - 28
    }

    ColumnLayout {
        visible: root.size === "medium"
        anchors { fill: parent; margins: 22 }
        spacing: 0

        Label {
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            color: Theme.accent
            font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true
            text: Qt.formatTime(clock.date, root.clock24 ? "HH:mm" : "h:mm")
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 76
            font.weight: Font.Light
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: 40
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            visible: root.zones.length > 0
            Layout.fillWidth: true
            spacing: 16
            Repeater {
                model: root.zones
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        Layout.fillWidth: true
                        text: modelData.label || TimeDate.city(modelData.zone)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                        elide: Text.ElideRight
                    }
                    Label {
                        text: TimeDate.timeIn(modelData.zone, clock.date)
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    ColumnLayout {
        visible: root.size === "large"
        anchors { fill: parent; margins: 24 }
        spacing: 12

        Dial {
            Layout.alignment: Qt.AlignHCenter
            diameter: Math.min(parent.width, parent.height - 110)
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, root.clock24 ? "HH:mm" : "h:mm AP") + "  ·  " + Qt.formatDate(clock.date, "ddd d MMM")
            font.pixelSize: Theme.fontSize + 3
            font.weight: Font.DemiBold
        }
        RowLayout {
            visible: root.zones.length > 0
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            Repeater {
                model: root.zones
                Label {
                    required property var modelData
                    text: (modelData.label || TimeDate.city(modelData.zone)) + "  " + TimeDate.timeIn(modelData.zone, clock.date)
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
