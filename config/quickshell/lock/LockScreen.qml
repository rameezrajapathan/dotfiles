import Quickshell.Widgets
import QtQuick
import qs.bar
import qs.panels
import qs.services
import qs.widgets

LockSurface {
    id: root

    required property var lock
    property string screenName: ""
    readonly property var player: Media.active

    theme: Theme
    auth: lock
    leaving: lock.unlocking
    wallpaper: Wallpaper.url
    blur: Settings.lock.blur
    restSeconds: Settings.lock.restSeconds
    use24h: TimeDate.use24h
    glassActive: Glass.active
    userName: User.displayName
    face: User.avatar
    hostName: User.hostName
    showPower: Settings.lock.showPower

    networkIcon: StatusInfo.icon("network")
    networkConnected: StatusInfo.netDevice !== null
    hasBattery: StatusInfo.battery.isLaptopBattery
    batteryIcon: StatusInfo.icon("battery")
    batteryPercent: StatusInfo.batteryPercent
    charging: StatusInfo.charging

    rim: Component { GlassRim {} }
    divider: Component {
        GlassDivider {
            width: Glass.active ? 2 : 1
            height: 14
            vertical: true
            strength: 0.33
        }
    }
    accentBorder: Component {
        GradientBorder {
            radius: parent?.parent?.radius ?? 0
            strength: 0.55
        }
    }
    backdrop: Component {
        GlassPanel {
            id: statusGlass
            readonly property Item host: parent?.parent ?? null
            radius: host?.radius ?? 0
            tint: Qt.alpha(Theme.base, 0.55)
            backdropItem: root
            backdropSource: Wallpaper.url
            fill: false
            Connections {
                target: statusGlass.host
                function onYChanged() { statusGlass.updateMap(); }
            }
        }
    }

    belowClock: [
        Rectangle {
            id: mediaCard
            anchors.horizontalCenter: parent.horizontalCenter
            width: 380
            height: 96
            radius: Theme.round(24, width, height)
            color: "transparent"
            border.width: Glass.active ? 0 : 1
            border.color: Qt.alpha(Theme.text, 0.08)
            onYChanged: mediaGlass.updateMap()

            GlassPanel {
                id: mediaGlass
                radius: mediaCard.radius
                tint: Qt.alpha(Theme.base, 0.5)
                backdropItem: root
                backdropSource: Wallpaper.url
                fill: false
            }
            opacity: root.player ? 1 : 0
            visible: root.player !== null && Settings.lock.showMedia
            Behavior on opacity { NumberAnimation { duration: Theme.ms(300) } }

            ClippingRectangle {
                id: cover
                anchors.left: parent.left
                anchors.leftMargin: Theme.pad(14, 24, parent.width, parent.height)
                anchors.verticalCenter: parent.verticalCenter
                width: 68
                height: 68
                radius: Theme.round(16, width, height)
                color: Theme.surface

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(136, 136)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    name: "music_note"
                    size: 28
                    color: Theme.subtext
                }
                GlassRim {}
            }

            Column {
                anchors.left: cover.right
                anchors.leftMargin: Theme.pad(14, 24, parent.width, parent.height)
                anchors.right: controls.left
                anchors.rightMargin: Theme.pad(8, 24, parent.width, parent.height)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: root.player?.trackTitle || "Unknown track"
                    color: Theme.text
                    elide: Text.ElideRight
                    font.family: Theme.displayFont
                    font.weight: Font.DemiBold
                    font.pixelSize: 15
                }
                Text {
                    width: parent.width
                    text: root.player?.trackArtist || root.player?.identity || ""
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font.family: Theme.displayFont
                    font.pixelSize: 13
                }
                MusicBars {
                    width: 54
                    height: 16
                    count: 9
                    visible: root.player?.isPlaying ?? false
                }
            }

            Row {
                id: controls
                anchors.right: parent.right
                anchors.rightMargin: Theme.pad(12, 24, parent.width, parent.height)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: ["previous", "toggle", "next"]

                    Rectangle {
                        required property string modelData
                        readonly property bool main: modelData === "toggle"
                        width: main ? 44 : 34
                        height: width
                        radius: Theme.round(width / 2, width, height)
                        anchors.verticalCenter: parent.verticalCenter
                        color: main ? Theme.selectedFill : controlMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                        scale: controlMouse.pressed ? 0.9 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.ms(100) } }

                        MediaGlyph {
                            anchors.centerIn: parent
                            size: parent.main ? 16 : 13
                            kind: parent.main ? (root.player?.isPlaying ? "pause" : "play") : parent.modelData
                            color: parent.main ? Theme.selectedText : Theme.text
                        }

                        MouseArea {
                            id: controlMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const p = root.player;
                                if (!p)
                                    return;
                                if (parent.modelData === "previous" && p.canGoPrevious) p.previous();
                                else if (parent.modelData === "next" && p.canGoNext) p.next();
                                else if (parent.main && p.canTogglePlaying) p.togglePlaying();
                            }
                        }
                        GlassRim {}
                    }
                }
            }
            GlassRim {}
        }
    ]
}
