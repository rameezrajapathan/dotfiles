import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

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
        readonly property var keys: ["decoration.blur.enabled", "decoration.blur.size", "decoration.blur.passes", "decoration.blur.vibrancy", "decoration.blur.proportional"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsSwitchRow {
            icon: "blur_on"
            title: "Blur behind windows"
            description: "Also used by the bar and panels."
            hypr: "decoration.blur.enabled"
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
        SettingsSwitchRow {
            visible: Hypr.value("decoration.blur.enabled") ?? false
            icon: "gradient"
            title: "Follow transparency"
            description: "See-through parts blur more, solid parts blur less."
            hypr: "decoration.blur.proportional"
        }
    }

    SettingsSection {
        id: backdrop
        title: "Backdrop"
        subtitle: "What shows through see-through windows, the bar and panels. Needs blur on."
        visible: Hypr.value("decoration.blur.enabled") ?? false
        readonly property int variant: Hypr.value("decoration.blur.variant") ?? 0
        readonly property var current: styles.find(st => st.value === variant) ?? styles[0]
        readonly property var styles: [
            { value: 0, label: "Plain", icon: "blur_on", about: "Classic smooth blur. The lightest on the GPU." },
            { value: 3, label: "Rain", icon: "water_drop", motion: true, about: "Raindrops running down a window pane." },
            { value: 9, label: "Aurora", icon: "airwave", motion: true, about: "Drifting northern-lights curtains in your wallpaper's colors." },
            { value: 5, label: "Fluid jar", icon: "local_drink", motion: true, about: "Liquid that sloshes when you move a window." },
            { value: 7, label: "Heat", icon: "heat", motion: true, about: "A wavy heat shimmer with color fringes." },
            { value: 4, label: "Water", icon: "water", about: "Ripples follow the pointer." },
            { value: 2, label: "Ripple", icon: "adjust", about: "A ripple spreads from every click." },
            { value: 8, label: "Acrylic", icon: "lens_blur", about: "Thick glass with curved, refracting edges." },
            { value: 1, label: "Frost", icon: "ac_unit", about: "Cracked ice." },
            { value: 6, label: "Prism", icon: "change_history", about: "Triangle-cut refraction." },
            { value: 10, label: "Haze", icon: "foggy", about: "A soft pearly sheen that shifts color." }
        ]
        readonly property var knobs: ({
            3: [
                { key: "decoration.blur.drops.speed", title: "Rain speed", icon: "speed", from: 0.5, to: 8, step: 0.5, decimals: 1, suffix: "×" },
                { key: "decoration.blur.glass.size", title: "Drop size", icon: "water_drop", from: 10, to: 160, step: 5, suffix: " px" }
            ],
            9: [
                { key: "decoration.blur.aurora.speed", title: "Drift speed", icon: "speed", from: 0.1, to: 4, step: 0.1, decimals: 1, suffix: "×" },
                { key: "decoration.blur.aurora.intensity", title: "Strength", icon: "brightness_6", from: 0.05, to: 1, step: 0.05, percent: true }
            ],
            5: [
                { key: "decoration.blur.fluid_jar.fill_amount", title: "How full", icon: "local_drink", from: 0.1, to: 0.9, step: 0.05, percent: true },
                { key: "decoration.blur.fluid_jar.turbulence", title: "Turbulence", icon: "cyclone", from: 0, to: 5, step: 0.1, decimals: 1, suffix: "×" },
                { key: "decoration.blur.fluid_jar.speed", title: "Speed", icon: "speed", from: 0.5, to: 8, step: 0.1, decimals: 1, suffix: "×" }
            ],
            7: [
                { key: "decoration.blur.heat_shimmer.speed", title: "Shimmer speed", icon: "speed", from: 0.1, to: 4, step: 0.1, decimals: 1, suffix: "×" }
            ],
            4: [
                { key: "decoration.blur.water.strength", title: "Strength", icon: "waves", from: 4, to: 32, step: 1, suffix: " px" },
                { key: "decoration.blur.water.radius", title: "Pointer size", icon: "radio_button_unchecked", from: 5, to: 120, step: 5, suffix: " px" }
            ],
            2: [
                { key: "decoration.blur.ripple.strength", title: "Strength", icon: "waves", from: 4, to: 32, step: 1, suffix: " px" },
                { key: "decoration.blur.ripple.radius", title: "Size", icon: "radio_button_unchecked", from: 100, to: 1000, step: 50, suffix: " px" },
                { key: "decoration.blur.ripple.duration", title: "Duration", icon: "timer", from: 0.2, to: 2, step: 0.05, decimals: 2, suffix: " s" }
            ],
            8: [
                { key: "decoration.blur.acrylic.clarity", title: "Clarity", icon: "visibility", from: 0, to: 1, step: 0.05, percent: true },
                { key: "decoration.blur.acrylic.refraction", title: "Edge bend", icon: "rounded_corner", from: 0, to: 48, step: 1, suffix: " px" }
            ],
            6: [
                { key: "decoration.blur.glass.size", title: "Pattern size", icon: "change_history", from: 10, to: 200, step: 5, suffix: " px" },
                { key: "decoration.blur.glass.refraction", title: "Refraction", icon: "lens_blur", from: 0, to: 20, step: 1, suffix: " px" }
            ],
            10: [
                { key: "decoration.blur.haze.intensity", title: "Sheen", icon: "brightness_6", from: 0, to: 1, step: 0.05, percent: true },
                { key: "decoration.blur.haze.iridescence", title: "Color shift", icon: "palette", from: 0, to: 1, step: 0.05, percent: true }
            ]
        })
        readonly property var keys: ["decoration.blur.variant", "pikadots.backdropColors", "pikadots.pauseOnBattery"].concat(
            Object.values(knobs).reduce((all, list) => all.concat(list), []).map(k => k.key))
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsRow {
            icon: backdrop.current.icon
            title: "Style"
            description: backdrop.current.about + (backdrop.current.motion ? " Animated, so it uses more GPU and battery." : backdrop.variant !== 0 ? " Uses more GPU than Plain." : "")
            below: true

            GridLayout {
                columns: Math.max(2, Math.min(6, Math.floor((width + 8) / 104)))
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: backdrop.styles

                    SettingsStyleCard {
                        id: tile
                        required property var modelData
                        selected: backdrop.variant === modelData.value
                        inset: 0
                        contentSpacing: 0
                        onClicked: Hypr.set("decoration.blur.variant", tile.modelData.value)

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 64

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Icon {
                                    Layout.alignment: Qt.AlignHCenter
                                    name: tile.modelData.icon
                                    size: 20
                                    filled: tile.selected
                                    color: tile.selected ? Theme.accent : Theme.subtext
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tile.modelData.label
                                    font.weight: tile.selected ? Font.DemiBold : Font.Normal
                                }
                            }
                            Icon {
                                visible: tile.modelData.motion === true
                                anchors { top: parent.top; right: parent.right; margins: 6 }
                                name: "animation"
                                size: 13
                                color: Theme.subtext
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: backdrop.knobs[backdrop.variant] ?? []

            SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                SettingsSlider {
                    from: modelData.percent ? modelData.from * 100 : modelData.from
                    to: modelData.percent ? modelData.to * 100 : modelData.to
                    stepSize: modelData.percent ? modelData.step * 100 : modelData.step
                    decimals: modelData.decimals ?? 0
                    suffix: modelData.percent ? "%" : modelData.suffix ?? ""
                    value: {
                        const v = Hypr.value(modelData.key) ?? modelData.from;
                        return modelData.percent ? Math.round(v * 100) : v;
                    }
                    onMoved: v => Hypr.set(modelData.key, modelData.percent ? v / 100 : v)
                }
            }
        }

        SettingsSwitchRow {
            visible: backdrop.variant === 9 || backdrop.variant === 5
            icon: "wallpaper"
            title: "Colors from the wallpaper"
            description: "Off uses Hyprland's own green and violet aurora and pink fluid."
            hypr: "pikadots.backdropColors"
            fallback: true
        }
        SettingsSwitchRow {
            icon: "battery_saver"
            title: "Pause on battery"
            description: "Freezes animated styles and the turning border while unplugged."
            hypr: "pikadots.pauseOnBattery"
            fallback: true
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
        SettingsSwitchRow {
            icon: "brightness_4"
            title: "Dim other windows"
            hypr: "decoration.dim_inactive"
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

        SettingsSwitchRow {
            icon: "shadow"
            title: "Window shadows"
            hypr: "decoration.shadow.enabled"
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
        title: "Panels"
        subtitle: "How the control center, calendar, weather, launcher and the other panels come out of the bar."
        canReset: Settings.appearance.panelAnimation !== "slide" || Settings.appearance.panelSpeed !== 1
        onReset: {
            Settings.appearance.panelAnimation = "slide";
            Settings.appearance.panelSpeed = 1;
        }

        SettingsRow {
            visible: Theme.reduceMotion
            icon: "motion_photos_off"
            title: "Reduce motion is on"
            description: "Panels open instantly, whichever style is picked (Settings > Accessibility)."
            Pill {
                text: "Turn off"
                onClicked: {
                    Settings.accessibility.reduceMotion = false;
                    Hypr.set("animations.enabled", true);
                    Quickshell.execDetached(["sh", "-c", "sleep 0.6; exec \"$HOME/.config/hypr/scripts/accessibility.sh\""]);
                }
            }
        }
        SettingsRow {
            icon: "animation"
            title: "Open and close"
            description: PanelMotion.info(PanelMotion.style).description
            below: true

            GridLayout {
                columns: Math.max(1, Math.min(3, Math.floor((width + 10) / 170)))
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: PanelMotion.styles

                    SettingsStyleCard {
                        id: card
                        required property var modelData
                        selected: PanelMotion.style === modelData.id
                        icon: modelData.icon
                        label: modelData.label
                        onClicked: Settings.appearance.panelAnimation = card.modelData.id

                        PanelMotionPreview {
                            Layout.fillWidth: true
                            style: card.modelData.id
                            running: root.shown && !Theme.reduceMotion
                        }
                    }
                }
            }
        }
        SettingsRow {
            icon: "speed"
            title: "Speed"
            description: "Faster to the right."
            SettingsSlider {
                from: 50
                to: 200
                stepSize: 10
                value: Math.round(Settings.appearance.panelSpeed * 100)
                suffix: "%"
                onMoved: v => Settings.appearance.panelSpeed = Math.round(v) / 100
            }
        }
        SettingsRow {
            icon: "play_circle"
            title: "Try it"
            description: "Opens the control center with this animation."
            Pill {
                text: "Open"
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "controlcenter", "toggle", ""])
            }
        }
    }

    SettingsSection {
        title: "Animations"
        readonly property var keys: ["animations.enabled", "pikadots.animationSpeed", "pikadots.workspaceStyle", "pikadots.motion", "pikadots.windowStyle", "pikadots.borderLoop", "misc.animate_mouse_windowdragging", "misc.animate_manual_resizes", "decoration.wobble.enabled", "decoration.wobble.intensity", "decoration.motion_blur.enabled"]
        canReset: root.changed(keys)
        onReset: Hypr.reset(keys)

        SettingsSwitchRow {
            icon: "animation"
            title: "Animations"
            hypr: "animations.enabled"
            fallback: true
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
        SettingsRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "airwave"
            title: "Feel"
            description: "Springs settle naturally; Bouncy overshoots a little. Classic is the old ease-out curve."
            SettingsSegmented {
                options: [
                    { value: "smooth", label: "Smooth" },
                    { value: "springy", label: "Springy" },
                    { value: "bouncy", label: "Bouncy" },
                    { value: "classic", label: "Classic" }
                ]
                current: Hypr.value("pikadots.motion")
                onPicked: v => Hypr.set("pikadots.motion", v)
            }
        }
        SettingsRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "open_in_full"
            title: "Opening and closing windows"
            SettingsSegmented {
                options: [
                    { value: "popin", label: "Pop in" },
                    { value: "slide", label: "Slide" },
                    { value: "gnomed", label: "Grow" }
                ]
                current: Hypr.value("pikadots.windowStyle")
                onPicked: v => Hypr.set("pikadots.windowStyle", v)
            }
        }
        SettingsSwitchRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "rotate_right"
            title: "Turning border"
            description: "The gradient border and glow slowly circle the focused window. Best with gradient accents or Glass."
            hypr: "pikadots.borderLoop"
        }
        SettingsSwitchRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "drag_pan"
            title: "Animate dragging and resizing"
            description: "Windows glide after the pointer instead of sticking to it."
            hypr: "misc.animate_mouse_windowdragging"
            onSwitched: value => Hypr.set("misc.animate_manual_resizes", value)
        }
        SettingsSwitchRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "waves"
            title: "Wobbly windows"
            description: "Windows flex like jelly while you drag or resize them."
            hypr: "decoration.wobble.enabled"
        }
        SettingsRow {
            visible: (Hypr.value("animations.enabled") ?? true) && (Hypr.value("decoration.wobble.enabled") ?? false)
            icon: "earthquake"
            title: "Wobble amount"
            SettingsSlider {
                from: 5; to: 100; stepSize: 5
                value: Math.round((Hypr.value("decoration.wobble.intensity") ?? 0.2) * 100)
                suffix: "%"
                onMoved: v => Hypr.set("decoration.wobble.intensity", v / 100)
            }
        }
        SettingsSwitchRow {
            visible: Hypr.value("animations.enabled") ?? true
            icon: "motion_blur"
            title: "Motion blur"
            description: "Smears windows slightly while they move or resize."
            hypr: "decoration.motion_blur.enabled"
        }
    }
}
