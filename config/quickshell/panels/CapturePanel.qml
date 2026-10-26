import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

Item {
    id: root
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
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(20, 24) }
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
                    tip: "Open screenshots folder"
                    onClicked: root.run(() => Quickshell.execDetached(["sh", "-c", "exec \"$1\" files \"$(xdg-user-dir PICTURES)/Screenshots\"", "sh", Apps.script]))
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Tile { icon: "screenshot_region"; label: "Region"; tip: "Save a region screenshot"; tipKeys: "Super + Shift + F"; onClicked: root.run(() => Capture.screenshot("region")) }
                Tile { icon: "web_asset"; label: "Window"; tip: "Save a window screenshot"; onClicked: root.run(() => Capture.screenshot("active")) }
                Tile { icon: "screenshot_monitor"; label: "Screen"; tip: "Save a full-screen screenshot"; onClicked: root.run(() => Capture.screenshot("full")) }
                Tile { icon: "draw"; label: "Annotate"; tip: "Annotate a region screenshot"; tipKeys: "Shift + Print"; onClicked: root.run(() => Capture.annotate()) }
                Tile { icon: "document_scanner"; label: "Text"; tip: "Copy the text in a region"; tipKeys: "Super + Shift + T"; onClicked: root.run(() => Capture.copyText()) }
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
                    tip: "Open recordings folder"
                    onClicked: root.run(() => Quickshell.execDetached(["sh", "-c", "exec \"$1\" files \"$(xdg-user-dir VIDEOS)/Recordings\"", "sh", Apps.script]))
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Tile { icon: "screen_record"; label: "Region"; tip: "Record a region"; tipKeys: "Super + Shift + R"; onClicked: root.run(() => Recorder.record("region")) }
                Tile { icon: "desktop_windows"; label: "Screen"; tip: "Record the full screen"; tipKeys: "Super + Alt + R"; onClicked: root.run(() => Recorder.record("full")) }
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
        property string tip
        property string tipKeys
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 64
        radius: Theme.round(12, width, height)
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

        Tooltip {
            text: tile.tip
            keys: tile.tipKeys
        }
    }
}
