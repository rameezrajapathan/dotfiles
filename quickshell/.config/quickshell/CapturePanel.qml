import Quickshell
import QtQuick
import QtQuick.Layouts

// Control center tab: screenshot a region, window or the screen (saved and copied),
// or record a region or the screen (record.sh; the bar shows a timer that stops it).
Item {
    id: root
    // Set by ControlCenter while this tab is on screen
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    function run(action) {
        root.closeRequested();
        action();
    }

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "Screenshot"
                    font.bold: true
                }
                Pill {
                    icon: "folder_open"
                    onClicked: root.run(() => Quickshell.execDetached(["sh", "-c", "xdg-open \"$(xdg-user-dir PICTURES)/Screenshots\""]))
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Tile { icon: "screenshot_region"; label: "Region"; onClicked: root.run(() => Capture.screenshot("region")) }
                Tile { icon: "web_asset"; label: "Window"; onClicked: root.run(() => Capture.screenshot("active")) }
                Tile { icon: "screenshot_monitor"; label: "Screen"; onClicked: root.run(() => Capture.screenshot("full")) }
                Tile { icon: "draw"; label: "Annotate"; onClicked: root.run(() => Capture.annotate()) }
                Tile { icon: "document_scanner"; label: "Text"; onClicked: root.run(() => Capture.copyText()) }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                Label {
                    Layout.fillWidth: true
                    text: "Record"
                    font.bold: true
                }
                Pill {
                    icon: "folder_open"
                    onClicked: root.run(() => Quickshell.execDetached(["sh", "-c", "xdg-open \"$(xdg-user-dir VIDEOS)/Recordings\""]))
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Tile { icon: "screen_record"; label: "Region"; onClicked: root.run(() => Recorder.record("region")) }
                Tile { icon: "desktop_windows"; label: "Screen"; onClicked: root.run(() => Recorder.record("full")) }
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "Recordings include desktop audio. Click the timer in the bar to stop."
                color: Theme.overlay
                font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.Wrap
            }
        }
    }

    component Tile: Rectangle {
        id: tile
        property string icon
        property string label
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 64
        radius: 12
        color: tileMouse.containsMouse ? Qt.alpha(Theme.accent, 0.25) : Qt.alpha(Theme.surface, 0.7)
        Behavior on color { ColorAnimation { duration: Theme.ms(100) } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: tile.icon
                filled: tileMouse.containsMouse
                color: tileMouse.containsMouse ? Theme.accent : Theme.text
                size: 24
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: tile.label
                font.pixelSize: Theme.fontSize - 1
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }
}
