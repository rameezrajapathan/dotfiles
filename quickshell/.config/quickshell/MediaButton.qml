import QtQuick
import QtQuick.Layouts

// Music note, plus the current track while something is loaded. Click opens MediaPanel,
// right click plays/pauses, scrolling skips tracks.
Item {
    id: root
    signal clicked()

    readonly property var player: Media.active
    readonly property string track: player ? [player.trackTitle, player.trackArtist].filter(s => s).join(" · ") : ""

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Icon {
            name: root.player?.isPlaying ? "graphic_eq" : "music_note"
            color: root.player?.isPlaying ? Theme.accent : Theme.text
        }

        Label {
            Layout.maximumWidth: 220
            visible: root.track !== ""
            text: root.track
            color: root.player?.isPlaying ? Theme.text : Theme.subtext
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.player?.canTogglePlaying)
                    root.player.togglePlaying();
            } else {
                root.clicked();
            }
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y < 0 && root.player?.canGoNext)
                root.player.next();
            else if (wheel.angleDelta.y > 0 && root.player?.canGoPrevious)
                root.player.previous();
        }
    }
}
