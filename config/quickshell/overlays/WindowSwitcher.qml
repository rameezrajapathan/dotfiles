import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

OverlayWindow {
    id: root

    layerNamespace: "quickshell-switcher"
    backdropOpacity: 0
    hideWhenFaded: false

    property int current: 0
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

    Timer {
        id: openTimer
        property int delta: 1
        interval: 60
        onTriggered: {
            root.items = Windows.windows;
            if (root.items.length < 2) {
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

    Timer {
        id: focusLater
        property var target: null
        interval: 50
        onTriggered: Windows.focus(target)
    }

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

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.close()
        Keys.onReturnPressed: root.commit()
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt)
                root.commit();
        }
    }

    Sheet {
        open: root.open
        anchorIds: ["workspaces"]
        sheetWidth: Math.min(root.width - Theme.barSpaceX - 80, row.implicitWidth + 2 * Theme.pad(16, 24))
        sheetHeight: row.implicitHeight + 2 * Theme.pad(16, 24)
        onClosed: root.visible = false
        onDismiss: root.close()

        ListView {
            id: row
            anchors.fill: parent
            anchors.margins: Theme.pad(16, 24)
            implicitWidth: contentWidth
            implicitHeight: 200
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            model: root.items
            currentIndex: root.current
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 160
            highlight: Rectangle {
                width: 260
                height: 200
                radius: Theme.round(16, width, height)
                color: Qt.alpha(Theme.accent, 0.22)
                border.width: 2
                border.color: Theme.gradientAccent ? "transparent" : Theme.accent
                GradientBorder {
                }
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
                radius: Theme.round(16, width, height)
                color: !selected && cardMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.pad(10, 16, parent.width, parent.height)
                    spacing: 8

                    ClippingRectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.round(10, width, height)
                        color: Theme.surface

                        ScreencopyView {
                            anchors.centerIn: parent
                            captureSource: root.visible ? card.modelData.wayland : null
                            live: card.selected
                            constraintSize: Qt.size(parent.width, parent.height)
                        }
                        GlassRim {}
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
