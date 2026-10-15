import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar's music button: album art, track info, seek bar and controls for the
// active player (Media.qml), with a switcher when several apps are playing media.
// A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar
    // Left edge of the panel, lined up with the music button
    property real anchorX: 8

    readonly property var player: Media.active

    function toggle() {
        visible = !visible;
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-media"
    color: "transparent"
    visible: false

    // MPRIS doesn't push position updates; poll while the panel shows a playing track
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    ClippingRectangle {
        x: Math.min(root.anchorX, parent.width - width - 8)
        y: Theme.barHeight + 6
        width: 420
        height: content.implicitHeight + 32
        color: Theme.base
        radius: 16
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        // Album art, faint and stretched, as the backdrop
        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            opacity: 0.22
            asynchronous: true
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 14

            // Player switcher (or the single player's name)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: Media.players.length > 0

                Repeater {
                    model: Media.players

                    Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool current: modelData === root.player

                        implicitWidth: chipRow.implicitWidth + 16
                        implicitHeight: 28
                        radius: height / 2
                        color: current ? Qt.alpha(Theme.accent, 0.25) : chipMouse.containsMouse ? Theme.surface : "transparent"
                        border.width: current ? 1 : 0
                        border.color: Qt.alpha(Theme.accent, 0.6)

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
                    onClicked: {
                        root.visible = false;
                        root.player.raise();
                    }
                }
            }

            // Nothing playing
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                visible: root.player === null
                spacing: 8

                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    name: "music_off"
                    color: Theme.overlay
                    size: 44
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Nothing playing"
                    font.bold: true
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Play music in Spotify, a browser or any player"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                }
            }

            // Art and track info
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                visible: root.player !== null

                ClippingRectangle {
                    implicitWidth: 112
                    implicitHeight: 112
                    radius: 12
                    color: Theme.surface

                    Icon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        name: "album"
                        color: Theme.overlay
                        size: 48
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        sourceSize.width: 224
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || "Unknown track"
                        font.pixelSize: Theme.fontSize + 4
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.player?.trackArtist ?? ""
                        color: Theme.accent
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.player?.trackAlbum ?? ""
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                }
            }

            // Seek bar
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
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
                        text: Media.time(root.player?.length ?? 0)
                        color: Theme.subtext
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
            }

            // Controls
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                visible: root.player !== null

                ControlButton {
                    icon: "shuffle"
                    visible: root.player?.shuffleSupported ?? false
                    active: root.player?.shuffle ?? false
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
                ControlButton {
                    icon: "skip_previous"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                // Play / pause
                Rectangle {
                    implicitWidth: 56
                    implicitHeight: 56
                    radius: 28
                    color: playMouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent
                    scale: playMouse.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Icon {
                        anchors.centerIn: parent
                        name: root.player?.isPlaying ? "pause" : "play_arrow"
                        filled: true
                        color: Theme.accentText
                        size: 32
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
                    icon: "skip_next"
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
                spacing: 10
                visible: (root.player?.volumeSupported ?? false) && (root.player?.canControl ?? false)

                Icon {
                    name: "volume_up"
                    color: Theme.subtext
                    size: 18
                }
                Slider {
                    Layout.fillWidth: true
                    value: root.player?.volume ?? 0
                    onMoved: v => root.player.volume = v
                }
            }
        }
    }

    component ControlButton: Rectangle {
        id: button
        property string icon
        property bool active: false
        signal clicked()

        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: buttonMouse.containsMouse && enabled ? Theme.surface : "transparent"
        opacity: enabled ? 1 : 0.4

        Icon {
            anchors.centerIn: parent
            name: button.icon
            filled: true
            color: button.active ? Theme.accent : Theme.text
            size: 26
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
