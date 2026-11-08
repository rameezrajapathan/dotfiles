import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    required property string dir

    readonly property color base: staged.base
    readonly property color surface: staged.surface
    readonly property color overlay: staged.overlay
    readonly property color text: staged.text
    readonly property color subtext: staged.subtext
    readonly property color accent: staged.accent
    readonly property color accentText: staged.accentText
    readonly property color red: staged.red
    readonly property color green: staged.green
    readonly property color yellow: staged.yellow
    readonly property bool gradientAccent: false

    readonly property string font: staged.font
    readonly property string displayFont: staged.displayFont
    readonly property string iconFont: "Material Symbols " + staged.iconStyle
    readonly property int iconWeight: staged.iconWeight
    readonly property int fontSize: staged.fontSize
    readonly property real roundness: Math.max(0, Math.min(2, staged.roundness))

    readonly property int barGap: Math.min(staged.barGap, Math.floor((staged.barHeight - 24) / 2))
    readonly property int pillHeight: staged.barHeight - 2 * barGap
    readonly property int pillInset: Math.max(5, Math.round((pillHeight - 28) / 2))
    readonly property int pillCircle: pillHeight - 2 * pillInset

    readonly property bool clock24: staged.clock24
    readonly property real blur: staged.blur
    readonly property int restSeconds: staged.restSeconds
    readonly property bool showPower: staged.showPower
    readonly property string wallpaper: staged.wallpaper ? "file://" + dir + "/" + staged.wallpaper : ""
    readonly property string user: staged.user
    readonly property string session: staged.session

    function ms(duration) {
        return duration;
    }

    function round(base, width, height) {
        const r = base * roundness;
        if (width === undefined)
            return r;
        const short = Math.min(width, height);
        const boxy = Math.max(width, height) < 1.6 * short;
        const limit = boxy ? Math.max(base, short * 0.3) : short / 2;
        return Math.max(0, Math.min(r, limit, short / 2));
    }

    function pad(base, radius, width, height) {
        return base + Math.round(Math.max(0, round(radius, width, height) - radius) / 2);
    }

    function wifiIcon(strength) {
        return ["signal_wifi_0_bar", "wifi_1_bar", "wifi_2_bar", "wifi", "wifi"][Math.min(4, Math.floor(strength * 5))];
    }

    FileView {
        path: root.dir + "/theme.json"
        printErrors: false

        JsonAdapter {
            id: staged
            property string base: "#202020"
            property string surface: "#303030"
            property string overlay: "#707070"
            property string text: "#e8e8e8"
            property string subtext: "#a8a8a8"
            property string accent: "#c8c8c8"
            property string accentText: "#202020"
            property string red: "#e06c6c"
            property string green: "#7cc47c"
            property string yellow: "#e0c060"
            property string font: "Fira Sans"
            property string displayFont: "Fira Sans"
            property string iconStyle: "Rounded"
            property int iconWeight: 400
            property int fontSize: 13
            property real roundness: 1
            property int barHeight: 46
            property int barGap: 4
            property bool clock24: false
            property real blur: 0.85
            property int restSeconds: 15
            property bool showPower: true
            property var fontFiles: []
            property string wallpaper: ""
            property string user: ""
            property string session: "hyprland.desktop"
        }
    }

    Instantiator {
        model: staged.fontFiles
        FontLoader {
            required property string modelData
            source: "file://" + root.dir + "/" + modelData
        }
    }
}
