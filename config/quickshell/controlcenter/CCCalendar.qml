import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

CCCard {
    id: root
    property var cc

    implicitHeight: column.implicitHeight + 28

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    property int offset: 0
    readonly property bool shown: cc?.open ?? false
    onShownChanged: if (shown) offset = 0

    readonly property date month: new Date(clock.date.getFullYear(), clock.date.getMonth() + offset, 1)
    readonly property int weekStart: Settings.datetime.weekStart
    readonly property var days: {
        const first = month;
        const lead = (first.getDay() - weekStart + 7) % 7;
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - lead);
        const count = Math.ceil((lead + new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()) / 7) * 7;
        const out = [];
        for (let i = 0; i < count; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === first.getMonth(),
                today: d.toDateString() === clock.date.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return out;
    }

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: Qt.formatDate(root.month, root.month.getFullYear() === clock.date.getFullYear() ? "MMMM" : "MMMM yyyy")
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.cc.close();
                        Toggles.calendarRequested();
                    }
                }
            }
            CCIconButton { implicitWidth: 28; implicitHeight: 28; tone: "flat"; icon: "chevron_left"; iconSize: 18; onClicked: root.offset-- }
            CCIconButton { implicitWidth: 28; implicitHeight: 28; tone: "flat"; icon: "chevron_right"; iconSize: 18; onClicked: root.offset++ }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 2
            columnSpacing: 2

            Repeater {
                model: 7
                Label {
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((index + root.weekStart) % 7, Locale.NarrowFormat)
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 2
                }
            }
            Repeater {
                model: root.days
                Item {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 28

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        visible: modelData.today
                        color: Theme.accent
                    }
                    Label {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: modelData.today ? Theme.accentText : !modelData.inMonth ? Qt.alpha(Theme.overlay, 0.6)
                            : modelData.weekend ? Theme.overlay : Theme.text
                        font.weight: modelData.today ? Font.DemiBold : Font.Normal
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
            }
        }

        RowLayout {
            visible: Meetings.next !== null
            Layout.fillWidth: true
            spacing: 6
            Icon { name: "event"; size: 16; color: Theme.accent }
            Label {
                Layout.fillWidth: true
                text: Meetings.next ? (Meetings.ongoing ? "Now: " : Qt.formatTime(new Date(Meetings.next.start * 1000), Settings.bar.clock24 ? "HH:mm" : "h:mm AP") + "  ") + Meetings.next.title : ""
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
        }
    }
}
