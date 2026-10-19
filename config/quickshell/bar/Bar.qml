import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.panels
import qs.services
import qs.widgets

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    readonly property string edge: Theme.barPosition
    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitHeight: Theme.barHeight + Theme.barEar
    implicitWidth: Theme.barHeight + Theme.barEar
    exclusiveZone: Theme.barHeight
    color: "transparent"
    mask: Region {
        item: layout
    }

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

    IdleInhibitor {
        window: bar
        enabled: Toggles.keepAwake
    }

    BarLayout {
        id: layout
        x: bar.edge === "right" ? parent.width - width : 0
        y: bar.edge === "bottom" ? parent.height - height : 0
        width: Theme.barVertical ? Theme.barHeight : parent.width
        height: Theme.barVertical ? parent.height : Theme.barHeight
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
