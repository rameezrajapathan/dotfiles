import QtQuick
import QtQuick.Layouts

// Settings app > Effects: blur, window opacity, dimming, shadows and animations (Hyprland).
SettingsPage {
    id: root
    title: "Effects"
    subtitle: "Blur, transparency and motion."

    onShownChanged: if (shown) Hypr.refresh()

    function changed(keys) {
        return keys.some(k => Hypr.changed(k));
    }

    SettingsSection {
        title: "Blur"
        readonly property var keys: ["decoration.blur.enabled", "decoration.blur.size", "decoration.blur.passes", "decoration.blur.vibrancy"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "blur_on"
            title: "Blur behind windows"
            description: "Also used by the bar and panels."
            Switch {
                checked: Hypr.value("decoration.blur.enabled") ?? false
                onToggled: Hypr.set("decoration.blur.enabled", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "blur_medium"
            title: "Strength"
            SettingsSlider {
                from: 1; to: 16
                value: Hypr.value("decoration.blur.size") ?? 1
                onMoved: v => Hypr.set("decoration.blur.size", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "layers"
            title: "Passes"
            description: "More passes look smoother and cost more GPU."
            SettingsSlider {
                from: 1; to: 4
                value: Hypr.value("decoration.blur.passes") ?? 1
                onMoved: v => Hypr.set("decoration.blur.passes", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "auto_awesome"
            title: "Vibrancy"
            description: "How much color the blur keeps."
            SettingsSlider {
                from: 0; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.blur.vibrancy") ?? 0) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.blur.vibrancy", v / 100)
            }
        }
    }

    SettingsSection {
        title: "Transparency"
        readonly property var keys: ["decoration.active_opacity", "decoration.inactive_opacity", "decoration.dim_inactive", "decoration.dim_strength"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "select_window"
            title: "Focused window"
            SettingsSlider {
                from: 50; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.active_opacity") ?? 1) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.active_opacity", v / 100)
            }
        }
        SettingsRow {
            icon: "filter_none"
            title: "Other windows"
            SettingsSlider {
                from: 50; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.inactive_opacity") ?? 1) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.inactive_opacity", v / 100)
            }
        }
        SettingsRow {
            icon: "brightness_4"
            title: "Dim other windows"
            Switch {
                checked: Hypr.value("decoration.dim_inactive") ?? false
                onToggled: Hypr.set("decoration.dim_inactive", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.dim_inactive") ?? false
            icon: "brightness_medium"
            title: "Dim amount"
            SettingsSlider {
                from: 5; to: 80; stepSize: 5
                value: Math.round((Hypr.value("decoration.dim_strength") ?? 0.5) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.dim_strength", v / 100)
            }
        }
    }

    SettingsSection {
        title: "Shadows"
        readonly property var keys: ["decoration.shadow.enabled", "decoration.shadow.range"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "shadow"
            title: "Window shadows"
            Switch {
                checked: Hypr.value("decoration.shadow.enabled") ?? false
                onToggled: Hypr.set("decoration.shadow.enabled", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("decoration.shadow.enabled") ?? false
            icon: "contrast_square"
            title: "Shadow size"
            SettingsSlider {
                from: 2; to: 40
                value: Hypr.value("decoration.shadow.range") ?? 4
                suffix: " px"
                onMoved: v => Hypr.set("decoration.shadow.range", v)
            }
        }
    }

    SettingsSection {
        title: "Animations"
        readonly property var keys: ["animations.enabled", "pikadots.animationSpeed", "pikadots.workspaceStyle"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "animation"
            title: "Animations"
            Switch {
                checked: Hypr.value("animations.enabled") ?? true
                onToggled: Hypr.set("animations.enabled", !checked)
            }
        }
        SettingsRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "speed"
            title: "Speed"
            SettingsSegmented {
                options: [
                    { value: 0.6, label: "Fast" },
                    { value: 1, label: "Normal" },
                    { value: 1.6, label: "Relaxed" }
                ]
                current: Hypr.value("pikadots.animationSpeed")
                onPicked: v => Hypr.set("pikadots.animationSpeed", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "swap_horiz"
            title: "Workspace switch"
            SettingsSegmented {
                options: [
                    { value: "slide", label: "Slide" },
                    { value: "slidevert", label: "Vertical" },
                    { value: "slidefade 20%", label: "Slide + fade" },
                    { value: "fade", label: "Fade" }
                ]
                current: Hypr.value("pikadots.workspaceStyle")
                onPicked: v => Hypr.set("pikadots.workspaceStyle", v)
            }
        }
    }
}
