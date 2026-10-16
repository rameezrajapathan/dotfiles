pragma Singleton

import Quickshell
import QtQuick

// The control center's widgets (CCWidget.qml), quick tiles (CCTiles.qml) and ready-made layouts
// for Settings > Control center. A layout is a list of columns, each a list of widget ids from
// top to bottom. "custom" is the user's own (Settings.controlCenter.custom).
Singleton {
    id: root

    readonly property var widgets: [
        { id: "header", label: "Profile & power", icon: "account_circle", description: "Picture, name, uptime, lock, settings and power" },
        { id: "tiles", label: "Quick tiles", icon: "grid_view", description: "Large toggles in two columns" },
        { id: "tilesSmall", label: "Quick tiles (small)", icon: "apps", description: "Square toggles in three columns" },
        { id: "sliders", label: "Volume & brightness", icon: "tune", description: "Output volume, microphone and screen brightness" },
        { id: "media", label: "Music", icon: "music_note", description: "Compact player, while something plays" },
        { id: "mediaLarge", label: "Music (large)", icon: "album", description: "Big cover and controls" },
        { id: "notifications", label: "Notifications", icon: "notifications", description: "The latest ones" },
        { id: "status", label: "Status chips", icon: "label", description: "CPU, memory, drives, updates, recording" },
        { id: "system", label: "System usage", icon: "monitoring", description: "CPU, memory, disk and battery bars" },
        { id: "calendar", label: "Calendar", icon: "calendar_month", description: "This month" },
        { id: "weather", label: "Weather", icon: "partly_cloudy_day", description: "Now and the next hours" },
        { id: "updates", label: "Updates", icon: "system_update_alt", description: "Package and pikadots updates" },
        { id: "actions", label: "Shortcuts", icon: "bolt", description: "Capture, wallpaper and settings" },
        { id: "tray", label: "Tray", icon: "widgets", description: "Background apps' icons" }
    ]

    function widget(id) {
        return widgets.find(w => w.id === id) ?? { id, label: id, icon: "help", description: "" };
    }

    readonly property var tiles: [
        { id: "network", label: "Wi-Fi", icon: "wifi" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth" },
        { id: "vpn", label: "VPN", icon: "vpn_key" },
        { id: "dnd", label: "Do Not Disturb", icon: "do_not_disturb_on" },
        { id: "night", label: "Night light", icon: "nightlight" },
        { id: "profile", label: "Power profile", icon: "bolt" },
        { id: "awake", label: "Keep awake", icon: "coffee" },
        { id: "game", label: "Game mode", icon: "sports_esports" },
        { id: "mic", label: "Microphone", icon: "mic" },
        { id: "record", label: "Record", icon: "screen_record" },
        { id: "picker", label: "Color picker", icon: "colorize" }
    ]

    function tile(id) {
        return tiles.find(t => t.id === id) ?? { id, label: id, icon: "help" };
    }

    readonly property var presets: [
        {
            id: "glance", label: "One glance", icon: "view_agenda",
            description: "One column under the bar. Tiles open their details in place.",
            columns: [["header", "tiles", "sliders", "media", "notifications", "status", "tray"]]
        },
        {
            id: "bento", label: "Bento", icon: "dashboard",
            description: "A wide dashboard: controls, now and what needs you, side by side.",
            columns: [
                ["header", "tilesSmall", "sliders", "tray"],
                ["mediaLarge", "calendar", "weather", "system"],
                ["updates", "notifications", "actions"]
            ]
        }
    ]

    readonly property string style: Settings.controlCenter.style
    readonly property var current: columnsFor(style)

    function columnsFor(id) {
        if (id === "custom")
            return Settings.controlCenter.custom ?? presets[0].columns;
        return (presets.find(p => p.id === id) ?? presets[0]).columns;
    }

    // One column is a little wider than each of several
    function columnWidth(count) {
        return count <= 1 ? 420 : 340;
    }

    function apply(id) {
        if (id === "custom" && !Settings.controlCenter.custom)
            Settings.controlCenter.custom = JSON.parse(JSON.stringify(columnsFor(style)));
        Settings.controlCenter.style = id;
    }

    // Changes the layout: `change` gets a copy of the columns to edit. A ready-made style becomes
    // Custom, starting from it.
    function edit(change) {
        const columns = JSON.parse(JSON.stringify(current));
        change(columns);
        Settings.controlCenter.custom = columns;
        Settings.controlCenter.style = "custom";
    }
}
