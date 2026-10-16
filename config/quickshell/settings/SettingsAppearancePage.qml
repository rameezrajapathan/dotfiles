import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
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

        ListView {
            id: strip
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            Layout.topMargin: 14
            Layout.bottomMargin: 4
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
                }
                Rectangle {
                    anchors.fill: picture
                    anchors.margins: -3
                    radius: picture.radius + 3
                    color: "transparent"
                    border.width: 3
                    border.color: Theme.accent
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
            description: "How strongly the wallpaper's colors show through."
            below: true
            SettingsChips {
                options: [
                    { value: "auto", label: "Auto" },
                    { value: "tonal-spot", label: "Tonal" },
                    { value: "content", label: "Vivid" },
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
            icon: "format_color_fill"
            title: "Current palette"
            description: "Changes live with the wallpaper."
            Row {
                spacing: -6
                Repeater {
                    model: [Theme.base, Theme.surface, Theme.overlay, Theme.accent, Theme.red, Theme.yellow, Theme.green, Theme.text]
                    Rectangle {
                        required property color modelData
                        width: 28
                        height: 28
                        radius: Theme.round(14, width, height)
                        color: modelData
                        border.width: 2
                        border.color: Theme.base
                        Behavior on color { ColorAnimation { duration: Theme.ms(400) } }
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
        title: "Transparency"

        SettingsRow {
            icon: "opacity"
            title: "Bar and panels"
            description: "Background opacity of the bar pill and drop-down panels."
            SettingsSlider {
                value: Math.round(Settings.appearance.panelOpacity * 100)
                suffix: "%"
                from: 40
                to: 100
                stepSize: 5
                onMoved: v => Settings.appearance.panelOpacity = v / 100
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
