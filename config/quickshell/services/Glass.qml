pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var names: ["off", "frosted", "clear", "custom"]
    readonly property var labels: ({ off: "Off", frosted: "Frosted", clear: "Clear", custom: "Custom" })
    readonly property var hyprKeys: ["decoration.blur.size", "decoration.blur.passes", "decoration.blur.vibrancy",
        "decoration.shadow.enabled", "decoration.shadow.range", "decoration.inactive_opacity"]
    readonly property var fallback: ({ tint: 0.8, card: 0.45, rim: 0, refraction: 0, chroma: 0, shadows: false })

    readonly property var presets: {
        try {
            return JSON.parse(presetFile.text());
        } catch (e) {
            return {};
        }
    }
    readonly property string preset: names.includes(Settings.glass.preset) ? Settings.glass.preset : "frosted"
    readonly property string customBase: Settings.glass.custom?.base ?? "frosted"
    readonly property var values: {
        if (preset !== "custom")
            return presets[preset] ?? fallback;
        return Object.assign({}, presets[customBase] ?? fallback, Settings.glass.custom ?? {});
    }

    readonly property bool active: preset !== "off" && !Toggles.gameMode
    readonly property bool neutral: active && !Settings.glass.color
    readonly property real tint: forMode(values.tint ?? fallback.tint)
    readonly property real card: forMode(values.card ?? fallback.card)
    readonly property real rim: active ? values.rim ?? 0 : 0
    readonly property real refraction: active ? values.refraction ?? 0 : 0
    readonly property real chroma: values.chroma ?? 0
    readonly property bool shadows: active && (values.shadows ?? false)
    readonly property real lightAngle: Settings.glass.lightAngle
    readonly property point lightDir: Qt.point(Math.sin(lightAngle * Math.PI / 180), -Math.cos(lightAngle * Math.PI / 180))
    readonly property bool light: Theme.base.hslLightness > 0.5
    readonly property color rimColor: Qt.rgba(1, 1, 1, light ? 0.95 : 0.6)
    readonly property color rimShade: light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.05)
    readonly property color shadowColor: light ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(0, 0, 0, 0.45)
    readonly property bool flat: !active
    readonly property color outline: light ? Qt.rgba(0, 0, 0, 0.14) : Qt.rgba(1, 1, 1, 0.12)
    readonly property bool panelShadows: shadows || flat
    readonly property color panelShadow: flat ? (light ? Qt.rgba(0, 0, 0, 0.12) : Qt.rgba(0, 0, 0, 0.4)) : shadowColor

    readonly property string wallpaper: {
        const match = /^\s*path\s*=\s*(.+?)\s*$/m.exec(wallpaperConf.text() ?? "");
        return match ? "file://" + match[1].replace(/^~(?=\/)/, Quickshell.env("HOME")) : "";
    }

    function forMode(a) {
        return light && active ? 1 - (1 - a) * 0.55 : a;
    }

    function value(key) {
        const v = values[key] ?? fallback[key];
        return ["window", "view", "popover", "terminal"].includes(key) ? forMode(v) : v;
    }

    function setPreset(name) {
        if (!names.includes(name) || name === preset)
            return;
        if (name === "custom")
            Settings.glass.custom = Object.assign({}, presets[preset] ?? {}, { base: preset === "off" ? "frosted" : preset });
        Settings.glass.preset = name;
        if (name !== "off" && name !== "custom" && hyprKeys.some(k => Hypr.changed(k)))
            Hypr.reset(hyprKeys.filter(k => Hypr.changed(k)));
        apply();
    }

    function setCustom(key, v) {
        const next = Object.assign({ base: preset === "custom" ? customBase : preset === "off" ? "frosted" : preset },
            preset === "custom" ? Settings.glass.custom : presets[preset] ?? {});
        next[key] = v;
        Settings.glass.custom = next;
        Settings.glass.preset = "custom";
        apply();
    }

    function setColor(on) {
        Settings.glass.color = on;
        apply();
    }

    function setLightAngle(a) {
        Settings.glass.lightAngle = a;
        apply();
    }

    function cycle() {
        const order = ["off", "frosted", "clear"];
        setPreset(order[(order.indexOf(preset) + 1) % order.length]);
    }

    function apply() {
        applyTimer.restart();
    }

    Timer {
        id: applyTimer
        interval: 300
        onTriggered: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh", "--glass"])
    }

    FileView {
        id: presetFile
        path: Quickshell.shellDir + "/services/glass-presets.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: wallpaperConf
        path: Quickshell.env("HOME") + "/.config/hypr/wallpaper.conf"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    IpcHandler {
        target: "glass"
        function preset(name: string): void { root.setPreset(name); }
        function cycle(): void { root.cycle(); }
        function get(): string { return root.preset; }
    }
}
