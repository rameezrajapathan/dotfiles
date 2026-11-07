import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property var next: Meetings.next
    readonly property var today: {
        const end = new Date();
        end.setHours(23, 59, 59);
        return Meetings.meetings.filter(m => m.end > Meetings.now && m.start * 1000 <= end.getTime());
    }

    function when(m) {
        if (m.start <= Meetings.now)
            return "Now · until " + Qt.formatTime(new Date(m.end * 1000), Settings.bar.clock24 ? "HH:mm" : "h:mm AP");
        const mins = Math.round((m.start - Meetings.now) / 60);
        return mins < 60 ? "In " + mins + " min" : Qt.formatTime(new Date(m.start * 1000), Settings.bar.clock24 ? "HH:mm" : "h:mm AP");
    }

    ColumnLayout {
        visible: root.size !== "large"
        anchors { fill: parent; margins: 20 }
        spacing: 4

        RowLayout {
            spacing: 6
            Icon {
                name: "event"
                size: 18
                color: Theme.accent
                filled: true
            }
            Label {
                text: Meetings.ongoing ? "NOW" : "NEXT"
                color: Theme.accent
                font.pixelSize: Theme.fontSize - 2
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: 4
            text: root.next ? root.next.title : "No meetings soon"
            color: root.next ? Theme.text : Theme.overlay
            font.pixelSize: root.size === "small" ? Theme.fontSize + 3 : Theme.fontSize + 6
            font.weight: Font.Bold
            wrapMode: Text.WordWrap
            maximumLineCount: root.size === "small" ? 3 : 2
            elide: Text.ElideRight
        }
        Label {
            visible: root.next !== null
            text: root.next ? root.when(root.next) : ""
            color: Theme.subtext
        }
        Label {
            visible: root.next !== null && root.size === "medium" && (root.next?.location ?? "") !== ""
            Layout.fillWidth: true
            text: root.next?.location ?? ""
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }
        Item { Layout.fillHeight: true }
        Rectangle {
            visible: root.next !== null && (root.next?.join ?? "") !== ""
            Layout.fillWidth: root.size === "small"
            implicitWidth: joinRow.implicitWidth + 28
            implicitHeight: 36
            radius: height / 2
            color: joinMouse.containsMouse ? Qt.lighter(Theme.green, 1.08) : Theme.green
            Row {
                id: joinRow
                anchors.centerIn: parent
                spacing: 6
                Icon { name: "videocam"; size: 18; filled: true; color: Theme.base; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "Join"; color: Theme.base; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                id: joinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Meetings.join(root.next)
            }
        }
    }

    ColumnLayout {
        visible: root.size === "large"
        anchors { fill: parent; margins: 20 }
        spacing: 10

        Label {
            text: "Today"
            font.pixelSize: Theme.fontSize + 4
            font.weight: Font.Bold
        }
        Label {
            visible: root.today.length === 0
            text: Meetings.meetings.length === 0 && !Meetings.next ? "No calendar set up yet" : "Nothing else today"
            color: Theme.overlay
        }
        Repeater {
            model: root.today.slice(0, 6)
            Rectangle {
                id: row
                required property var modelData
                readonly property bool now: modelData.start <= Meetings.now
                Layout.fillWidth: true
                implicitHeight: 58
                radius: Theme.round(14, width, height)
                color: now ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(Theme.surface, 0.45)
                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                    spacing: 10
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            Layout.fillWidth: true
                            text: row.modelData.title
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            text: root.when(row.modelData)
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                    Rectangle {
                        visible: (row.modelData.join ?? "") !== ""
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
                        color: Theme.green
                        Icon { anchors.centerIn: parent; name: "videocam"; size: 18; filled: true; color: Theme.base }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Meetings.join(row.modelData)
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
