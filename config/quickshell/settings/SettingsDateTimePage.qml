import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Date & time"
    subtitle: "Time zone, clock and formats. Changing the zone or clock asks for your password."

    readonly property date sample: new Date()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: root.shown
    }

    Component.onCompleted: TimeDate.refresh()
    onShownChanged: if (shown) TimeDate.refresh()

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: nowRow.implicitHeight + 40
        radius: 18
        color: Qt.alpha(Theme.accent, 0.12)

        RowLayout {
            id: nowRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 22 }
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatTime(clock.date, Settings.bar.clock24 ? "HH:mm:ss" : "h:mm:ss AP")
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 40
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
                Label {
                    Layout.fillWidth: true
                    text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize + 1
                }
            }
            ColumnLayout {
                spacing: 4
                Label {
                    Layout.alignment: Qt.AlignRight
                    text: TimeDate.city(TimeDate.timezone)
                    font.weight: Font.DemiBold
                    font.pixelSize: Theme.fontSize + 2
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    text: TimeDate.timezone
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 4
                    Icon {
                        name: TimeDate.synced ? "sync" : "sync_problem"
                        size: 15
                        color: TimeDate.synced ? Theme.green : Theme.yellow
                    }
                    Label {
                        text: TimeDate.ntp ? (TimeDate.synced ? "Synced with network time" : "Not synced yet") : "Set by hand"
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }
        }
    }

    Rectangle {
        visible: TimeDate.shellStale || TimeDate.error !== ""
        Layout.fillWidth: true
        implicitHeight: noticeRow.implicitHeight + 20
        radius: 14
        color: Qt.alpha(TimeDate.error ? Theme.red : Theme.yellow, 0.14)

        RowLayout {
            id: noticeRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 14 }
            spacing: 10
            Icon {
                name: TimeDate.error ? "error" : "restart_alt"
                color: TimeDate.error ? Theme.red : Theme.yellow
            }
            Label {
                Layout.fillWidth: true
                text: TimeDate.error || "The bar and panels still show the old time zone until the shell restarts."
                wrapMode: Text.WordWrap
            }
            Pill {
                visible: !TimeDate.error
                text: "Restart shell"
                active: true
                implicitHeight: 30
                onClicked: Quickshell.execDetached(["sh", "-c",
                    "qs kill; sleep 0.5; setsid -f ~/.config/hypr/scripts/shell.sh >/dev/null 2>&1; "
                    + "for i in $(seq 20); do sleep 0.5; qs ipc call settings open datetime >/dev/null 2>&1 && break; done"])
            }
        }
    }

    SettingsSection {
        title: "Time zone"

        SettingsRow {
            icon: "my_location"
            title: "Detect my time zone"
            description: "From your network location (ipinfo.io), like the weather."
            Pill {
                text: TimeDate.busy ? "Working…" : "Detect"
                implicitHeight: 30
                onClicked: TimeDate.detectTimezone()
            }
        }

        SettingsRow {
            icon: "public"
            title: "Choose a time zone"
            description: "Current: " + TimeDate.timezone
            below: true
            ZoneSearch {
                current: TimeDate.timezone
                onPicked: zone => TimeDate.setTimezone(zone)
            }
        }
    }

    SettingsSection {
        title: "Clock"

        SettingsRow {
            icon: "sync"
            title: "Set time automatically"
            description: TimeDate.canNtp ? "Keeps the clock right using network time (systemd-timesyncd)." : "No network time service is installed."
            Switch {
                enabled: TimeDate.canNtp
                checked: TimeDate.ntp
                onToggled: TimeDate.setNtp(!checked)
            }
        }
        SettingsRow {
            visible: !TimeDate.ntp
            icon: "edit_calendar"
            title: "Set the date and time"
            description: "As YYYY-MM-DD HH:MM, then press Enter."
            SettingsTextField {
                implicitWidth: 200
                placeholder: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm")
                onAccepted: t => {
                    if (/^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}(:\d{2})?$/.test(t.trim()))
                        TimeDate.setTime(t.trim());
                    else
                        TimeDate.error = "Use the form 2026-10-15 14:30";
                }
            }
        }
    }

    SettingsSection {
        title: "Formats"

        SettingsRow {
            icon: "schedule"
            title: "24-hour time"
            description: Qt.formatTime(clock.date, Settings.bar.clock24 ? "HH:mm" : "h:mm AP")
            Switch {
                checked: Settings.bar.clock24
                onToggled: Settings.bar.clock24 = !checked
            }
        }
        SettingsRow {
            icon: "timer"
            title: "Seconds in the bar"
            Switch {
                checked: Settings.bar.seconds
                onToggled: Settings.bar.seconds = !checked
            }
        }
        SettingsRow {
            icon: "calendar_today"
            title: "Date format"
            description: "The bar's date item."
            below: true
            SettingsChips {
                options: ["ddd d MMM", "d MMM", "ddd, MMM d", "dddd d MMMM", "dd/MM", "MM/dd", "yyyy-MM-dd"]
                    .map(f => ({ value: f, label: Qt.formatDate(root.sample, f) }))
                current: Settings.datetime.dateFormat
                onPicked: v => Settings.datetime.dateFormat = v
            }
        }
        SettingsRow {
            icon: "date_range"
            title: "Week starts on"
            SettingsSegmented {
                options: [
                    { value: 1, label: "Monday" },
                    { value: 0, label: "Sunday" },
                    { value: 6, label: "Saturday" }
                ]
                current: Settings.datetime.weekStart
                onPicked: v => Settings.datetime.weekStart = v
            }
        }
        SettingsRow {
            icon: "numbers"
            title: "Week numbers"
            description: "In the calendar."
            Switch {
                checked: Settings.datetime.weekNumbers
                onToggled: Settings.datetime.weekNumbers = !checked
            }
        }
    }

    SettingsSection {
        title: "World clocks"
        subtitle: "Shown under the calendar (click the clock in the bar)."

        Repeater {
            model: Settings.datetime.worldClocks

            SettingsRow {
                id: worldRow
                required property var modelData
                required property int index
                icon: "language"
                title: modelData.label || TimeDate.city(modelData.zone)
                description: modelData.zone + " · " + TimeDate.difference(modelData.zone)
                RowLayout {
                    spacing: 10
                    Label {
                        text: TimeDate.timeIn(worldRow.modelData.zone, clock.date)
                        font.pixelSize: Theme.fontSize + 3
                        font.weight: Font.DemiBold
                    }
                    Pill {
                        icon: "close"
                        implicitHeight: 28
                        onClicked: {
                            const l = Settings.datetime.worldClocks.slice();
                            l.splice(worldRow.index, 1);
                            Settings.datetime.worldClocks = l;
                        }
                    }
                }
            }
        }

        SettingsRow {
            icon: "add"
            title: "Add a clock"
            below: true
            ZoneSearch {
                placeholder: "Search a city to add"
                onPicked: zone => {
                    if (!Settings.datetime.worldClocks.some(c => c.zone === zone))
                        Settings.datetime.worldClocks = Settings.datetime.worldClocks.concat([{ zone, label: TimeDate.city(zone) }]);
                }
            }
        }
    }
}
