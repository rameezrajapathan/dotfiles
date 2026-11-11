import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root
    required property var modelData
    property bool raisedLayer: false

    screen: modelData
    readonly property string screenName: modelData?.name ?? ""
    readonly property var area: {
        Theme.barHeight; Theme.barPosition; Dock.enabled; Dock.mode; Dock.edge; Dock.depth; width; height;
        return Desktop.area(screenName);
    }
    readonly property var entries: Desktop.layout(screenName)
    readonly property bool menuHere: Desktop.menu !== null && Desktop.menu.screen === screenName
    readonly property bool catalogHere: Desktop.catalogScreen === screenName
    readonly property bool shortcutMenuHere: Shortcuts.menu !== null && Shortcuts.menu.screen === screenName
    readonly property bool shortcutSheetHere: Shortcuts.sheet !== null && Shortcuts.sheet.screen === screenName
    readonly property bool popupHere: menuHere || shortcutMenuHere || shortcutSheetHere
    readonly property bool widgetsShown: raisedLayer ? Desktop.raised : Desktop.enabled && !Desktop.raised
    readonly property bool focusedHere: Desktop.focusedScreen === screenName
    property Item dragged: null
    property Item editor: null
    property int keyboardStage: 0

    function wantKeyboard(item) {
        if (raisedLayer)
            return;
        editor = item;
        if (keyboardStage === 0) {
            keyboardStage = 1;
            stageTimer.restart();
        }
    }

    function releaseKeyboard() {
        keyboardStage = 0;
        editor = null;
    }

    onEditorChanged: if (!editor && keyboardStage !== 0) keyboardStage = 0

    Timer {
        id: stageTimer
        interval: 250
        onTriggered: {
            if (root.keyboardStage !== 1)
                return;
            if (root.editor?.activeFocus)
                root.keyboardStage = 2;
            else
                root.releaseKeyboard();
        }
    }

    Connections {
        target: root.editor
        function onActiveFocusChanged() {
            if (root.keyboardStage === 2 && !root.editor.activeFocus)
                root.releaseKeyboard();
        }
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: raisedLayer ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.namespace: raisedLayer ? "quickshell-desktop-raised" : "quickshell-desktop"
    WlrLayershell.keyboardFocus: !raisedLayer ? (keyboardStage === 1 ? WlrKeyboardFocus.Exclusive : keyboardStage === 2 ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
        : (Desktop.raised || popupHere) && (focusedHere || shortcutSheetHere) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: raisedLayer ? "transparent" : "black"
    visible: raisedLayer ? Desktop.enabled && !Shortcuts.picking && (Desktop.raised || popupHere || dim.opacity > 0 || shortcutSheet.visible || shortcutMenu.visible) : true

    Loader {
        anchors.fill: parent
        active: !root.raisedLayer
        sourceComponent: WallpaperImage {}
    }

    Rectangle {
        id: dim
        anchors.fill: parent
        color: Theme.base
        opacity: root.raisedLayer && Desktop.raised ? (Desktop.editing ? 0.42 : 0.32) : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: root.raisedLayer
        Keys.onEscapePressed: Desktop.dismiss()
    }

    MouseArea {
        anchors.fill: parent
        enabled: Desktop.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onPressed: keys.forceActiveFocus()
        onClicked: event => {
            if (Shortcuts.menu) {
                Shortcuts.menu = null;
                return;
            }
            if (event.button === Qt.RightButton) {
                if (Settings.desktop.menu || root.raisedLayer)
                    Desktop.openMenu(root.screenName, event.x, event.y);
                return;
            }
            if (Desktop.menu)
                Desktop.menu = null;
            else if (root.raisedLayer && !Desktop.editing)
                Desktop.showing = false;
            else if (root.raisedLayer && Desktop.catalogScreen)
                Desktop.catalogScreen = "";
        }
    }

    Repeater {
        model: root.raisedLayer && Desktop.editing ? root.area.cols * root.area.rows : 0
        Rectangle {
            required property int index
            x: root.area.x + (index % root.area.cols) * Desktop.cell + Desktop.gutter
            y: root.area.y + Math.floor(index / root.area.cols) * Desktop.cell + Desktop.gutter
            width: Desktop.cell - 2 * Desktop.gutter
            height: width
            radius: Theme.round(20, width, height)
            color: Qt.alpha(Theme.text, 0.035)
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.07)
        }
    }

    Rectangle {
        visible: root.dragged !== null
        x: root.area.x + (root.dragged?.targetCol ?? 0) * Desktop.cell + Desktop.gutter
        y: root.area.y + (root.dragged?.targetRow ?? 0) * Desktop.cell + Desktop.gutter
        width: root.dragged ? Desktop.pixels(root.dragged.ghostW, root.dragged.ghostH).w : 0
        height: root.dragged ? Desktop.pixels(root.dragged.ghostW, root.dragged.ghostH).h : 0
        radius: root.dragged?.radius ?? 0
        color: Qt.alpha(root.dragged?.targetFree ? Theme.accent : Theme.red, 0.18)
        border.width: 2
        border.color: Qt.alpha(root.dragged?.targetFree ? Theme.accent : Theme.red, 0.7)
    }

    Item {
        id: canvas
        anchors.fill: parent
        opacity: root.widgetsShown ? 1 : 0
        visible: opacity > 0
        scale: root.raisedLayer ? (root.widgetsShown ? 1 : 0.96) : 1
        Behavior on opacity { NumberAnimation { duration: Theme.ms(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutCubic } }

        Repeater {
            model: root.entries
            DesktopWidget {
                id: w
                required property var modelData
                entry: modelData
                screenName: root.screenName
                area: root.area
                live: root.widgetsShown
                editable: root.raisedLayer && Desktop.editing
                readonly property bool active: dragging || resizing
                onActiveChanged: root.dragged = active ? w : (root.dragged === w ? null : root.dragged)
            }
        }
    }

    ColumnLayout {
        visible: root.raisedLayer && Desktop.editing && root.entries.length === 0 && !root.catalogHere
        anchors.centerIn: parent
        spacing: 10
        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "widgets"
            size: 56
            color: Theme.text
            opacity: 0.8
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "No widgets on this screen yet"
            color: Theme.text
            font.pixelSize: Theme.fontSize + 4
            font.weight: Font.DemiBold
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Add one from the catalog, or start with a few favorites."
            color: Qt.alpha(Theme.text, 0.75)
        }
    }

    Rectangle {
        id: toolbar
        visible: root.raisedLayer && Desktop.editing
        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.barPosition === "top" ? Theme.barHeight + 16 : 16
        implicitWidth: toolRow.implicitWidth + 16
        implicitHeight: 52
        radius: height / 2
        color: Qt.alpha(Theme.base, 0.85)
        border.width: 1
        border.color: Qt.alpha(Theme.text, 0.1)
        GlassRim {}

        RowLayout {
            id: toolRow
            anchors.centerIn: parent
            spacing: 6

            IconButton {
                icon: "add"
                iconSize: 18
                text: "Add widget"
                onClicked: Desktop.openCatalog(root.screenName)
            }
            IconButton {
                visible: root.entries.length === 0
                iconSize: 18
                icon: "auto_awesome"
                text: "Starter widgets"
                onClicked: Desktop.addStarter(root.screenName)
            }
            IconButton {
                tone: "accent"
                iconSize: 18
                icon: "check"
                text: "Done"
                onClicked: Desktop.edit(false)
            }
        }
    }

    Label {
        visible: root.raisedLayer && Desktop.editing && root.entries.length > 0 && !root.catalogHere
        anchors { horizontalCenter: parent.horizontalCenter; top: toolbar.bottom; topMargin: 10 }
        text: "Drag to move  ·  drag the corner to resize  ·  Esc when you're done"
        color: Qt.alpha(Theme.text, 0.8)
        font.pixelSize: Theme.fontSize - 1
    }

    WidgetCatalog {
        open: root.raisedLayer && root.catalogHere
        screenName: root.screenName
    }

    DesktopMenu {
        open: root.raisedLayer && root.menuHere
        screenName: root.screenName
        at: root.menuHere ? Qt.point(Desktop.menu.x, Desktop.menu.y) : Qt.point(0, 0)
    }

    ShortcutMenu {
        id: shortcutMenu
        open: root.raisedLayer && root.shortcutMenuHere
    }

    ShortcutSheet {
        id: shortcutSheet
        open: root.raisedLayer && root.shortcutSheetHere
    }

    Label {
        visible: root.raisedLayer && Desktop.showing && !Desktop.editing && root.focusedHere
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 28 }
        text: root.entries.length ? "Click anywhere or press Esc to go back" : "No widgets yet. Right click to add some."
        color: Qt.alpha(Theme.text, 0.75)
        font.pixelSize: Theme.fontSize - 1
    }
}
