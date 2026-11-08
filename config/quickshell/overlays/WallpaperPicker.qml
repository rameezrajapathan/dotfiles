import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.services
import qs.widgets

OverlayWindow {
    id: root

    layerNamespace: "quickshell-wallpaper"
    backdropOpacity: 0
    hideWhenFaded: false

    property string current: ""

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

    function displayName(file) {
        return file.replace(/\.[^.]+$/, "").replace(/[-_.]+/g, " ").trim();
    }

    onOpening: {
        search.text = "";
        current = Wallpaper.path;
        Qt.callLater(showCurrent);
    }

    function showCurrent() {
        const i = shown.findIndex(w => w.path === current);
        if (i >= 0)
            list.positionViewAtIndex(list.currentIndex = i, ListView.Center);
    }

    function apply(path) {
        current = path;
        Wallpaper.apply(path);
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            root.toggle();
        }
    }

    FolderListModel {
        id: files
        folder: "file://" + Wallpaper.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
        showDirs: false
    }

    Sheet {
        id: strip
        open: root.open
        sheetWidth: Math.round(root.width * 0.7)
        sheetHeight: content.implicitHeight + 2 * Theme.pad(14, 24)
        onClosed: root.visible = false
        onDismiss: root.open = false

        MouseArea {
            anchors.fill: parent
            onWheel: wheel => list.flick(wheel.angleDelta.y * 8, 0)
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.pad(14, 24) }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    text: "Wallpapers"
                    font.bold: true
                }
                Rectangle {
                    implicitWidth: 260
                    implicitHeight: 30
                    radius: Theme.round(height / 2, width, height)
                    color: Theme.surface
                    border.width: 2
                    border.color: Theme.gradientAccent && (search.text !== "") ? "transparent" : search.text !== "" ? Qt.alpha(Theme.accent, 0.6) : "transparent"
                    GradientBorder {
                        active: search.text !== ""
                        strength: 0.6
                    }

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
                    GlassRim {}
                }
                Pill {
                    icon: "folder_open"
                    tip: "Open wallpaper folder"
                    onClicked: {
                        root.open = false;
                        Apps.files(Wallpaper.folder);
                    }
                }
            }

            Label {
                visible: files.count === 0
                text: "No images in " + Wallpaper.folder
                color: Theme.overlay
            }

            Label {
                visible: files.count > 0 && root.shown.length === 0
                Layout.preferredHeight: list.implicitHeight
                verticalAlignment: Text.AlignVCenter
                text: `No wallpaper matches "${search.text}"`
                color: Theme.overlay
            }

            Rectangle {
                id: fadeMask
                visible: false
                width: list.width
                height: list.height
                layer.enabled: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: list.atXBeginning ? "black" : "transparent" }
                    GradientStop { position: Math.min(0.5, 48 / Math.max(1, list.width)); color: "black" }
                    GradientStop { position: Math.max(0.5, 1 - 48 / Math.max(1, list.width)); color: "black" }
                    GradientStop { position: 1; color: list.atXEnd ? "black" : "transparent" }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: 206
                visible: count > 0
                orientation: ListView.Horizontal
                spacing: 10
                clip: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: fadeMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                keyNavigationWraps: true
                highlightMoveDuration: 150
                model: root.visible ? root.shown : []

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
                        radius: Theme.round(8, width, height)
                        color: Theme.surface
                        border.width: 3
                        border.color: Theme.gradientAccent && (cell.active) ? "transparent" : cell.active ? Theme.accent : cell.selected ? Theme.overlay : "transparent"
                        GradientBorder {
                            active: cell.active
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: Theme.pad(3, 8, parent.width, parent.height)
                            source: "file://" + cell.modelData.path
                            sourceSize.width: 400
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        GlassRim {}
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
