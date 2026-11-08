import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs.services

Scope {
    id: root

    property bool open: false
    property string page: "appearance"

    readonly property var pages: [
        { key: "appearance", group: "Personalize", title: "Appearance", icon: "palette",
            keywords: "wallpaper colors theme dark light mode palette scheme transparency opacity roundness rounded corners radius square circle cursor pointer size", source: "SettingsAppearancePage.qml" },
        { key: "fonts", group: "Personalize", title: "Fonts & icons", icon: "font_download",
            keywords: "font typeface text size icons weight", source: "SettingsFontsPage.qml" },
        { key: "bar", group: "Personalize", title: "Bar", icon: "toolbar",
            keywords: "bar pill height weather music spectrum clock 24 hour seconds", source: "SettingsBarPage.qml" },
        { key: "dock", group: "Personalize", title: "Dock", icon: "dock_to_bottom",
            keywords: "dock taskbar pinned apps running open windows previews auto hide intellihide magnify indicator", source: "SettingsDockPage.qml" },
        { key: "desktop", group: "Personalize", title: "Desktop", icon: "widgets",
            keywords: "desktop widgets clock weather calendar photo frame notes to-do todo right click menu show desktop edit", source: "SettingsDesktopPage.qml" },
        { key: "controlcenter", group: "Personalize", title: "Control center", icon: "dashboard_customize",
            keywords: "control center quick settings tiles cards widgets layout bento columns custom panel", source: "SettingsControlCenterPage.qml" },
        { key: "accessibility", group: "Personalize", title: "Accessibility", icon: "accessibility_new",
            keywords: "accessibility zoom magnifier magnify larger text size bigger font reduce motion animations tooltips hover hints", source: "SettingsAccessibilityPage.qml" },
        { key: "windows", group: "Desktop", title: "Windows", icon: "select_window",
            keywords: "hyprland layout dwindle master scrolling gaps borders corner shape squircle resize", source: "SettingsWindowsPage.qml" },
        { key: "effects", group: "Desktop", title: "Effects", icon: "auto_awesome",
            keywords: "blur opacity transparency dim shadows animations speed workspace", source: "SettingsEffectsPage.qml" },
        { key: "rules", group: "Desktop", title: "Window rules", icon: "select_window",
            keywords: "window rules float floating center size workspace opacity pin fullscreen blur app class", source: "SettingsWindowRulesPage.qml" },
        { key: "input", group: "Desktop", title: "Keyboard & mouse", icon: "keyboard",
            keywords: "keyboard layout language repeat mouse pointer sensitivity acceleration touchpad tap scroll", source: "SettingsInputPage.qml" },
        { key: "notifications", group: "Shell", title: "Notifications", icon: "notifications",
            keywords: "notifications popups do not disturb dnd quiet hours schedule position timeout", source: "SettingsNotificationsPage.qml" },
        { key: "launcher", group: "Shell", title: "Launcher", icon: "apps",
            keywords: "launcher app grid columns icons most used calculator emoji clipboard projects run style centered fullscreen spotlight attached dock bar", source: "SettingsLauncherPage.qml" },
        { key: "weather", group: "Shell", title: "Weather", icon: "partly_cloudy_day",
            keywords: "weather temperature celsius fahrenheit city location forecast", source: "SettingsWeatherPage.qml" },
        { key: "lock", group: "Shell", title: "Lock screen", icon: "lock",
            keywords: "lock screen blur password media power rest idle", source: "SettingsLockPage.qml" },
        { key: "keybinds", group: "Shell", title: "Keybindings", icon: "keyboard_command_key",
            keywords: "keybindings shortcuts keys hotkeys cheatsheet", source: "SettingsKeybindsPage.qml" },
        { key: "network", group: "System", title: "Network", icon: "wifi",
            keywords: "network wifi wi-fi ethernet wired vpn internet speed test", source: "SettingsNetworkPage.qml" },
        { key: "vpn", group: "System", title: "VPN", icon: "vpn_key",
            keywords: "vpn openvpn wireguard ssl vpn sophos fortinet company work tunnel servers password certificate dns", source: "SettingsVpnPage.qml" },
        { key: "bluetooth", group: "System", title: "Bluetooth", icon: "bluetooth",
            keywords: "bluetooth devices headphones pair", source: "SettingsBluetoothPage.qml" },
        { key: "sound", group: "System", title: "Sound", icon: "volume_up",
            keywords: "sound audio volume speakers headphones microphone input output apps", source: "SettingsSoundPage.qml" },
        { key: "displays", group: "System", title: "Displays", icon: "monitor",
            keywords: "display monitor screen resolution refresh rate scale night light warmth", source: "SettingsDisplaysPage.qml" },
        { key: "drives", group: "System", title: "Drives", icon: "usb",
            keywords: "drives usb stick flash sd card disk image iso mount eject automount removable", source: "SettingsDrivesPage.qml" },
        { key: "datetime", group: "System", title: "Date & time", icon: "schedule",
            keywords: "date time clock timezone time zone ntp sync 24 hour format week calendar world clocks", source: "SettingsDateTimePage.qml" },
        { key: "power", group: "System", title: "Power", icon: "battery_android_frame_5",
            keywords: "power battery charge limit profile performance idle dim lock sleep suspend screen off keep awake", source: "SettingsPowerPage.qml" },
        { key: "apps", group: "System", title: "Default apps", icon: "apps",
            keywords: "default apps browser terminal files editor mail pictures video music pdf open with", source: "SettingsDefaultAppsPage.qml" },
        { key: "startup", group: "System", title: "Startup apps", icon: "rocket_launch",
            keywords: "startup autostart login apps commands", source: "SettingsStartupPage.qml" },
        { key: "updates", group: "System", title: "Updates", icon: "system_update_alt",
            keywords: "updates upgrade pikadots dotfiles git pull packages pacman aur dnf flatpak", source: "SettingsUpdatesPage.qml" },
        { key: "about", group: "System", title: "About", icon: "info",
            keywords: "about version system hyprland quickshell kernel memory cpu", source: "SettingsAboutPage.qml" }
    ]

    function available(key) {
        return key !== "bluetooth" || Bluetooth.defaultAdapter !== null;
    }

    function show(key) {
        if (key && pages.some(p => p.key === key))
            page = key;
        if (open)
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ window = "title:^Settings$" })']);
        open = true;
    }

    Connections {
        target: Settings
        function onOpenRequested(key) {
            root.show(key);
        }
    }

    LazyLoader {
        active: root.open

        SettingsWindow {
            app: root
        }
    }
}
