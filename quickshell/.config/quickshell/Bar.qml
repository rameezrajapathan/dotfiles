import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// One centered pill: workspaces, the clock (click for the calendar), the weather (click for the
// forecast) and a settings icon that opens ControlCenter, which holds everything else. While
// recording, the timer shows too, and so does the next meeting when a calendar is set up.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"

    CalendarPanel {
        id: calendarPanel
        bar: bar
    }

    ControlCenter {
        id: controlCenter
        bar: bar
    }

    WeatherPanel {
        id: weatherPanel
        bar: bar
    }

    // IPC and keybinds that used to open the separate panels open their tab instead
    Connections {
        target: NotificationService
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                controlCenter.toggle("notifications");
        }
    }
    Connections {
        target: Toggles
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                controlCenter.toggle("account");
        }
        function onControlCenterRequested(tab) {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                controlCenter.toggle(tab);
        }
        function onCalendarRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                calendarPanel.toggle();
        }
    }
    Connections {
        target: Weather
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                weatherPanel.toggle();
        }
    }
    Connections {
        target: Media
        function onPanelToggleRequested() {
            if (Hyprland.focusedMonitor?.name === bar.screen.name)
                controlCenter.toggle("music");
        }
    }

    // Keep awake: hypridle won't dim, lock or suspend while this is enabled
    IdleInhibitor {
        window: bar
        enabled: Toggles.keepAwake
    }

    BarIsland {
        id: island
        anchors.centerIn: parent
        // Hidden while a Sheet draws its copy over it
        opacity: (Panels.covered[bar.screen.name] ?? 0) > 0 ? 0 : 1
        settingsActive: controlCenter.open
        onClockClicked: calendarPanel.toggle()
        onWeatherClicked: weatherPanel.toggle()
        onMusicClicked: controlCenter.toggle("music")
        onCaptureClicked: controlCenter.toggle("capture")
        onSettingsClicked: controlCenter.toggle()
    }
}
