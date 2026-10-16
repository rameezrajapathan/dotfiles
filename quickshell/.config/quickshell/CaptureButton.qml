import QtQuick
import QtQuick.Layouts

// Screenshots and screen recording in one icon. Click opens CapturePanel, right click takes a
// region screenshot straight away. While recording it becomes a red pill with the elapsed time
// that stops the recording on click.
Item {
    id: root
    signal clicked()

    implicitWidth: Recorder.active ? pill.implicitWidth : icon.implicitWidth
    implicitHeight: Recorder.active ? pill.implicitHeight : icon.implicitHeight

    Icon {
        id: icon
        anchors.centerIn: parent
        visible: !Recorder.active
        name: "screenshot_frame"
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        visible: Recorder.active
        implicitWidth: Theme.barVertical ? implicitHeight : row.implicitWidth + 16
        implicitHeight: 22
        radius: height / 2
        color: Qt.alpha(Theme.red, mouse.containsMouse ? 0.35 : 0.2)

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Theme.red

                SequentialAnimation on opacity {
                    running: Recorder.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 600 }
                    NumberAnimation { to: 1; duration: 600 }
                }
            }
            // Just the dot on a side bar
            Label {
                visible: !Theme.barVertical
                text: mouse.containsMouse ? "Stop" : Recorder.elapsedText
                color: Theme.red
                font.bold: true
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (Recorder.active)
                Recorder.stop();
            else if (mouse.button === Qt.RightButton)
                Capture.screenshot("region");
            else
                root.clicked();
        }
    }
}
