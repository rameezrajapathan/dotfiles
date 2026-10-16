import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

ColumnLayout {
    id: root
    property string title
    property string subtitle
    property bool canReset: false
    default property alias rows: card.data
    signal reset()

    Layout.fillWidth: true
    spacing: 8

    RowLayout {
        visible: root.title !== ""
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4

        Label {
            Layout.fillWidth: true
            text: root.title
            color: Theme.accent
            font.bold: true
            font.pixelSize: Theme.fontSize - 1
        }
        Rectangle {
            visible: root.canReset
            implicitWidth: resetRow.implicitWidth + 16
            implicitHeight: 24
            radius: 12
            color: resetMouse.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.accent, 0.12)

            Row {
                id: resetRow
                anchors.centerIn: parent
                spacing: 4
                Icon { name: "restart_alt"; size: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "Reset"; color: Theme.accent; font.pixelSize: Theme.fontSize - 2; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                id: resetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.reset()
            }
        }
    }
    Label {
        visible: root.subtitle !== ""
        Layout.leftMargin: 4
        Layout.fillWidth: true
        Layout.topMargin: -4
        text: root.subtitle
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
        wrapMode: Text.WordWrap
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight
        radius: 16
        color: Qt.alpha(Theme.surface, 0.45)

        ColumnLayout {
            id: card
            anchors { left: parent.left; right: parent.right }
            spacing: 0
        }
    }
}
