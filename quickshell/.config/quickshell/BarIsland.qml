import QtQuick

// The bar's pill: workspaces, clock (spectrum while music plays), weather, next meeting, recording
// timer and the user's picture (opens the control center).
// Bar.qml shows it; Sheet.qml draws a copy on top of drop-down sheets so they look attached.
Island {
    id: root
    property bool settingsActive: false
    signal clockClicked()
    signal weatherClicked()
    signal musicClicked()
    signal captureClicked()
    signal settingsClicked()

    spacing: 12
    padding: Theme.pillInset

    Workspaces {}
    Divider {}
    // The clock, or while music plays a small spectrum in its place (same size, so the pill
    // doesn't change); click for the calendar or the Music tab
    Item {
        readonly property bool music: Cava.active && Settings.bar.musicBars
        implicitWidth: clock.implicitWidth
        implicitHeight: clock.implicitHeight

        Clock {
            id: clock
            anchors.centerIn: parent
            opacity: parent.music ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        MusicBars {
            anchors.fill: parent
            anchors.topMargin: -2
            anchors.bottomMargin: -2
            opacity: parent.music ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.music ? root.musicClicked() : root.clockClicked()
        }
    }
    WeatherChip {
        visible: Weather.ready && Settings.bar.weather
        onClicked: root.weatherClicked()
    }
    NextMeeting {}
    CaptureButton {
        visible: Recorder.active
        onClicked: root.captureClicked()
    }
    Divider {}

    // The user's picture opens the control center; a ring while it's open, a dot while there are
    // notifications
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
            Behavior on opacity { NumberAnimation { duration: 150 } }
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
            onClicked: root.settingsClicked()
        }
    }
}
