import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Alt + Tab: a row of live window previews, most recent first, coming out of the bar's pill.
// Holding Alt, Tab / Shift + Tab move; releasing Alt focuses the selection (Hyprland reports the
// release, so quick taps work). Esc cancels. Driven by `qs ipc call switcher
// next|prev|commit|cancel` from keybinds.lua.
PanelWindow {
    id: root

    // Closes the other panels when this one opens, and the other way round
    Exclusive { panel: root }

    property bool open: false
    property int current: 0
    // Snapshot taken when opened, so the order doesn't shift while switching
    property var items: []

    function step(delta) {
        if (!open) {
            Windows.refresh();
            openTimer.delta = delta;
            openTimer.restart();
            return;
        }
        if (items.length > 0)
            current = (current + delta + items.length) % items.length;
    }

    // Toplevel data refreshes asynchronously; open a moment later with the new order
    Timer {
        id: openTimer
        property int delta: 1
        interval: 60
        onTriggered: {
            root.items = Windows.windows;
            if (root.items.length < 2) {
                // Nothing to switch to
                if (root.items.length === 1)
                    Windows.focus(root.items[0]);
                return;
            }
            root.current = delta > 0 ? 1 : root.items.length - 1;
            root.visible = true;
            root.open = true;
        }
    }

    function commit() {
        if (!open)
            return;
        focusLater.target = items[current] ?? null;
        close();
        if (focusLater.target)
            focusLater.restart();
    }

    // Hyprland ignores focus changes while this window holds the keyboard (exclusive while open),
    // and it stays mapped while it slides back into the pill; focus once the keyboard is released
    Timer {
        id: focusLater
        property var target: null
        interval: 50
        onTriggered: Windows.focus(target)
    }

    // Slides back into the pill; the window hides when that ends
    function close() {
        open = false;
    }

    IpcHandler {
        target: "switcher"
        function next(): void {
            root.step(1);
        }
        function prev(): void {
            root.step(-1);
        }
        function commit(): void {
            root.commit();
        }
        function cancel(): void {
            root.close();
        }
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-switcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.close()
        Keys.onReturnPressed: root.commit()
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onReleased: event => {
            // Backup for the Hyprland release bind
            if (event.key === Qt.Key_Alt)
                root.commit();
        }
    }

    // Comes out of the bar's pill, like the launcher
    Sheet {
        open: root.open
        anchorIds: ["workspaces"]
        sheetWidth: Math.min(root.width - 80, row.implicitWidth + 32)
        sheetHeight: row.implicitHeight + 32
        onClosed: root.visible = false
        onDismiss: root.close()

        ListView {
            id: row
            anchors.fill: parent
            anchors.margins: 16
            implicitWidth: contentWidth
            implicitHeight: 200
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            model: root.items
            currentIndex: root.current
            // One highlight that glides to the selection
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 160
            highlight: Rectangle {
                width: 260
                height: 200
                radius: 16
                color: Qt.alpha(Theme.accent, 0.22)
                border.width: 2
                border.color: Theme.accent
            }
            preferredHighlightBegin: width / 2 - 130
            preferredHighlightEnd: width / 2 + 130
            highlightRangeMode: ListView.ApplyRange

            delegate: Rectangle {
                id: card
                required property var modelData
                required property int index
                readonly property bool selected: index === root.current

                width: 260
                height: 200
                radius: 16
                color: !selected && cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: Theme.surface

                        // Sized by constraintSize, keeping the window's aspect ratio
                        ScreencopyView {
                            anchors.centerIn: parent
                            captureSource: root.visible ? card.modelData.wayland : null
                            live: card.selected
                            constraintSize: Qt.size(parent.width, parent.height)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        IconImage {
                            implicitSize: 20
                            source: Windows.icon(card.modelData)
                        }
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.title
                            color: card.selected ? Theme.text : Theme.subtext
                            font.bold: card.selected
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = card.index
                    onClicked: {
                        root.current = card.index;
                        root.commit();
                    }
                }
            }
        }
    }
}
