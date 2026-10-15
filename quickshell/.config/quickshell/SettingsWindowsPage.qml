import QtQuick
import QtQuick.Layouts

// Settings app > Windows: tiling layout, gaps, borders and corners (Hyprland, applied live).
SettingsPage {
    id: root
    title: "Windows"
    subtitle: "How windows are arranged and framed. Changes show on your desktop right away."

    onShownChanged: if (shown) Hypr.refresh()

    function changed(keys) {
        return keys.some(k => Hypr.changed(k));
    }

    SettingsSection {
        title: "Layout"
        readonly property var keys: ["general.layout"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "dashboard"
            title: "Tiling layout"
            description: "Dwindle splits in a spiral, Master keeps one big window, Scrolling lines windows up in columns."
            SettingsSegmented {
                options: [
                    { value: "dwindle", label: "Dwindle", icon: "view_quilt" },
                    { value: "master", label: "Master", icon: "view_sidebar" },
                    { value: "scrolling", label: "Scrolling", icon: "view_column" }
                ]
                current: Hypr.value("general.layout")
                onPicked: v => Hypr.set("general.layout", v)
            }
        }
    }

    SettingsSection {
        title: "Gaps"
        readonly property var keys: ["general.gaps_in", "general.gaps_out"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "border_inner"
            title: "Between windows"
            SettingsSlider {
                from: 0; to: 24
                value: Hypr.value("general.gaps_in") ?? 0
                suffix: " px"
                onMoved: v => Hypr.set("general.gaps_in", v)
            }
        }
        SettingsRow {
            icon: "border_outer"
            title: "Around the screen edge"
            SettingsSlider {
                from: 0; to: 48
                value: Hypr.value("general.gaps_out") ?? 0
                suffix: " px"
                onMoved: v => Hypr.set("general.gaps_out", v)
            }
        }
    }

    SettingsSection {
        title: "Borders"
        subtitle: "Border colors follow the wallpaper."
        readonly property var keys: ["general.border_size", "general.resize_on_border"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "border_style"
            title: "Border width"
            SettingsSlider {
                from: 0; to: 6
                value: Hypr.value("general.border_size") ?? 0
                suffix: " px"
                onMoved: v => Hypr.set("general.border_size", v)
            }
        }
        SettingsRow {
            icon: "drag_pan"
            title: "Resize by dragging borders"
            Switch {
                checked: Hypr.value("general.resize_on_border") ?? false
                onToggled: Hypr.set("general.resize_on_border", !checked)
            }
        }
    }

    SettingsSection {
        title: "Corners"
        readonly property var keys: ["decoration.rounding", "decoration.rounding_power"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "rounded_corner"
            title: "Roundness"
            SettingsSlider {
                from: 0; to: 24
                value: Hypr.value("decoration.rounding") ?? 0
                suffix: " px"
                onMoved: v => Hypr.set("decoration.rounding", v)
            }
        }
        SettingsRow {
            icon: "crop_square"
            title: "Corner shape"
            description: "Higher values give smoother, squircle-like corners."
            SettingsSlider {
                from: 1; to: 5; stepSize: 0.5; decimals: 1
                value: Hypr.value("decoration.rounding_power") ?? 2
                onMoved: v => Hypr.set("decoration.rounding_power", v)
            }
        }
    }
}
