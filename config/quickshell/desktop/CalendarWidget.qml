import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property int weekStart: Settings.datetime.weekStart
    readonly property var days: {
        const today = clock.date;
        const first = new Date(today.getFullYear(), today.getMonth(), 1);
        const lead = (first.getDay() - weekStart + 7) % 7;
        const count = Math.ceil((lead + new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()) / 7) * 7;
        const out = [];
        for (let i = 0; i < count; i++) {
            const d = new Date(today.getFullYear(), today.getMonth(), 1 - lead + i);
            out.push({ day: d.getDate(), inMonth: d.getMonth() === today.getMonth(), today: d.toDateString() === today.toDateString(), weekend: d.getDay() === 0 || d.getDay() === 6 });
        }
        return out;
    }
    readonly property var upcoming: Meetings.meetings.filter(m => m.end > Meetings.now).slice(0, 4)

    function timeOf(m) {
        return m.start <= Meetings.now ? "Now" : Qt.formatTime(new Date(m.start * 1000), Settings.bar.clock24 ? "HH:mm" : "h:mm AP");
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Desktop.showing = false;
            Toggles.calendarRequested();
        }
    }

    component Today: ColumnLayout {
        spacing: 0
        Label {
            text: Qt.formatDate(clock.date, "dddd").toUpperCase()
            color: Theme.red
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Bold
            font.letterSpacing: 0.8
        }
        Text {
            text: clock.date.getDate()
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 68
            font.weight: Font.Light
        }
        Item { Layout.fillHeight: true }
        Label {
            Layout.fillWidth: true
            text: Meetings.next ? Meetings.label(Meetings.next) : "No more events today"
            color: Meetings.next ? Theme.text : Theme.overlay
            font.pixelSize: Theme.fontSize - 1
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    component Month: GridLayout {
        id: month
        property real cellHeight: 22
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: 7
            Label {
                required property int index
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((index + root.weekStart) % 7, Locale.NarrowFormat)
                color: Theme.overlay
                font.pixelSize: Theme.fontSize - 3
                font.weight: Font.DemiBold
            }
        }
        Repeater {
            model: root.days
            Item {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: month.cellHeight
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, month.cellHeight)
                    height: width
                    radius: width / 2
                    visible: modelData.today
                    color: Theme.red
                }
                Label {
                    anchors.centerIn: parent
                    text: modelData.day
                    color: modelData.today ? "white" : !modelData.inMonth ? Qt.alpha(Theme.overlay, 0.5) : modelData.weekend ? Theme.subtext : Theme.text
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: modelData.today ? Font.Bold : Font.Normal
                }
            }
        }
    }

    Today {
        visible: root.size === "small"
        anchors { fill: parent; margins: 20 }
    }

    RowLayout {
        visible: root.size === "medium"
        anchors { fill: parent; margins: 18 }
        spacing: 16
        Today {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: 140
        }
        Month {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            cellHeight: 25
        }
    }

    ColumnLayout {
        visible: root.size === "large"
        anchors { fill: parent; margins: 20 }
        spacing: 10

        Label {
            text: Qt.formatDate(clock.date, "MMMM yyyy")
            color: Theme.red
            font.pixelSize: Theme.fontSize + 2
            font.weight: Font.Bold
        }
        Month {
            Layout.fillWidth: true
            cellHeight: 34
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.alpha(Theme.text, 0.08)
        }
        Label {
            visible: root.upcoming.length === 0
            text: "Nothing coming up"
            color: Theme.overlay
        }
        Repeater {
            model: root.upcoming
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                    implicitWidth: 3
                    implicitHeight: 30
                    radius: 2
                    color: Theme.accent
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        Layout.fillWidth: true
                        text: modelData.title
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Label {
                        text: root.timeOf(modelData)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
