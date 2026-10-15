import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Control center music tab for the active player (Media.qml), minimal and Material 3 flavored,
// top to bottom: the cover in a slowly turning scalloped shape with the spectrum (Cava) radiating
// around it; title, artist and album; a wavy seek bar; round tonal buttons around a wide play button
// that squares off while playing. At the bottom: the players (when there are several), "open app"
// and volume.
Item {
    id: root
    // Set by ControlCenter while this tab is on screen
    property bool shown: false
    signal closeRequested()

    readonly property var player: Media.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool hasLength: (player?.lengthSupported ?? false) && (player?.length ?? 0) > 0

    implicitHeight: 460

    // MPRIS doesn't push position updates; poll while the tab shows a playing track
    Timer {
        interval: 1000
        repeat: true
        running: root.shown && root.playing
        onTriggered: root.player.positionChanged()
    }

    // Nothing playing
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.player === null
        spacing: 6

        MediaCover {
            Layout.alignment: Qt.AlignHCenter
            coverSize: 120
            implicitWidth: 140
            icon: "queue_music"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            text: "Nothing playing"
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Play something and it shows up here"
            color: Theme.subtext
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        visible: root.player !== null
        spacing: 12

        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            // Lets this column take the full width (a layout is otherwise only as wide as its
            // children allow), so the items below center in it
            Item { Layout.fillWidth: true }

            MediaCover {
                id: cover
                Layout.alignment: Qt.AlignHCenter
                // Shrinks on short screens so the controls stay in view
                coverSize: Math.max(130, Math.min(220, root.height - 400))
                art: root.player?.trackArtUrl ?? ""
                playing: root.playing && root.shown
            }

            // Track info, seek bar and controls, centered and kept to a comfortable width
            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 440
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || "Unknown title"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: root.player?.trackArtist || "Unknown artist"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize + 2
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.player?.trackAlbum ?? ""
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.accent
                    font.pixelSize: Theme.fontSize + 1
                    elide: Text.ElideRight
                }

                // Seek bar between the elapsed and total times (fixed widths, so it doesn't jiggle)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    spacing: 10
                    visible: root.hasLength

                    Label {
                        Layout.preferredWidth: timeWidth.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Media.time(root.player?.position ?? 0)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                        font.features: { "tnum": 1 }
                    }
                    WavySlider {
                        Layout.fillWidth: true
                        value: root.hasLength ? Math.min(1, root.player.position / root.player.length) : 0
                        playing: root.playing && root.shown
                        enabled: root.player?.canSeek ?? false
                        onMoved: v => root.player.position = v * root.player.length
                    }
                    Label {
                        Layout.preferredWidth: timeWidth.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Media.time(root.player?.length ?? 0)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                        font.features: { "tnum": 1 }
                    }
                    TextMetrics {
                        id: timeWidth
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                        text: Media.time(root.player?.length ?? 0).replace(/[0-9]/g, "0")
                    }
                }

                // Controls
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: root.hasLength ? 14 : 24
                    spacing: 6

                    MusicButton {
                        icon: "shuffle"
                        size: 42
                        enabled: root.player?.shuffleSupported ?? false
                        checked: root.player?.shuffle ?? false
                        onClicked: root.player.shuffle = !root.player.shuffle
                    }
                    MusicButton {
                        glyph: "previous"
                        size: 52
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player.previous()
                    }
                    MusicButton {
                        Layout.fillWidth: true
                        glyph: root.playing ? "pause" : "play"
                        size: 52
                        glyphSize: 22
                        filled: true
                        checked: root.playing
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player.togglePlaying()
                    }
                    MusicButton {
                        glyph: "next"
                        size: 52
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player.next()
                    }
                    MusicButton {
                        icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                        size: 42
                        enabled: root.player?.loopSupported ?? false
                        checked: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                        // None → Playlist → Track → None
                        onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                            : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track
                            : MprisLoopState.None
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Players, "open app" and the player's volume
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: Media.players.length > 1 ? Media.players : []

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool current: modelData === root.player

                    implicitWidth: chipRow.implicitWidth + 20
                    implicitHeight: 32
                    radius: current ? 10 : height / 2
                    color: current ? Theme.accent : chipMouse.containsMouse ? Qt.alpha(Theme.accent, 0.22) : Qt.alpha(Theme.accent, 0.1)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on radius { NumberAnimation { duration: 200 } }

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6

                        IconImage {
                            implicitSize: 16
                            source: Media.iconFor(chip.modelData)
                        }
                        Label {
                            Layout.maximumWidth: 120
                            text: chip.modelData.identity
                            font.pixelSize: Theme.fontSize - 1
                            color: chip.current ? Theme.accentText : Theme.text
                            elide: Text.ElideRight
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

            // Only one player: just its name
            RowLayout {
                visible: Media.players.length === 1
                spacing: 6
                IconImage {
                    implicitSize: 16
                    source: root.player ? Media.iconFor(root.player) : ""
                }
                Label {
                    text: root.player?.identity ?? ""
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            MusicButton {
                visible: root.player?.canRaise ?? false
                icon: "open_in_new"
                size: 32
                onClicked: {
                    root.closeRequested();
                    root.player.raise();
                }
            }

            Item { Layout.fillWidth: true }

            // Player volume, when the app exposes it
            RowLayout {
                visible: (root.player?.volumeSupported ?? false) && (root.player?.canControl ?? false)
                spacing: 8

                Icon {
                    name: (root.player?.volume ?? 0) < 0.01 ? "volume_off" : "volume_up"
                    color: Theme.subtext
                    size: 18
                }
                Slider {
                    Layout.preferredWidth: 130
                    value: root.player?.volume ?? 0
                    onMoved: v => root.player.volume = v
                }
            }
        }
    }
}
