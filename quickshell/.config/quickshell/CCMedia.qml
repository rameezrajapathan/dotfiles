import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// Control center widget: what's playing, in the music page's style: the scalloped cover (turning
// while it plays), title and artist, the wavy seek bar and round buttons. Compact: the cover on
// the left, everything else beside it. Large: centered, the spectrum around the cover, shuffle
// and repeat too. Hidden while there's no player; a click on the cover or title opens the music page.
CCCard {
    id: root
    property var cc
    property bool large: false

    readonly property var player: Media.active
    readonly property bool wanted: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool shown: cc?.open ?? false
    readonly property bool hasLength: (player?.lengthSupported ?? false) && (player?.length ?? 0) > 0

    visible: wanted
    implicitHeight: (large ? largeLayout.implicitHeight : compactLayout.implicitHeight) + 2 * (large ? 18 : 14)

    // MPRIS only reports the position when asked
    Timer {
        interval: 1000
        repeat: true
        running: root.shown && root.playing
        onTriggered: root.player.positionChanged()
    }

    // ── Compact ──────────────────────────────────────────────────────────────────────────────
    RowLayout {
        id: compactLayout
        visible: !root.large
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 14 }
        spacing: 14

        MediaCover {
            coverSize: 64
            barRoom: 0
            art: root.player?.trackArtUrl ?? ""
            playing: root.playing && root.shown && !root.large

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cc.openDetail("music")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || "Unknown title"
                        color: Theme.text
                        font.family: Theme.displayFont
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Font.Bold
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cc.openDetail("music")
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.player?.trackArtist || root.player?.identity || ""
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                }

                MusicButton {
                    glyph: "previous"
                    size: 34
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }
                MusicButton {
                    glyph: root.playing ? "pause" : "play"
                    size: 40
                    glyphSize: 16
                    filled: true
                    checked: root.playing
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }
                MusicButton {
                    glyph: "next"
                    size: 34
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }

            WavySlider {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.hasLength
                value: root.hasLength ? Math.min(1, root.player.position / root.player.length) : 0
                playing: root.playing && root.shown
                enabled: root.player?.canSeek ?? false
                onMoved: v => root.player.position = v * root.player.length
            }
        }
    }

    // ── Large ────────────────────────────────────────────────────────────────────────────────
    ColumnLayout {
        id: largeLayout
        visible: root.large
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 2

        // Lets the column take the full width, so the cover centers in it
        Item { Layout.fillWidth: true }

        MediaCover {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -12
            Layout.bottomMargin: -10
            coverSize: 112
            barRoom: 56
            art: root.player?.trackArtUrl ?? ""
            playing: root.playing && root.shown && root.large

            MouseArea {
                anchors.centerIn: parent
                width: 112
                height: 112
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cc.openDetail("music")
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Unknown title"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: Theme.fontSize + 6
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
        Label {
            Layout.fillWidth: true
            text: root.player?.trackArtist || root.player?.identity || ""
            horizontalAlignment: Text.AlignHCenter
            color: Theme.subtext
            elide: Text.ElideRight
        }

        // Seek bar between the elapsed and total times
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            visible: root.hasLength
            spacing: 8

            Label {
                text: Media.time(root.player?.position ?? 0)
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 3
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
                text: Media.time(root.player?.length ?? 0)
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 3
                font.features: { "tnum": 1 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: root.hasLength ? 10 : 16
            spacing: 6

            MusicButton {
                icon: "shuffle"
                size: 36
                enabled: root.player?.shuffleSupported ?? false
                checked: root.player?.shuffle ?? false
                onClicked: root.player.shuffle = !root.player.shuffle
            }
            MusicButton {
                glyph: "previous"
                size: 44
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            MusicButton {
                Layout.fillWidth: true
                glyph: root.playing ? "pause" : "play"
                size: 44
                glyphSize: 18
                filled: true
                checked: root.playing
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
            MusicButton {
                glyph: "next"
                size: 44
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
            MusicButton {
                icon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                size: 36
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
