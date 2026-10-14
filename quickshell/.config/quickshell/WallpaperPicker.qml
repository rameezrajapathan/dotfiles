import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Layouts

// Strip of ~/Pictures/Wallpapers thumbnails that slides down from under the bar. Click or Enter
// applies one with hypr/scripts/theme.sh, which also recolors everything from it.
// Toggled with `qs ipc call wallpaper toggle`.
PanelWindow {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string config: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
    property string current: ""
    // Drives the slide; the window hides once the strip is back up
    property bool open: false

    function toggle() {
        if (!open) {
            reader.running = true;
            visible = true;
        }
        open = !open;
    }

    // Sets the wallpaper, saves it and recolors everything from it
    function apply(path) {
        current = path;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh", path]);
    }

    Process {
        id: reader
        command: ["sed", "-n", "s/^\\s*path\\s*=\\s*//p", root.config]
        stdout: StdioCollector {
            onStreamFinished: {
                root.current = text.trim().replace(/^~/, Quickshell.env("HOME"));
                const i = files.indexOf("file://" + root.current);
                if (i >= 0)
                    list.positionViewAtIndex(list.currentIndex = i, ListView.Center);
            }
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.toggle();
        }
    }

    FolderListModel {
        id: files
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    // Clips the strip so it appears to come out from under the bar
    Item {
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Theme.barHeight }
        height: strip.height
        clip: true

        Rectangle {
            id: strip
            x: 8
            width: parent.width - 16
            height: content.implicitHeight + 28
            y: root.open ? 0 : -height
            color: Theme.base
            bottomLeftRadius: 12
            bottomRightRadius: 12
            border.color: Theme.surface
            border.width: 2

            Behavior on y {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                    onRunningChanged: if (!running && !root.open) root.visible = false
                }
            }

            MouseArea {
                anchors.fill: parent
                onWheel: wheel => list.flick(wheel.angleDelta.y * 8, 0)
            }

            ColumnLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: "Wallpapers"
                        font.bold: true
                    }
                    Pill {
                        text: "open folder"
                        onClicked: {
                            root.open = false;
                            Quickshell.execDetached(["thunar", root.folder]);
                        }
                    }
                }

                Label {
                    visible: files.count === 0
                    text: "No images in " + root.folder
                    color: Theme.overlay
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: 180
                    visible: count > 0
                    orientation: ListView.Horizontal
                    spacing: 10
                    clip: true
                    focus: root.open
                    keyNavigationWraps: true
                    highlightMoveDuration: 150
                    model: files

                    Keys.onEscapePressed: root.open = false
                    Keys.onReturnPressed: root.apply(files.get(currentIndex, "filePath"))

                    delegate: Rectangle {
                        id: cell
                        required property string filePath
                        required property int index
                        readonly property bool active: filePath === root.current

                        width: height * 16 / 10
                        height: ListView.view.height
                        radius: 8
                        color: Theme.surface
                        border.width: 3
                        border.color: active ? Theme.accent
                            : list.currentIndex === index || mouse.containsMouse ? Theme.overlay
                            : "transparent"

                        Image {
                            anchors.fill: parent
                            anchors.margins: 3
                            source: "file://" + cell.filePath
                            sourceSize.width: 400
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = cell.index
                            onClicked: root.apply(cell.filePath)
                            onWheel: wheel => list.flick(wheel.angleDelta.y * 8, 0)
                        }
                    }
                }
            }
        }
    }
}
