import QtQuick
import QtQuick.Layouts
import qs.panels
import qs.services
import qs.widgets

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
        radius: Theme.round(height / 2, width, height)
        color: Qt.alpha(Theme.red, mouse.containsMouse ? 0.35 : 0.2)

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: Theme.round(4, width, height)
                color: Theme.red

                SequentialAnimation on opacity {
                    running: Recorder.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 600 }
                    NumberAnimation { to: 1; duration: 600 }
                }
            }
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

    Tooltip {
        text: Recorder.active ? "Stop recording" : "Capture screen · Right-click for a region screenshot"
        side: Theme.awayFromBar
    }
}
