pragma Singleton

import Quickshell
import QtQuick

// Catppuccin Mocha
Singleton {
    readonly property color base: "#1e1e2e"
    readonly property color surface: "#313244"
    readonly property color overlay: "#6c7086"
    readonly property color text: "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color accent: "#89b4fa"
    readonly property color red: "#f38ba8"
    readonly property color green: "#a6e3a1"
    readonly property color yellow: "#f9e2af"

    readonly property string font: "FiraCode Nerd Font Propo"
    readonly property int fontSize: 13
    readonly property int barHeight: 30

    function wifiIcon(strength) {
        return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(strength * 5))];
    }
}
