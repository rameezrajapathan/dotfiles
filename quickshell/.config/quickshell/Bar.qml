import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.base

    NetworkPanel {
        id: networkPanel
        bar: bar
    }

    CalendarPanel {
        id: calendarPanel
        bar: bar
    }

    BatteryPanel {
        id: batteryPanel
        bar: bar
    }

    NotificationPanel {
        id: notificationPanel
        bar: bar
    }

    Connections {
        target: NotificationService
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                notificationPanel.toggle();
        }
    }

    AudioPanel {
        id: audioPanel
        bar: bar
    }

    Workspaces {
        id: workspaces
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    ActiveWindow {
        anchors.left: workspaces.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        screen: bar.screen
        // Stop short of the centered clock
        maxWidth: clock.x - x - 40
    }

    Clock {
        id: clock
        anchors.centerIn: parent
        onClicked: calendarPanel.toggle()
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Recording {}
        WallpaperButton {}
        Network { onClicked: networkPanel.toggle() }
        Volume { onClicked: audioPanel.toggle() }
        Battery { onClicked: batteryPanel.toggle() }
        NotificationButton { onClicked: notificationPanel.toggle() }
    }
}
