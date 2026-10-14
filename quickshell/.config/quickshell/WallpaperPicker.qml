import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Layouts

// Strip of ~/Pictures/Wallpapers thumbnails with their names that slides down from under the bar.
// Typing filters by name, arrows move, click or Enter applies one with hypr/scripts/theme.sh, which
// also recolors everything from it.
// Toggled with `qs ipc call wallpaper toggle`.
PanelWindow {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string config: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
    property string current: ""
    // Drives the slide; the window hides once the strip is back up
    property bool open: false

    // Matching images as { path, name }: every word typed must appear in the name
    readonly property var shown: {
        const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
        const out = [];
        for (let i = 0; i < files.count; i++) {
            const name = displayName(files.get(i, "fileName"));
            const haystack = name.toLowerCase();
            if (words.every(w => haystack.includes(w)))
                out.push({ path: files.get(i, "filePath"), name: name });
        }
        return out;
    }

    // "orange-forest.jpg" → "orange forest"
    function displayName(file) {
        return file.replace(/\.[^.]+$/, "").replace(/[-_.]+/g, " ").trim();
    }

    function toggle() {
        if (!open) {
            search.text = "";
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
                const i = root.shown.findIndex(w => w.path === root.current);
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
                    // Search field; keeps the keyboard so typing always filters
                    Rectangle {
                        implicitWidth: 260
                        implicitHeight: 30
                        radius: height / 2
                        color: Theme.surface
                        border.width: 2
                        border.color: search.text !== "" ? Qt.alpha(Theme.accent, 0.6) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 6

                            Icon {
                                name: "search"
                                size: 18
                                color: Theme.overlay
                            }

                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: Theme.text
                                selectionColor: Theme.accent
                                selectedTextColor: Theme.accentText
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                                clip: true
                                focus: root.open
                                onTextChanged: list.currentIndex = 0

                                Keys.onEscapePressed: {
                                    if (text !== "")
                                        text = "";
                                    else
                                        root.open = false;
                                }
                                Keys.onReturnPressed: if (root.shown.length) root.apply(root.shown[list.currentIndex].path)
                                Keys.onEnterPressed: if (root.shown.length) root.apply(root.shown[list.currentIndex].path)
                                Keys.onLeftPressed: list.decrementCurrentIndex()
                                Keys.onRightPressed: list.incrementCurrentIndex()
                                Keys.onTabPressed: list.incrementCurrentIndex()
                                Keys.onBacktabPressed: list.decrementCurrentIndex()

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: search.text === ""
                                    text: "Search by name…"
                                    color: Theme.overlay
                                }
                            }
                        }
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

                Label {
                    visible: files.count > 0 && root.shown.length === 0
                    Layout.preferredHeight: list.implicitHeight
                    verticalAlignment: Text.AlignVCenter
                    text: `No wallpaper matches "${search.text}"`
                    color: Theme.overlay
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    implicitHeight: 206
                    visible: count > 0
                    orientation: ListView.Horizontal
                    spacing: 10
                    clip: true
                    keyNavigationWraps: true
                    highlightMoveDuration: 150
                    model: root.shown

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool active: modelData.path === root.current
                        readonly property bool selected: list.currentIndex === index || mouse.containsMouse

                        width: thumb.width
                        height: ListView.view.height

                        Rectangle {
                            id: thumb
                            width: height * 16 / 10
                            height: parent.height - 26
                            radius: 8
                            color: Theme.surface
                            border.width: 3
                            border.color: cell.active ? Theme.accent : cell.selected ? Theme.overlay : "transparent"

                            Image {
                                anchors.fill: parent
                                anchors.margins: 3
                                source: "file://" + cell.modelData.path
                                sourceSize.width: 400
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        Label {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: cell.modelData.name
                            color: cell.active ? Theme.accent : cell.selected ? Theme.text : Theme.subtext
                            font.bold: cell.active
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = cell.index
                            onClicked: root.apply(cell.modelData.path)
                            onWheel: wheel => list.flick(wheel.angleDelta.y * 8, 0)
                        }
                    }
                }
            }
        }
    }
}
