import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// The bar: by default one centered pill with workspaces, the clock (click for the calendar), the
// weather (click for the forecast) and the profile picture that opens ControlCenter, which holds
// everything else. Its style and items are set in Settings > Bar (BarLayout.qml).
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    // Along the screen edge picked in Settings > Bar (Theme.barPosition)
    readonly property string edge: Theme.barPosition
    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitHeight: Theme.barHeight
    implicitWidth: Theme.barHeight
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
                controlCenter.toggle("");
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

    BarLayout {
        anchors.fill: parent
        // Hidden while a Sheet draws its copy over it
        opacity: (Panels.covered[bar.screen.name] ?? 0) > 0 ? 0 : 1
        settingsActive: controlCenter.open
        onAction: name => {
            if (name.startsWith("cc:"))
                controlCenter.toggle(name.slice(3));
            else if (name === "calendar")
                calendarPanel.toggle();
            else if (name === "weather")
                weatherPanel.toggle();
            else
                Toggles.barAction(name);
        }
    }
}
