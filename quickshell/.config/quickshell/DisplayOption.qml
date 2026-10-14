import QtQuick
import QtQuick.Layouts

// DisplayPanel row: label on the left, wrapping pills on the right.
RowLayout {
    property alias label: optionLabel.text
    default property alias pills: flow.data
    Layout.fillWidth: true
    spacing: 10

    Label {
        id: optionLabel
        Layout.preferredWidth: 72
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: 2
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }
    Flow {
        id: flow
        Layout.fillWidth: true
        spacing: 6
    }
}
