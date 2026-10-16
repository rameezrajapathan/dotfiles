pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colors come from ~/.local/state/theme/quickshell.json, written by matugen from the wallpaper
// (hypr/scripts/theme.sh) and reloaded live. The defaults are Catppuccin Mocha.
Singleton {
    readonly property color base: colors.base
    // Semi-transparent base for the bar islands and dropdown panels
    readonly property color baseTranslucent: Qt.alpha(colors.base, Settings.appearance.panelOpacity)
    readonly property color surface: colors.surface
    readonly property color overlay: colors.overlay
    readonly property color text: colors.text
    readonly property color subtext: colors.subtext
    readonly property color accent: colors.accent
    // Text and icons drawn on top of accent
    readonly property color accentText: colors.accentText
    // Special workspaces (scratchpads, drop-down terminal): the bar chip and their window borders
    readonly property color special: colors.special
    readonly property color specialText: colors.specialText
    readonly property color red: colors.red
    readonly property color green: colors.green
    readonly property color yellow: colors.yellow

    // Fonts and sizes are chosen in the Settings app (Settings.qml)
    readonly property string font: Settings.appearance.font
    readonly property string displayFont: Settings.appearance.displayFont
    // Settings > Accessibility "Text size" scales it
    readonly property int fontSize: Math.round(Settings.appearance.fontSize * Settings.accessibility.textScale)

    // Settings > Accessibility "Reduce motion": the shell's transitions become instant (1 ms, so
    // what waits for an animation to end still runs); spinners and pulses keep their pace
    readonly property bool reduceMotion: Settings.accessibility.reduceMotion
    function ms(duration) {
        return reduceMotion ? 1 : duration;
    }
    readonly property int barHeight: Settings.bar.height
    // Screen edge the bar is on; on the left or right its "height" is its width
    readonly property string barPosition: ["top", "bottom", "left", "right"].includes(Settings.bar.position) ? Settings.bar.position : "top"
    readonly property bool barVertical: barPosition === "left" || barPosition === "right"
    // Room the bar takes across and down the screen
    readonly property int barSpaceX: barVertical ? barHeight : 0
    readonly property int barSpaceY: barVertical ? 0 : barHeight
    // Space above the bar's shapes (and below, inside barHeight)
    readonly property int barGap: Math.min(Settings.bar.gap, Math.floor((barHeight - 24) / 2))
    // The bar's pill(s), and the circles at their ends (workspace, profile picture): the same gap
    // on every side makes them sit concentric in the rounded ends
    readonly property int pillHeight: barHeight - 2 * barGap
    readonly property int pillInset: Math.max(5, Math.round((pillHeight - 28) / 2))
    readonly property int pillCircle: pillHeight - 2 * pillInset
    readonly property real pillRadius: pillHeight / 2 * Settings.bar.roundness
    // Material Symbols (ttf-material-symbols-variable), used through Icon.qml; Rounded, Outlined or
    // Sharp (Settings app)
    readonly property string iconFont: "Material Symbols " + Settings.appearance.iconStyle
    readonly property int iconSize: 20
    readonly property int iconWeight: Settings.appearance.iconWeight

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
            property string special: "#f5c2e7"
            property string specialText: "#1e1e2e"
            property string red: "#f38ba8"
            property string green: "#a6e3a1"
            property string yellow: "#f9e2af"
        }
    }
}
