import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    Exclusive { panel: root }
    required property var bar

    property date today: new Date()
    property int year: today.getFullYear()
    property int month: today.getMonth()

    readonly property int weekStart: Settings.datetime.weekStart
    readonly property var days: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - weekStart + 7) % 7;
        const cells = [];
        for (let i = 0; i < 42; i++)
            cells.push(new Date(year, month, 1 - offset + i));
        return cells;
    }

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
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 24) }
            spacing: 10

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
                enabled: root.visible
            }

            Label {
                text: Qt.formatTime(clock.date, Settings.bar.clock24 ? "HH:mm:ss" : "h:mm:ss AP")
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
                columns: Settings.datetime.weekNumbers ? 8 : 7
                rowSpacing: 2
                columnSpacing: 2

                Label {
                    visible: Settings.datetime.weekNumbers
                    text: "Wk"
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 3
                }
                Repeater {
                    model: [0, 1, 2, 3, 4, 5, 6].map(i => ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][(i + root.weekStart) % 7])

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
                    model: root.days.length + (Settings.datetime.weekNumbers ? 6 : 0)

                    Loader {
                        required property int index
                        readonly property int cols: Settings.datetime.weekNumbers ? 8 : 7
                        readonly property bool weekCell: Settings.datetime.weekNumbers && index % 8 === 0
                        readonly property int day: Settings.datetime.weekNumbers ? index - Math.floor(index / 8) - 1 : index
                        Layout.fillWidth: !weekCell
                        sourceComponent: weekCell ? weekNumber : dayCell
                        property var dayDate: root.days[weekCell ? day + 1 + (8 - root.weekStart) % 7 : day]
                        property int dayIndex: day
                    }
                }
            }

            Rectangle {
                visible: Settings.datetime.worldClocks.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Qt.alpha(Theme.overlay, 0.3)
            }
            Repeater {
                model: Settings.datetime.worldClocks

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8

                    Icon { name: "language"; size: 16; color: Theme.accent }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.label || TimeDate.city(modelData.zone)
                        elide: Text.ElideRight
                    }
                    Label {
                        text: TimeDate.difference(modelData.zone)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                    }
                    Label {
                        text: TimeDate.timeIn(modelData.zone, clock.date)
                        font.weight: Font.DemiBold
                    }
                }
            }

            Component {
                id: weekNumber
                Label {
                    text: {
                        const d = new Date(parent.dayDate);
                        const t = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7);
                        const jan4 = new Date(t.getFullYear(), 0, 4);
                        return 1 + Math.round(((t - jan4) / 86400000 - 3 + (jan4.getDay() + 6) % 7) / 7);
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 3
                    height: 30
                }
            }

            Component {
                id: dayCell
                    Rectangle {
                        readonly property var modelData: parent.dayDate
                        readonly property int index: parent.dayIndex
                        readonly property bool isToday: modelData.toDateString() === root.today.toDateString()
                        readonly property bool inMonth: modelData.getMonth() === root.month

                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.round(6, width, height)
                        color: isToday ? Theme.accent : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: modelData.getDate()
                            font.bold: parent.isToday
                            color: parent.isToday ? Theme.accentText
                                : !parent.inMonth ? Theme.surface
                                : modelData.getDay() % 6 === 0 ? Theme.subtext
                                : Theme.text
                        }
                    }
                }
            }
        }
    }
