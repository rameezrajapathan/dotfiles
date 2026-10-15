import QtQuick
import QtQuick.Layouts

// A Settings app page: big title and subtitle, then SettingsSections.
ColumnLayout {
    id: root
    property string title
    property string subtitle
    // True while the page is the one on screen
    property bool shown: false
    default property alias content: body.data

    spacing: 22

    ColumnLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 2
        spacing: 4

        Text {
            text: root.title
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 28
            font.weight: Font.Bold
        }
        Label {
            visible: root.subtitle !== ""
            Layout.fillWidth: true
            text: root.subtitle
            color: Theme.subtext
            wrapMode: Text.WordWrap
        }
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: 22
    }
}
