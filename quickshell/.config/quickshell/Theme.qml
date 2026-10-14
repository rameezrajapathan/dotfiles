pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Colors come from ~/.local/state/theme/quickshell.json, written by matugen from the wallpaper
// (hypr/scripts/theme.sh) and reloaded live. The defaults are Catppuccin Mocha.
Singleton {
    readonly property color base: colors.base
    readonly property color surface: colors.surface
    readonly property color overlay: colors.overlay
    readonly property color text: colors.text
    readonly property color subtext: colors.subtext
    readonly property color accent: colors.accent
    // Text and icons drawn on top of accent
    readonly property color accentText: colors.accentText
    readonly property color red: colors.red
    readonly property color green: colors.green
    readonly property color yellow: colors.yellow

    readonly property string font: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 13
    readonly property int barHeight: 30

    function wifiIcon(strength) {
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(strength * 5))];
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
            property string red: "#f38ba8"
            property string green: "#a6e3a1"
            property string yellow: "#f9e2af"
        }
    }
}
