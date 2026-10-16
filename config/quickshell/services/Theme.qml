pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.widgets

Singleton {
    id: root
    readonly property color base: colors.base
    readonly property color baseTranslucent: Qt.alpha(colors.base, Settings.appearance.panelOpacity)
    readonly property color surface: colors.surface
    readonly property color overlay: colors.overlay
    readonly property color text: colors.text
    readonly property color subtext: colors.subtext
    readonly property color accent: colors.accent
    readonly property color accentText: colors.accentText
    readonly property bool multiColor: colors.accent2 !== ""
    readonly property color accent2: multiColor ? colors.accent2 : accent
    readonly property color accent3: multiColor && colors.accent3 !== "" ? colors.accent3 : accent2
    readonly property var accents: [accent, accent2, accent3]
    readonly property bool gradientAccent: Settings.appearance.gradient
    readonly property color accentEnd: multiColor ? accent2 : shade(accent)
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
    function shade(c) {
        return Qt.hsla(c.hslHue, Math.min(1, c.hslSaturation * 1.1), Math.max(0, c.hslLightness - (c.hslLightness > 0.5 ? 0.15 : 0.1)), 1);
    }
    readonly property Gradient accentGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.accent }
        GradientStop { position: 1; color: root.accentEnd }
    }
    function accentFill(on) {
        return on && gradientAccent ? accentGradient : null;
    }
    readonly property color special: colors.special
    readonly property color specialText: colors.specialText
    readonly property color red: colors.red
    readonly property color green: colors.green
    readonly property color yellow: colors.yellow

    readonly property string font: Settings.appearance.font
    readonly property string displayFont: Settings.appearance.displayFont
    readonly property int fontSize: Math.round(Settings.appearance.fontSize * Settings.accessibility.textScale)

    readonly property bool reduceMotion: Settings.accessibility.reduceMotion
    function ms(duration) {
        return reduceMotion ? 1 : duration;
    }
    readonly property int barHeight: Settings.bar.height
    readonly property string barPosition: ["top", "bottom", "left", "right"].includes(Settings.bar.position) ? Settings.bar.position : "top"
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"
    readonly property int barSpaceX: barVertical ? barHeight : 0
    readonly property int barSpaceY: barVertical ? 0 : barHeight
    readonly property int barGap: Math.min(Settings.bar.gap, Math.floor((barHeight - 24) / 2))
    readonly property int pillHeight: barHeight - 2 * barGap
    readonly property int pillInset: Math.max(5, Math.round((pillHeight - 28) / 2))
    readonly property int pillCircle: pillHeight - 2 * pillInset
    readonly property real pillRadius: round(pillHeight / 2, pillHeight, pillHeight)
    readonly property string iconFont: "Material Symbols " + Settings.appearance.iconStyle
    readonly property int iconSize: 20
    readonly property int iconWeight: Settings.appearance.iconWeight
    readonly property real roundness: Math.max(0, Math.min(2, Settings.appearance.roundness))

    function round(base, width, height) {
        const r = base * roundness;
        return width === undefined ? r : Math.max(0, Math.min(r, Math.min(width, height) / 2));
    }

    function pad(base, radius, width, height) {
        return base + Math.round(Math.max(0, round(radius, width, height) - radius) / 2);
    }

    function wifiIcon(strength) {
        return ["signal_wifi_0_bar", "wifi_1_bar", "wifi_2_bar", "wifi", "wifi"][Math.min(4, Math.floor(strength * 5))];
    }

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme/quickshell.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: colors
            property string base: "#1e1e2e"
            property string surface: "#313244"
            property string overlay: "#6c7086"
            property string text: "#cdd6f4"
            property string subtext: "#a6adc8"
            property string accent: "#89b4fa"
            property string accentText: "#1e1e2e"
            property string accent2: ""
            property string accent3: ""
            property string special: "#f5c2e7"
            property string specialText: "#1e1e2e"
            property string red: "#f38ba8"
            property string green: "#a6e3a1"
            property string yellow: "#f9e2af"
        }
    }
}
