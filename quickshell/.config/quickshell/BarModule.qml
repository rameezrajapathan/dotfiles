import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// One item of the bar, by id (BarStyles.modules lists them all). Clicks come out as `action`:
// "calendar", "weather", "launcher", "power", "overview" or "cc:<tab>" for a control center tab
// ("cc:" = the last one); BarLayout.qml passes them on.
Loader {
    id: root
    required property string moduleId
    // The control center is open (ring around the profile picture)
    property bool settingsActive: false
    // Set by BarRow: whether this divider sits between two shown items
    property bool dividerShown: true
    signal action(string name)

    Layout.alignment: Qt.AlignVCenter
    visible: wanted && (moduleId !== "divider" || dividerShown)
    // Hidden while there's nothing to show; a hidden item takes no room in the row
    readonly property bool wanted: {
        switch (moduleId) {
        case "weather": return Weather.ready;
        case "meeting": return Meetings.next !== null;
        case "recording": return Recorder.active || Privacy.active;
        case "title": return ToplevelManager.activeToplevel !== null;
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
    // The recording timer, and the privacy dots while an app uses the mic, camera or screen
    Component {
        id: recording
        Row {
            spacing: 6
            CaptureButton {
                visible: Recorder.active
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.action("cc:capture")
            }
            PrivacyIndicator {
                visible: Privacy.active
                anchors.verticalCenter: parent.verticalCenter
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
        BarIconButton { icon: "power_settings_new"; onClicked: root.action("power") }
    }
    Component {
        id: launcher
        BarLogo {
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.action("launcher")
            }
        }
    }
    Component {
        id: tray
        Row {
            spacing: 8
            Tray { bar: QsWindow.window }
        }
    }

    // The clock, or while music plays a small spectrum in its place (same size, so the bar
    // doesn't change); click for the calendar or the Music tab
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
                anchors.fill: parent
                anchors.topMargin: -2
                anchors.bottomMargin: -2
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
        }
    }

    Component {
        id: date
        Label {
            SystemClock {
                id: dateClock
                precision: SystemClock.Hours
            }
            text: Qt.formatDate(dateClock.date, Settings.datetime.dateFormat)
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.action("calendar")
            }
        }
    }

    // The user's picture opens the control center; a ring while it's open, a dot while there are
    // notifications
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
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
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
                radius: 4
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
        }
    }
}
