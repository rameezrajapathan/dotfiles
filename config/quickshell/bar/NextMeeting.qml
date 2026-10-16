import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root

    visible: Meetings.next !== null
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            name: Meetings.next?.join ? "video_call" : "event"
            filled: Meetings.ongoing
            size: 18
            color: Meetings.ongoing ? Theme.red : Theme.accent
        }
        Label {
            visible: !Theme.barVertical
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
