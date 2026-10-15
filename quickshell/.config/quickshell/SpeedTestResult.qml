import QtQuick
import QtQuick.Layouts

// One value in the Network tab's speed test row: label, then the result; pulses while testing.
ColumnLayout {
    id: result
    property string label
    property string value
    property bool testing: false
    spacing: 0

    Label {
        text: result.label
        color: result.testing ? Theme.accent : Theme.subtext
        font.pixelSize: Theme.fontSize - 3
    }
    Label {
        Layout.minimumWidth: 70
        text: result.value !== "" ? result.value : result.testing ? "…" : "–"
        color: result.value !== "" ? Theme.text : Theme.overlay
        font.bold: result.value !== ""
        // Pulses while this part runs
        SequentialAnimation on opacity {
            running: result.testing
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.35; duration: 500 }
            NumberAnimation { to: 1; duration: 500 }
        }
    }
}
