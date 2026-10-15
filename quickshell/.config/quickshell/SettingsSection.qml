import QtQuick
import QtQuick.Layouts

// A titled group of settings rows on a rounded card (Settings app). Rows go inside; a thin line
// separates them.
ColumnLayout {
    id: root
    property string title
    property string subtitle
    default property alias rows: card.data

    Layout.fillWidth: true
    spacing: 8

    Label {
        visible: root.title !== ""
        Layout.leftMargin: 4
        text: root.title
        color: Theme.accent
        font.bold: true
        font.pixelSize: Theme.fontSize - 1
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
