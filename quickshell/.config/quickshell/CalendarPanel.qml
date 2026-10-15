import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Full time and month calendar, dropping down under the clock. Arrows or scroll change the
// month, the month name returns to today. Clicks outside close it.
PanelWindow {
    id: root

    // Closes the other panels when this one opens, and the other way round
    Exclusive { panel: root }
    required property var bar

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()

    // 42 cells (6 weeks), weeks start on Monday
    readonly property var days: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() + 6) % 7;
        const cells = [];
        for (let i = 0; i < 42; i++)
            cells.push(new Date(year, month, 1 - offset + i));
        return cells;
    }

    // The window stays mapped until the close animation ends
    property bool open: false

    function toggle() {
        if (!open) {
            today = new Date();
            showToday();
            visible = true;
        }
        open = !open;
    }

    function showToday() {
        year = today.getFullYear();
        month = today.getMonth();
    }

    function shift(delta) {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-calendar"
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    // Drops down from under the bar, like the launcher
    Sheet {
        open: root.open
        kind: "calendar"
        sheetWidth: 320
        sheetHeight: content.implicitHeight + 28
        onClosed: root.visible = false
        onDismiss: root.open = false

        MouseArea {
            anchors.fill: parent
            onWheel: wheel => root.shift(wheel.angleDelta.y > 0 ? -1 : 1)
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
                enabled: root.visible
            }

            Label {
                text: Qt.formatTime(clock.date, "h:mm:ss AP")
                font.pixelSize: 32
                font.bold: true
            }

            Label {
                text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                color: Theme.subtext
            }

            RowLayout {
                Layout.fillWidth: true

                Pill {
                    icon: "chevron_left"
                    onClicked: root.shift(-1)
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(new Date(root.year, root.month, 1), "MMMM yyyy")
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showToday()
                    }
                }
                Pill {
                    icon: "chevron_right"
                    onClicked: root.shift(1)
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                    Label {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.overlay
                        font.pixelSize: Theme.fontSize - 2
                    }
                }

                Repeater {
                    model: root.days

                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool isToday: modelData.toDateString() === root.today.toDateString()
                        readonly property bool inMonth: modelData.getMonth() === root.month

                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: isToday ? Theme.accent : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: modelData.getDate()
                            font.bold: parent.isToday
                            color: parent.isToday ? Theme.accentText
                                : !parent.inMonth ? Theme.surface
                                : index % 7 >= 5 ? Theme.subtext
                                : Theme.text
                        }
                    }
                }
            }
        }
    }
}
