import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.bar
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Appearance"
    subtitle: "Colors come from your wallpaper. Pick one, then fine-tune the mode and palette."

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string current: wallpaperConf.text().match(/^\s*path\s*=\s*(.+)$/m)?.[1]?.trim().replace(/^~/, Quickshell.env("HOME")) ?? ""

    FileView {
        id: wallpaperConf
        path: Quickshell.env("HOME") + "/.config/hypr/wallpaper.conf"
        watchChanges: true
        onFileChanged: reload()
        printErrors: false
    }

    FolderListModel {
        id: files
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    SettingsSection {
        title: "Wallpaper"
        subtitle: root.folder.replace(Quickshell.env("HOME"), "~")

        FadeMask {
            id: stripFade
            target: strip
            size: 56
        }

        ListView {
            id: strip
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            Layout.topMargin: 14
            Layout.bottomMargin: 4
            layer.enabled: stripFade.needed
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: stripFade
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }
            orientation: ListView.Horizontal
            leftMargin: Theme.pad(14, 16)
            rightMargin: Theme.pad(14, 16)
            spacing: 12
            clip: true
            model: files
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 400
            onCountChanged: positionTimer.restart()
            Timer {
                id: positionTimer
                interval: 50
                onTriggered: {
                    for (let i = 0; i < files.count; i++)
                        if (files.get(i, "filePath") === root.current)
                            strip.positionViewAtIndex(i, ListView.Center);
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => strip.flick((wheel.angleDelta.y || wheel.angleDelta.x) * 8, 0)
            }

            delegate: Item {
                id: thumb
                required property string filePath
                required property string fileName
                readonly property bool selected: filePath === root.current

                width: 190
                height: 150

                ClippingRectangle {
                    id: picture
                    y: 3
                    width: parent.width
                    height: 116
                    radius: Theme.round(14, width, height)
                    color: Qt.alpha(Theme.base, 0.6)
                    scale: thumbMouse.containsMouse ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutQuint } }

                    Image {
                        id: image
                        anchors.fill: parent
                        source: "file://" + thumb.filePath
                        sourceSize.width: 380
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
                    }
                    Icon {
                        visible: image.status !== Image.Ready
                        anchors.centerIn: parent
                        name: "image"
                        color: Theme.overlay
                    }
                    GlassRim {}
                }
                Rectangle {
                    anchors.fill: picture
                    anchors.margins: -3
                    radius: picture.radius + 3
                    color: "transparent"
                    border.width: 3
                    border.color: Theme.gradientAccent ? "transparent" : Theme.accent
                    GradientBorder {
                    }
                    visible: thumb.selected
                }
                Rectangle {
                    visible: thumb.selected
                    anchors { right: picture.right; top: picture.top; margins: Theme.pad(8, 14) }
                    width: 24
                    height: 24
                    radius: Theme.round(12, width, height)
                    color: Theme.accent
                    Icon { anchors.centerIn: parent; name: "check"; size: 16; weight: 600; color: Theme.accentText }
                }
                Label {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 4 }
                    text: thumb.fileName.replace(/\.[^.]+$/, "").replace(/[-_.]+/g, " ")
                    color: thumb.selected ? Theme.accent : Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: thumbMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh", thumb.filePath])
                }
            }
        }

        SettingsRow {
            icon: "folder_open"
            title: "Wallpaper folder"
            description: files.count + " pictures. Add more here and they show up above."
            Pill {
                icon: "open_in_new"
                implicitHeight: 30
                onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/app.sh", "files", root.folder])
            }
        }
    }

    SettingsSection {
        title: "Colors"

        SettingsRow {
            icon: "contrast"
            title: "Mode"
            description: "Auto picks light for bright wallpapers and dark otherwise."
            SettingsSegmented {
                options: [
                    { value: "auto", label: "Auto", icon: "brightness_auto" },
                    { value: "light", label: "Light", icon: "light_mode" },
                    { value: "dark", label: "Dark", icon: "dark_mode" }
                ]
                current: Settings.appearance.themeMode
                onPicked: v => {
                    Settings.appearance.themeMode = v;
                    Settings.retheme();
                }
            }
        }

        SettingsRow {
            icon: "palette"
            title: "Palette style"
            description: Glass.neutral ? "Glass is colorless right now. Turn on Glass › Wallpaper color to use a palette." : "How strongly the wallpaper's colors show through."
            below: true
            SettingsChips {
                options: [
                    { value: "auto", label: "Auto" },
                    { value: "tonal-spot", label: "Tonal" },
                    { value: "content", label: "Vivid" },
                    { value: "multi", label: "Multi-color" },
                    { value: "expressive", label: "Expressive" },
                    { value: "fidelity", label: "Fidelity" },
                    { value: "rainbow", label: "Rainbow" },
                    { value: "neutral", label: "Neutral" },
                    { value: "monochrome", label: "Monochrome" }
                ]
                current: Settings.appearance.scheme
                onPicked: v => {
                    Settings.appearance.scheme = v;
                    Settings.retheme();
                }
            }
        }

        SettingsRow {
            icon: "gradient"
            title: "Gradient accents"
            description: Theme.multiColor ? "Accent fills blend from one wallpaper color into the next."
                : "Accent fills blend into a deeper shade of the same color."
            Switch {
                checked: Settings.appearance.gradient
                onToggled: {
                    Settings.appearance.gradient = !Settings.appearance.gradient;
                    Settings.retheme();
                }
            }
        }

        SettingsRow {
            icon: "format_color_fill"
            title: "Current palette"
            description: "Changes live with the wallpaper."
            below: true

            ColumnLayout {
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.round(12, width, height)
                    border.width: Glass.active ? 0 : 1
                    border.color: Qt.alpha(Theme.overlay, 0.3)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.base }
                        GradientStop { position: 0.16; color: Theme.surface }
                        GradientStop { position: 0.36; color: Theme.accent }
                        GradientStop { position: 0.56; color: Theme.multiColor ? Theme.accent2 : Theme.accentEnd }
                        GradientStop { position: 0.76; color: Theme.multiColor ? Theme.accent3 : Theme.special }
                        GradientStop { position: 1; color: Theme.text }
                    }
                    GlassRim {}
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            { name: "Accent", color: Theme.accent },
                            { name: Theme.multiColor ? "Second" : "Shade", color: Theme.multiColor ? Theme.accent2 : Theme.accentEnd },
                            { name: Theme.multiColor ? "Third" : "Special", color: Theme.multiColor ? Theme.accent3 : Theme.special },
                            { name: "Red", color: Theme.red },
                            { name: "Yellow", color: Theme.yellow },
                            { name: "Green", color: Theme.green }
                        ]
                        Rectangle {
                            required property var modelData
                            implicitWidth: swatchRow.implicitWidth + 16
                            implicitHeight: 24
                            radius: Theme.round(12, width, height)
                            color: Qt.alpha(Theme.base, 0.6)
                            Row {
                                id: swatchRow
                                anchors.centerIn: parent
                                spacing: 6
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12
                                    height: 12
                                    radius: Theme.round(6, width, height)
                                    color: modelData.color
                                    Behavior on color { ColorAnimation { duration: Theme.ms(400) } }
                                }
                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: Theme.subtext
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }
                            GlassRim {}
                        }
                    }
                }
            }
        }

        SettingsRow {
            icon: "widgets"
            title: "Qt and KDE apps"
            description: "Dolphin, Kate and other Qt apps use these colors and icons. Plasma keeps its own."
            Switch {
                checked: Settings.appearance.qtTheme
                onToggled: {
                    Settings.appearance.qtTheme = !checked;
                    Settings.applyQtTheme();
                }
            }
        }
    }

    SettingsSection {
        title: "Glass"

        SettingsRow {
            icon: "blur_on"
            title: "Material"
            description: "Liquid glass for the shell, Hyprland windows, terminals and apps. Frosted stays easy to read; Clear shows the most of the wallpaper."
            SettingsSegmented {
                options: Glass.names.map(n => ({ value: n, label: Glass.labels[n] }))
                current: Glass.preset
                onPicked: v => Glass.setPreset(v)
            }
        }

        SettingsRow {
            below: true
            separator: Glass.preset !== "off"
            icon: "preview"
            title: "Preview"
            description: Glass.active ? "How panels look over your wallpaper." : "Glass is off: plain translucent panels."
            GlassPreview {
                Layout.fillWidth: true
            }
        }

        SettingsRow {
            visible: Glass.preset !== "off"
            icon: "colors"
            title: "Wallpaper color"
            description: "Off makes the shell, window borders and apps colorless, like clear glass. On keeps the wallpaper's colors."
            Switch {
                checked: Settings.glass.color
                onToggled: Glass.setColor(!checked)
            }
        }

        SettingsRow {
            visible: Glass.preset !== "off"
            icon: "light_mode"
            title: "Light direction"
            description: "Where the rim highlight catches the light. 0° is straight above."
            SettingsSlider {
                from: -180
                to: 180
                stepSize: 5
                value: Settings.glass.lightAngle
                suffix: "°"
                onMoved: v => Glass.setLightAngle(v)
            }
        }

        Repeater {
            model: [
                { key: "tint", icon: "opacity", title: "Shell tint", description: "Opacity of the bar and panels.", from: 20, to: 95, scale: 100, suffix: "%" },
                { key: "card", icon: "dashboard", title: "Cards", description: "Opacity of cards and tiles inside panels.", from: 10, to: 90, scale: 100, suffix: "%" },
                { key: "window", icon: "web_asset", title: "App windows", description: "GTK, VS Code and Zen window backgrounds.", from: 30, to: 100, scale: 100, suffix: "%" },
                { key: "terminal", icon: "terminal", title: "Terminal", description: "kitty background opacity.", from: 30, to: 100, scale: 100, suffix: "%" },
                { key: "rim", icon: "highlight", title: "Rim light", description: "Brightness of the specular edge.", from: 0, to: 100, scale: 100, suffix: "%" },
                { key: "refraction", icon: "lens_blur", title: "Refraction", description: "How strongly panel edges bend the wallpaper behind them.", from: 0, to: 100, scale: 100, suffix: "%" },
                { key: "chroma", icon: "gradient", title: "Color fringe", description: "Chromatic split along refracting edges.", from: 0, to: 100, scale: 100, suffix: "%" },
                { key: "blurSize", icon: "blur_medium", title: "Blur radius", description: "Hyprland blur size behind windows and panels.", from: 2, to: 16, scale: 1, suffix: "" },
                { key: "blurPasses", icon: "layers", title: "Blur passes", description: "More passes give a smoother, heavier blur.", from: 1, to: 5, scale: 1, suffix: "" },
                { key: "vibrancy", icon: "palette", title: "Vibrancy", description: "Saturation boost of colors seen through the glass.", from: 0, to: 100, scale: 100, suffix: "%" },
                { key: "inactiveOpacity", icon: "select_window", title: "Inactive windows", description: "Opacity of unfocused windows.", from: 50, to: 100, scale: 100, suffix: "%" }
            ]

            SettingsRow {
                required property var modelData
                visible: Glass.preset === "custom"
                icon: modelData.icon
                title: modelData.title
                description: modelData.description
                SettingsSlider {
                    from: modelData.from
                    to: modelData.to
                    stepSize: 1
                    value: Math.round((Glass.value(modelData.key) ?? 0) * modelData.scale)
                    suffix: modelData.suffix
                    onMoved: v => Glass.setCustom(modelData.key, modelData.scale === 1 ? Math.round(v) : Math.round(v) / modelData.scale)
                }
            }
        }

        SettingsRow {
            visible: Glass.preset === "custom"
            icon: "shadow"
            title: "Shadows"
            description: "Soft shadows under panels and windows."
            Switch {
                checked: Glass.value("shadows") ?? false
                onToggled: Glass.setCustom("shadows", !checked)
            }
        }
    }

    SettingsSection {
        title: "Shape"

        SettingsRow {
            icon: "rounded_corner"
            title: "Corner roundness"
            description: "Every corner in the shell and Hyprland windows. 0% is square, 100% is the default, 200% turns small shapes into circles and pills."
            SettingsSlider {
                from: 0
                to: 200
                stepSize: 5
                value: Math.round(Settings.appearance.roundness * 100)
                suffix: "%"
                onMoved: v => {
                    Settings.appearance.roundness = Math.round(v) / 100;
                    Hypr.set("decoration.rounding", Math.round(10 * Settings.appearance.roundness));
                }
            }
        }
    }
}
