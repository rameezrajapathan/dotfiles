pragma Singleton

import Quickshell
import QtQuick
import qs.bar

Singleton {
    id: root

    readonly property var modules: [
        { id: "workspaces", label: "Workspaces", icon: "space_dashboard", description: "Workspaces, in the style picked below" },
        { id: "launcher", label: "Apps", icon: "apps", description: "Distro logo that opens the launcher" },
        { id: "title", label: "Window title", icon: "web_asset", description: "The focused window" },
        { id: "clock", label: "Clock", icon: "schedule", description: "Click for the calendar" },
        { id: "date", label: "Date", icon: "calendar_today", description: "Day and month" },
        { id: "weather", label: "Weather", icon: "partly_cloudy_day", description: "Click for the forecast" },
        { id: "meeting", label: "Next meeting", icon: "event", description: "When a calendar is set up" },
        { id: "media", label: "Now playing", icon: "music_note", description: "Track and artist" },
        { id: "recording", label: "Recording & privacy", icon: "radio_button_checked", description: "While recording, or while an app uses the mic, camera or screen" },
        { id: "capture", label: "Capture", icon: "screenshot_frame", description: "Screenshots and recording" },
        { id: "tray", label: "Tray", icon: "widgets", description: "Background apps' icons" },
        { id: "system", label: "CPU & memory", icon: "memory", description: "Usage in percent" },
        { id: "network", label: "Network", icon: "wifi", description: "Wi-Fi or wired" },
        { id: "bluetooth", label: "Bluetooth", icon: "bluetooth", description: "Right click turns it on or off" },
        { id: "sound", label: "Sound", icon: "volume_up", description: "Scroll for volume" },
        { id: "battery", label: "Battery", icon: "battery_android_frame_5", description: "With percentage" },
        { id: "notifications", label: "Notifications", icon: "notifications", description: "Count; right click for Do Not Disturb" },
        { id: "avatar", label: "Profile", icon: "account_circle", description: "Opens the control center" },
        { id: "power", label: "Power", icon: "power_settings_new", description: "Power menu" },
        { id: "divider", label: "Divider", icon: "more_vert", description: "A thin line", multi: true }
    ]

    function module(id) {
        return modules.find(m => m.id === id) ?? { id, label: id, icon: "help" };
    }

    readonly property var keys: ["layout", "left", "center", "right", "height", "gap", "sideGap", "roundness", "border"]

    readonly property var presets: [
        {
            id: "minimalist", label: "Minimalist", icon: "radio_button_unchecked",
            description: "One pill in the middle. The original.",
            layout: "pill", height: 46, gap: 4, sideGap: 8, roundness: 1, border: false,
            left: [], center: ["workspaces", "divider", "clock", "meeting", "recording", "divider", "avatar"], right: []
        },
        {
            id: "focus", label: "Focus", icon: "self_improvement",
            description: "Only the time. Nothing to pull you away.",
            layout: "pill", height: 36, gap: 3, sideGap: 8, roundness: 1, border: false,
            left: [], center: ["clock", "meeting", "recording"], right: []
        },
        {
            id: "everyday", label: "Everyday", icon: "local_cafe",
            description: "Friendly and familiar: apps, date, battery, sound. No tech clutter.",
            layout: "islands", height: 46, gap: 5, sideGap: 10, roundness: 1, border: false,
            left: ["launcher", "workspaces"],
            center: ["date", "clock", "weather"],
            right: ["network", "sound", "battery", "notifications", "avatar"]
        },
        {
            id: "onthego", label: "On the go", icon: "luggage",
            description: "A small pill for laptops: Wi-Fi, battery and time.",
            layout: "pill", height: 40, gap: 4, sideGap: 8, roundness: 1, border: false,
            left: [], center: ["workspaces", "divider", "clock", "divider", "network", "battery", "avatar"], right: []
        },
        {
            id: "music", label: "Music lover", icon: "headphones",
            description: "What's playing up front, sound and Bluetooth close at hand.",
            layout: "islands", height: 44, gap: 4, sideGap: 8, roundness: 1, border: false,
            left: ["workspaces", "divider", "media"],
            center: ["clock", "weather"],
            right: ["bluetooth", "sound", "divider", "avatar"]
        },
        {
            id: "developer", label: "Developer", icon: "terminal",
            description: "Window title, CPU and memory, tray and meetings.",
            layout: "full", height: 38, gap: 4, sideGap: 8, roundness: 0.35, border: true,
            left: ["workspaces", "divider", "title"],
            center: ["clock", "meeting", "recording"],
            right: ["tray", "system", "divider", "network", "bluetooth", "sound", "battery", "notifications", "avatar"]
        },
        {
            id: "islands", label: "Islands", icon: "bubble_chart",
            description: "A pill on each side and one in the middle.",
            layout: "islands", height: 44, gap: 4, sideGap: 8, roundness: 1, border: false,
            left: ["launcher", "workspaces", "divider", "title"],
            center: ["clock", "weather", "meeting", "recording"],
            right: ["tray", "divider", "network", "bluetooth", "sound", "battery", "divider", "avatar"]
        },
        {
            id: "floating", label: "Floating", icon: "flight",
            description: "A full bar with space around it.",
            layout: "full", height: 46, gap: 6, sideGap: 10, roundness: 0.55, border: false,
            left: ["launcher", "workspaces", "divider", "title"],
            center: ["clock", "weather", "recording"],
            right: ["tray", "media", "divider", "network", "bluetooth", "sound", "battery", "notifications", "avatar"]
        },
        {
            id: "classic", label: "Classic", icon: "desktop_windows",
            description: "Edge to edge and square, like a traditional desktop.",
            layout: "full", height: 34, gap: 0, sideGap: 0, roundness: 0, border: false,
            left: ["launcher", "workspaces", "title"],
            center: ["date", "clock", "recording"],
            right: ["tray", "system", "network", "sound", "battery", "power"]
        },
        {
            id: "maximalist", label: "Maximalist", icon: "auto_awesome",
            description: "Everything, all at once.",
            layout: "full", height: 48, gap: 6, sideGap: 10, roundness: 1, border: true,
            left: ["launcher", "workspaces", "divider", "media"],
            center: ["date", "clock", "weather", "meeting", "recording"],
            right: ["tray", "divider", "system", "divider", "network", "bluetooth", "sound", "battery", "divider", "notifications", "avatar", "power"]
        }
    ]

    function has(id) {
        return ["left", "center", "right"].some(k => Settings.bar[k].includes(id));
    }

    function toggle(id, on, after) {
        if (!on) {
            for (const k of ["left", "center", "right"])
                if (Settings.bar[k].includes(id))
                    Settings.bar[k] = Settings.bar[k].filter(m => m !== id);
            return;
        }
        if (has(id))
            return;
        const k = ["left", "center", "right"].find(k => Settings.bar[k].includes(after)) ?? "center";
        const l = Settings.bar[k].slice();
        const i = l.indexOf(after);
        l.splice(i < 0 ? l.length : i + 1, 0, id);
        Settings.bar[k] = l;
    }

    function same(a, b) {
        return JSON.stringify(a) === JSON.stringify(b);
    }

    function snapshot() {
        const s = {};
        for (const k of keys)
            s[k] = Settings.bar[k];
        return s;
    }

    readonly property string current: {
        const now = snapshot();
        return presets.find(p => keys.every(k => same(p[k], now[k])))?.id ?? "custom";
    }

    function set(values) {
        for (const k of keys)
            if (values[k] !== undefined && !same(Settings.bar[k], values[k]))
                Settings.bar[k] = values[k];
    }

    function apply(id) {
        if (current === "custom")
            Settings.bar.custom = snapshot();
        if (id === "custom") {
            if (Settings.bar.custom)
                set(Settings.bar.custom);
            return;
        }
        set(presets.find(p => p.id === id));
    }
}
