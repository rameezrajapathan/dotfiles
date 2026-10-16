import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Accessibility"
    subtitle: "Zoom, larger text and calmer motion."

    readonly property var a: Settings.accessibility
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts/"
    property real zoom: 1

    Timer {
        id: applyTimer
        interval: 600
        onTriggered: Quickshell.execDetached([root.scripts + "accessibility.sh"])
    }

    SettingsSection {
        title: "Zoom"
        subtitle: "Super + Alt + = and − zoom around the pointer, Super + Alt + 0 resets."

        SettingsRow {
            icon: "zoom_in"
            title: "Screen zoom"
            description: "Follows the pointer. Resets when you log out."
            SettingsSlider {
                from: 1; to: 4; stepSize: 0.25
                decimals: 2
                value: root.zoom
                suffix: "×"
                onMoved: v => {
                    root.zoom = v;
                    Quickshell.execDetached([root.scripts + "zoom.sh", String(v)]);
                }
            }
        }
    }

    SettingsSection {
        title: "Reading"
        canReset: root.a.textScale !== 1
        onReset: {
            root.a.textScale = 1;
            applyTimer.restart();
        }

        SettingsRow {
            icon: "format_size"
            title: "Text size"
            description: "The shell, GTK apps, and Qt apps when Fonts & icons > \"Use in apps\" is on."
            SettingsSlider {
                from: 100; to: 150; stepSize: 5
                value: Math.round(root.a.textScale * 100)
                suffix: "%"
                onMoved: v => {
                    root.a.textScale = v / 100;
                    applyTimer.restart();
                }
            }
        }
    }

    SettingsSection {
        title: "Motion"

        SettingsRow {
            icon: "animation"
            title: "Reduce motion"
            description: "Panels, windows and apps switch without sliding or fading. Turns off Effects > Animations too."
            Switch {
                checked: root.a.reduceMotion
                onToggled: {
                    root.a.reduceMotion = !checked;
                    Hypr.set("animations.enabled", !root.a.reduceMotion);
                    applyTimer.restart();
                }
            }
        }
    }

    onShownChanged: if (shown) zoomReader.running = true
    Process {
        id: zoomReader
        command: ["hyprctl", "-j", "getoption", "cursor:zoom_factor"]
        stdout: StdioCollector {
            onStreamFinished: root.zoom = JSON.parse(text).float ?? 1
        }
    }
}
