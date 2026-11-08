import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Keyboard & mouse"
    subtitle: "Typing and pointing."

    onShownChanged: if (shown) Hypr.refresh()

    function changed(keys) {
        return keys.some(k => Hypr.changed(k));
    }

    SettingsSection {
        title: "Keyboard"
        readonly property var keys: ["input.kb_layout", "input.kb_options", "input.repeat_rate", "input.repeat_delay"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "keyboard"
            title: "Layouts"
            description: "Comma-separated, e.g. us,de,ara. Press Enter to apply."
            SettingsTextField {
                text: Hypr.value("input.kb_layout") ?? ""
                placeholder: "us"
                onAccepted: t => Hypr.set("input.kb_layout", t.replace(/\s+/g, ""))
            }
        }
        SettingsRow {
            icon: "tune"
            title: "Layout options"
            description: "XKB options, e.g. grp:alt_shift_toggle to switch layouts, caps:escape."
            SettingsTextField {
                text: Hypr.value("input.kb_options") ?? ""
                placeholder: "none"
                onAccepted: t => Hypr.set("input.kb_options", t.replace(/\s+/g, ""))
            }
        }
        SettingsRow {
            icon: "keyboard_double_arrow_right"
            title: "Repeat rate"
            description: "Characters per second while a key is held."
            SettingsSlider {
                from: 10; to: 60
                value: Hypr.value("input.repeat_rate") ?? 25
                suffix: "/s"
                onMoved: v => Hypr.set("input.repeat_rate", v)
            }
        }
        SettingsRow {
            icon: "hourglass_top"
            title: "Repeat delay"
            description: "How long to hold before it repeats."
            SettingsSlider {
                from: 150; to: 1000; stepSize: 50
                value: Hypr.value("input.repeat_delay") ?? 600
                suffix: " ms"
                onMoved: v => Hypr.set("input.repeat_delay", v)
            }
        }
    }

    SettingsSection {
        title: "Mouse"
        readonly property var keys: ["input.sensitivity", "input.accel_profile", "input.follow_mouse", "input.natural_scroll", "input.swallow_focus_click", "cursor.hide_on_key_press"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: "mouse"
            title: "Pointer speed"
            SettingsSlider {
                from: -100; to: 100; stepSize: 5
                value: Math.round((Hypr.value("input.sensitivity") ?? 0) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("input.sensitivity", v / 100)
            }
        }
        SettingsRow {
            icon: "trending_up"
            title: "Acceleration"
            SettingsSegmented {
                options: [
                    { value: "", label: "Default" },
                    { value: "adaptive", label: "Adaptive" },
                    { value: "flat", label: "Flat" }
                ]
                current: Hypr.value("input.accel_profile") ?? ""
                onPicked: v => Hypr.set("input.accel_profile", v)
            }
        }
        SettingsRow {
            icon: "ads_click"
            title: "Focus follows the mouse"
            description: "Windows take focus when the pointer moves over them."
            Switch {
                checked: (Hypr.value("input.follow_mouse") ?? 1) !== 0
                onToggled: Hypr.set("input.follow_mouse", checked ? 0 : 1)
            }
        }
        SettingsSwitchRow {
            icon: "swap_vert"
            title: "Natural scrolling (mouse)"
            hypr: "input.natural_scroll"
        }
        SettingsSwitchRow {
            icon: "left_click"
            title: "Click only focuses"
            description: "The click that focuses a window isn't passed on to it, so you can't hit a button by accident."
            hypr: "input.swallow_focus_click"
        }
        SettingsSwitchRow {
            icon: "visibility_off"
            title: "Hide pointer while typing"
            description: "It comes back when you move the mouse."
            hypr: "cursor.hide_on_key_press"
        }
    }

    SettingsSection {
        title: "Touchpad"
        readonly property var keys: ["input.touchpad.natural_scroll", "input.touchpad.tap_to_click", "input.touchpad.disable_while_typing", "input.touchpad.scroll_factor", "pikadots.gestures"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsSwitchRow {
            icon: "swipe_vertical"
            title: "Natural scrolling"
            description: "Content moves with your fingers."
            hypr: "input.touchpad.natural_scroll"
        }
        SettingsSwitchRow {
            icon: "touch_app"
            title: "Tap to click"
            hypr: "input.touchpad.tap_to_click"
            fallback: true
        }
        SettingsSwitchRow {
            icon: "keyboard_hide"
            title: "Ignore while typing"
            hypr: "input.touchpad.disable_while_typing"
            fallback: true
        }
        SettingsRow {
            icon: "unfold_more"
            title: "Scroll speed"
            SettingsSlider {
                from: 0.2; to: 2; stepSize: 0.1; decimals: 1
                value: Hypr.value("input.touchpad.scroll_factor") ?? 1
                suffix: "×"
                onMoved: v => Hypr.set("input.touchpad.scroll_factor", v)
            }
        }
        SettingsSwitchRow {
            icon: "swipe"
            title: "Gestures"
            description: "3 fingers: sideways switches workspaces, up opens the overview, down shows scratchpad 1. Pinch with 4 fingers to zoom. Hold Super: 3 fingers move a window, 4 resize it."
            hypr: "pikadots.gestures"
            fallback: true
        }
    }
}
