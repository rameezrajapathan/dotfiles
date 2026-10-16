import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    readonly property var player: Media.active
    signal clicked()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            name: root.player?.isPlaying ? "pause" : "play_arrow"
            filled: true
            size: 18
            color: Theme.accent
        }
        Label {
            visible: !Theme.barVertical
            Layout.maximumWidth: 200
            text: [root.player?.trackTitle, root.player?.trackArtist].filter(s => s).join(" · ")
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.player?.togglePlaying();
            else
                root.clicked();
        }
        onWheel: wheel => wheel.angleDelta.y < 0 ? root.player?.next() : root.player?.previous()
    }
}
