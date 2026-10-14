import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"

    NetworkPanel {
        id: networkPanel
        bar: bar
    }

    CalendarPanel {
        id: calendarPanel
        bar: bar
        anchorX: center.x + clockIsland.x + clockIsland.width / 2
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

    BluetoothPanel {
        id: bluetoothPanel
        bar: bar
    }

    DisplayPanel {
        id: displayPanel
        bar: bar
    }

    CapturePanel {
        id: capturePanel
        bar: bar
    }

    QuickSettingsPanel {
        id: quickSettingsPanel
        bar: bar
    }

    SystemPanel {
        id: systemPanel
        bar: bar
    }

    GitHubPanel {
        id: gitHubPanel
        bar: bar
    }

    Connections {
        target: Toggles
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                quickSettingsPanel.toggle();
        }
    }

    // Keep awake: hypridle won't dim, lock or suspend while this is enabled
    IdleInhibitor {
        window: bar
        enabled: Toggles.keepAwake
    }

    MediaPanel {
        id: mediaPanel
        bar: bar
        anchorX: media.x
    }

    Connections {
        target: Media
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                mediaPanel.toggle();
        }
    }

    Island {
        id: left
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        OsIcon {}
        Workspaces {}
    }

    // Music, between the workspaces and the window title
    Island {
        id: media
        anchors.left: left.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        MediaButton { onClicked: mediaPanel.toggle() }
    }

    // Clock, then the window title, centered together
    Row {
        id: center
        anchors.centerIn: parent
        spacing: 8

        Island {
            id: clockIsland

            Clock { onClicked: calendarPanel.toggle() }
            NextMeeting {}
        }

        Island {
            visible: title.toplevel !== null

            ActiveWindow {
                id: title
                screen: bar.screen
                // Keep clear of the left and right groups
                maxWidth: bar.width - 2 * Math.max(left.width + media.width + 8, right.width + (tray.visible ? tray.width + 8 : 0))
                    - clockIsland.width - 8 - 120
            }
        }
    }

    // Background apps (hidden Thunderbird / Chrome apps, then tray icons), left of the status group
    Island {
        id: tray
        anchors.right: right.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: SystemTray.items.values.length > 0 || backgroundApps.count > 0

        BackgroundApps { id: backgroundApps; bar: bar }
        Tray { bar: bar }
    }

    Island {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        CaptureButton { onClicked: capturePanel.toggle() }
        WallpaperButton {}
        DisplayButton { onClicked: displayPanel.toggle() }
        Network { onClicked: networkPanel.toggle() }
        Bluetooth { onClicked: bluetoothPanel.toggle() }
        Volume { onClicked: audioPanel.toggle() }
        SystemButton { onClicked: systemPanel.toggle() }
        Battery { onClicked: batteryPanel.toggle() }
        GitHubButton { onClicked: gitHubPanel.toggle() }
        NotificationButton { onClicked: notificationPanel.toggle() }
        KeepAwakeIndicator {}
        QuickSettingsButton { onClicked: quickSettingsPanel.toggle() }
        PowerButton {}
    }
}
