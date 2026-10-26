import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Loader {
    id: root
    required property string moduleId
    property bool settingsActive: false
    property bool dividerShown: true
    signal action(string name)

    Layout.alignment: Qt.AlignCenter
    visible: wanted && (moduleId !== "divider" || dividerShown)
    readonly property bool wanted: {
        switch (moduleId) {
        case "weather": return Weather.ready;
        case "meeting": return Meetings.next !== null;
        case "recording": return Recorder.active || Privacy.active;
        case "title": return ToplevelManager.activeToplevel !== null && !Theme.barVertical;
        case "media": return Media.active !== null;
        case "tray": return SystemTray.items.values.length > 0;
        case "bluetooth": return StatusInfo.btAdapter !== null;
        case "battery": return StatusInfo.battery.isLaptopBattery;
        }
        return true;
    }
    sourceComponent: {
        switch (moduleId) {
        case "workspaces": return workspaces;
        case "divider": return divider;
        case "clock": return clock;
        case "date": return date;
        case "weather": return weather;
        case "meeting": return meeting;
        case "recording": return recording;
        case "capture": return capture;
        case "avatar": return avatar;
        case "launcher": return launcher;
        case "title": return title;
        case "media": return media;
        case "tray": return tray;
        case "network":
        case "bluetooth":
        case "sound":
        case "battery":
        case "notifications": return statusIcon;
        case "system": return system;
        case "power": return power;
        }
        return null;
    }

    Component { id: workspaces; Workspaces {} }
    Component { id: divider; Divider {} }
    Component { id: weather; WeatherChip { onClicked: root.action("weather") } }
    Component { id: meeting; NextMeeting {} }
    Component { id: capture; CaptureButton { onClicked: root.action("cc:capture") } }
    Component {
        id: recording
        Grid {
            columns: Theme.barVertical ? 1 : 2
            spacing: 6
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            CaptureButton {
                visible: Recorder.active
                onClicked: root.action("cc:capture")
            }
            PrivacyIndicator {
                visible: Privacy.active
                onClicked: root.action("cc:audio")
            }
        }
    }
    Component { id: title; BarTitle {} }
    Component { id: media; BarMedia { onClicked: root.action("cc:music") } }
    Component { id: system; BarSystem { onClicked: root.action("cc:system") } }
    Component {
        id: statusIcon
        BarStatusIcon {
            key: root.moduleId === "sound" ? "audio" : root.moduleId
            onClicked: root.action("cc:" + key)
        }
    }
    Component {
        id: power
        BarIconButton { icon: "power_settings_new"; tip: "Power menu"; tipKeys: "Super + Escape"; onClicked: root.action("power") }
    }
    Component {
        id: launcher
        Item {
            implicitWidth: Theme.pillCircle
            implicitHeight: Theme.pillCircle

            BarLogo {
                anchors.centerIn: parent
                width: Theme.pillCircle - 6
                height: Theme.pillCircle - 6
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 2 * width
                sourceSize.height: 2 * height
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.action("launcher")
            }

            Tooltip {
                text: "Open launcher"
                keys: "Super + A"
                side: Theme.awayFromBar
            }
        }
    }
    Component {
        id: tray
        Grid {
            columns: Theme.barVertical ? 1 : -1
            rows: Theme.barVertical ? -1 : 1
            spacing: 8
            Tray { bar: QsWindow.window }
        }
    }

    Component {
        id: clock
        Item {
            id: clockItem
            readonly property bool music: Cava.active && Settings.bar.musicBars
            implicitWidth: clockLabel.implicitWidth
            implicitHeight: clockLabel.implicitHeight

            Clock {
                id: clockLabel
                anchors.centerIn: parent
                opacity: clockItem.music ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
            }
            MusicBars {
                anchors.centerIn: parent
                width: Theme.barVertical ? Theme.pillCircle : parent.width
                height: parent.height + (Theme.barVertical ? 0 : 4)
                opacity: clockItem.music ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.action(clockItem.music ? "cc:music" : "calendar")
            }

            Tooltip {
                active: clockItem.music
                text: "Show media controls"
                side: Theme.awayFromBar
            }
        }
    }

    Component {
        id: date
        Label {
            SystemClock {
                id: dateClock
                precision: SystemClock.Hours
            }
            text: Qt.formatDate(dateClock.date, Theme.barVertical ? "d\nMMM" : Settings.datetime.dateFormat)
            horizontalAlignment: Text.AlignHCenter
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.action("calendar")
            }
        }
    }

    Component {
        id: avatar
        Item {
            implicitWidth: Theme.pillCircle
            implicitHeight: Theme.pillCircle

            Avatar {
                anchors.fill: parent
                size: Theme.pillCircle
            }
            Rectangle {
                anchors.fill: parent
                radius: Theme.round(width / 2, width, height)
                color: "transparent"
                border.width: 2
                border.color: Theme.gradientAccent ? "transparent" : Theme.accent
                GradientBorder {
                }
                opacity: root.settingsActive ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.ms(150) } }
            }
            Rectangle {
                visible: NotificationService.list.length > 0 && !NotificationService.dnd
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -2
                anchors.topMargin: -2
                width: 8
                height: 8
                radius: Theme.round(4, width, height)
                color: Theme.accent
                border.width: 1.5
                border.color: Theme.base
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.action("cc:")
            }

            Tooltip {
                text: "Open control center"
                keys: "Super + S"
                side: Theme.awayFromBar
            }
        }
    }
}
