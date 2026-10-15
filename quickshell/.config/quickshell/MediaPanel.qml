import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes

// Control center music tab for the active player (Media.qml): the album art blurred as the
// backdrop, a large cover, track info, a live spectrum (Cava, while playing),
// seek bar, controls, player volume and a switcher when several apps are playing media.
Item {
    id: root
    // Set by ControlCenter while this tab is on screen
    property bool shown: false
    signal closeRequested()

    readonly property var player: Media.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string art: player?.trackArtUrl ?? ""

    implicitHeight: players.height + content.implicitHeight + 60

    // MPRIS doesn't push position updates; poll while the tab shows a playing track
    Timer {
        interval: 1000
        repeat: true
        running: root.shown && root.playing
        onTriggered: root.player.positionChanged()
    }

    // Backdrop: the cover, heavily blurred, fading into the window color
    Item {
        anchors.fill: parent

        Image {
            id: backdrop
            anchors.fill: parent
            source: root.art
            sourceSize.width: 128
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: backdrop
            visible: backdrop.status === Image.Ready
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.25
            opacity: 0.55
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        // Accent glow when there's no cover
        Rectangle {
            anchors.fill: parent
            visible: backdrop.status !== Image.Ready
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0.18) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(Theme.base, 0.15) }
                GradientStop { position: 0.55; color: Qt.alpha(Theme.base, 0.45) }
                GradientStop { position: 1; color: Qt.alpha(Theme.base, 0.85) }
            }
        }
    }

    // Player switcher and "open app"
    RowLayout {
        id: players
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 6

        Repeater {
            model: Media.players

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool current: modelData === root.player

                implicitWidth: chipRow.implicitWidth + 18
                implicitHeight: 30
                radius: height / 2
                color: current ? Qt.alpha(Theme.accent, 0.22) : chipMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : Qt.alpha(Theme.surface, 0.4)
                border.width: current ? 1 : 0
                border.color: Qt.alpha(Theme.accent, 0.6)
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 6

                    IconImage {
                        implicitSize: 16
                        source: Media.iconFor(chip.modelData)
                    }
                    Label {
                        text: chip.modelData.identity
                        font.pixelSize: Theme.fontSize - 1
                        color: chip.current ? Theme.text : Theme.subtext
                    }
                    Icon {
                        visible: chip.modelData.isPlaying
                        name: "graphic_eq"
                        color: Theme.accent
                        size: 16
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.chosen = chip.modelData
                }
            }
        }

        Item { Layout.fillWidth: true }

        Pill {
            visible: root.player?.canRaise ?? false
            icon: "open_in_new"
            implicitHeight: 30
            onClicked: {
                root.closeRequested();
                root.player.raise();
            }
        }
    }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; margins: 20 }
        y: players.y + players.height + Math.max(20, (root.height - players.y - players.height - implicitHeight) / 2 - 10)
        spacing: 18

        // Nothing playing
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.player === null
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 96
                implicitHeight: 96
                radius: 48
                color: Qt.alpha(Theme.surface, 0.6)

                Icon {
                    anchors.centerIn: parent
                    name: "music_off"
                    color: Theme.overlay
                    size: 44
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                text: "Nothing playing"
                font.pixelSize: Theme.fontSize + 4
                font.bold: true
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Play music in Spotify, a browser or any player"
                color: Theme.subtext
            }
        }

        // Cover and track info
        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            visible: root.player !== null

            Item {
                implicitWidth: 210
                implicitHeight: 210

                ClippingRectangle {
                    id: cover
                    anchors.fill: parent
                    radius: 20
                    color: Theme.surface
                    // Settles back a little while paused
                    scale: root.playing ? 1 : 0.94
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                    Icon {
                        anchors.centerIn: parent
                        visible: coverArt.status !== Image.Ready
                        name: "album"
                        color: Theme.overlay
                        size: 72
                    }

                    Image {
                        id: coverArt
                        anchors.fill: parent
                        source: root.art
                        sourceSize.width: 420
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#000000"
                        shadowOpacity: 0.45
                        shadowBlur: 1
                        shadowVerticalOffset: 8
                        autoPaddingEnabled: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Label {
                    text: root.playing ? "NOW PLAYING" : "PAUSED"
                    color: Theme.accent
                    font.bold: true
                    font.pixelSize: Theme.fontSize - 3
                    font.letterSpacing: 2
                }
                Label {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Unknown track"
                    font.pixelSize: Theme.fontSize + 9
                    font.bold: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.player?.trackArtist ?? ""
                    font.pixelSize: Theme.fontSize + 2
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.player?.trackAlbum ?? ""
                    color: Theme.subtext
                    elide: Text.ElideRight
                }

                // Spectrum, mirrored around a baseline so it reads like a waveform
                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    implicitHeight: 56

                    Row {
                        id: spectrum
                        anchors.fill: parent
                        spacing: 3
                        readonly property real barWidth: (width - spacing * (Cava.barCount - 1)) / Cava.barCount

                        Repeater {
                            model: Cava.barCount

                            Item {
                                required property int index
                                readonly property real level: Cava.levels[index] ?? 0

                                width: spectrum.barWidth
                                height: spectrum.height

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: Math.max(width, parent.level * parent.height)
                                    radius: width / 2
                                    color: Theme.accent
                                    opacity: 0.35 + 0.65 * parent.level
                                    Behavior on height { NumberAnimation { duration: 60 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Seek bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: (root.player?.lengthSupported ?? false) && root.player.length > 0

            Slider {
                Layout.fillWidth: true
                value: root.player ? root.player.position / root.player.length : 0
                dimmed: !(root.player?.canSeek ?? false)
                onMoved: v => { if (root.player?.canSeek) root.player.position = v * root.player.length; }
            }
            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: Media.time(root.player?.position ?? 0)
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
                Label {
                    text: "-" + Media.time((root.player?.length ?? 0) - (root.player?.position ?? 0))
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }

        // Controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 22
            visible: root.player !== null

            ControlButton {
                icon: "shuffle"
                visible: root.player?.shuffleSupported ?? false
                active: root.player?.shuffle ?? false
                onClicked: root.player.shuffle = !root.player.shuffle
            }
            ControlButton {
                skip: -1
                size: 32
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }

            // Play / pause
            Rectangle {
                implicitWidth: 68
                implicitHeight: 68
                radius: root.playing ? 22 : 34
                color: playMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                scale: playMouse.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }
                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                // Drawn rather than an icon: the filled Material Symbols glyph renders with seams
                Row {
                    anchors.centerIn: parent
                    visible: root.playing
                    spacing: 7

                    Repeater {
                        model: 2
                        Rectangle {
                            width: 7
                            height: 24
                            radius: 2.5
                            color: Theme.accentText
                        }
                    }
                }
                Shape {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 3
                    visible: !root.playing
                    width: 22
                    height: 26
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: Theme.accentText
                        strokeColor: Theme.accentText
                        strokeWidth: 4
                        joinStyle: ShapePath.RoundJoin
                        startX: 2; startY: 2
                        PathLine { x: 20; y: 13 }
                        PathLine { x: 2; y: 24 }
                        PathLine { x: 2; y: 2 }
                    }
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player?.canTogglePlaying) root.player.togglePlaying()
                }
            }

            ControlButton {
                skip: 1
                size: 32
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
            ControlButton {
                icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                visible: root.player?.loopSupported ?? false
                active: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                // None → Playlist → Track → None
                onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                    : MprisLoopState.None
            }
        }

        // Player volume, when the app exposes it
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 60
            Layout.rightMargin: 60
            spacing: 10
            visible: (root.player?.volumeSupported ?? false) && (root.player?.canControl ?? false)

            Icon {
                name: "volume_down"
                color: Theme.subtext
                size: 18
            }
            Slider {
                Layout.fillWidth: true
                value: root.player?.volume ?? 0
                onMoved: v => root.player.volume = v
            }
            Icon {
                name: "volume_up"
                color: Theme.subtext
                size: 18
            }
        }
    }

    component ControlButton: Rectangle {
        id: button
        property string icon
        property bool active: false
        property int size: 24
        // 1 or -1: draw a skip next/previous glyph (the filled icons render with seams)
        property int skip: 0
        signal clicked()

        implicitWidth: size + 18
        implicitHeight: size + 18
        radius: width / 2
        color: buttonMouse.containsMouse && enabled ? Qt.alpha(Theme.surface, 0.8) : "transparent"
        opacity: enabled ? 1 : 0.4
        Behavior on color { ColorAnimation { duration: 120 } }

        Icon {
            anchors.centerIn: parent
            visible: button.skip === 0
            name: button.icon
            filled: true
            color: button.active ? Theme.accent : Theme.text
            size: button.size
        }

        // Triangle and bar, mirrored for previous
        Shape {
            anchors.centerIn: parent
            visible: button.skip !== 0
            width: 18
            height: 18
            preferredRendererType: Shape.CurveRenderer
            transform: Scale { xScale: button.skip; origin.x: 9 }

            ShapePath {
                fillColor: Theme.text
                strokeColor: Theme.text
                strokeWidth: 3
                joinStyle: ShapePath.RoundJoin
                startX: 1.5; startY: 2
                PathLine { x: 12; y: 9 }
                PathLine { x: 1.5; y: 16 }
                PathLine { x: 1.5; y: 2 }
            }
            ShapePath {
                fillColor: Theme.text
                strokeColor: Theme.text
                strokeWidth: 3
                capStyle: ShapePath.RoundCap
                startX: 16.5; startY: 2
                PathLine { x: 16.5; y: 16 }
            }
        }

        // Dot under active toggles (shuffle, repeat)
        Rectangle {
            visible: button.active
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            width: 4
            height: 4
            radius: 2
            color: Theme.accent
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (button.enabled) button.clicked()
        }
    }
}
