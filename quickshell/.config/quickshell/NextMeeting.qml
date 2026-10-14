import QtQuick
import QtQuick.Layouts

// Next meeting beside the clock ("Standup in 10 min"); red while it's on. Click to join.
// Hidden without a calendar or meetings in the next 12 hours.
Item {
    id: root

    visible: Meetings.next !== null
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Icon {
            name: Meetings.next?.join ? "video_call" : "event"
            filled: Meetings.ongoing
            size: 18
            color: Meetings.ongoing ? Theme.red : Theme.accent
        }
        Label {
            Layout.maximumWidth: 240
            text: Meetings.label(Meetings.next)
            color: Meetings.ongoing ? Theme.red : Theme.text
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Meetings.join(Meetings.next)
    }
}
