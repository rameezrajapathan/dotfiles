import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    required property var dock
    property string key: ""
    property string current: ""
    onKeyChanged: if (key) current = key

    readonly property bool vertical: dock.vertical
    readonly property var group: current ? Dock.groups.map[current] ?? null : null
    readonly property var windows: group?.windows ?? []
    readonly property var entry: current && current !== "launcher" ? Dock.entry(current) : null
    readonly property string title: current === "launcher" ? "Apps" : entry?.name ?? group?.appId ?? ""
    readonly property var p: dock.layout.pos[current] ?? null
    readonly property bool open: key !== "" && p !== null && dock.dragKey === "" && !dock.menuOpen

    readonly property real thumbBase: vertical ? 200 : 110
    readonly property var sizes: windows.map(t => {
        const s = t.lastIpcObject?.size;
        const a = s && s[1] > 0 ? s[0] / s[1] : 16 / 10;
        return vertical ? { w: thumbBase, h: Math.max(60, Math.min(150, thumbBase / a)) }
            : { w: Math.max(80, Math.min(220, thumbBase * a)), h: thumbBase };
    })
    readonly property real totalAlong: sizes.reduce((sum, s) => sum + (vertical ? s.h + 30 : s.w), 0) + Math.max(0, sizes.length - 1) * 10
    readonly property real fit: Math.min(1, (dock.length - 80) / Math.max(1, totalAlong))

    property real shownAmount: open ? 1 : 0
    Behavior on shownAmount { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
    visible: shownAmount > 0

    readonly property rect cardRect: Qt.rect(card.x, card.y, card.width, card.height)
    readonly property Item hit: hitItem

    Item {
        id: hitItem
        x: root.open ? card.x : 0
        y: root.open ? card.y : 0
        width: root.open ? card.width : 0
        height: root.open ? card.height : 0
    }

    readonly property real centerAlong: p ? p.along + p.size / 2 : 0

    Rectangle {
        id: card
        readonly property real fromEdge: Dock.gap + Math.max(root.dock.depth, (root.p?.size ?? 0) + 2 * Dock.pad) + 10
        readonly property real alongSize: root.vertical ? height : width
        readonly property real alongPos: Math.max(8, Math.min(root.dock.length - alongSize - 8, root.centerAlong - alongSize / 2))
        readonly property rect r: root.dock.rect(alongPos, alongSize, fromEdge - (1 - root.shownAmount) * 8, root.vertical ? width : height)
        x: r.x
        y: r.y
        implicitWidth: content.implicitWidth + 20
        implicitHeight: content.implicitHeight + 20
        width: implicitWidth
        height: implicitHeight
        opacity: root.shownAmount
        radius: Theme.round(16, width, height)
        color: "transparent"

        GlassPanel {
            radius: card.radius
            tint: Theme.denseTranslucent
            shadow: true
            tracking: root.shownAmount < 1
        }

        Column {
            id: content
            x: 10
            y: 10
            spacing: 8

            Label {
                text: root.title
                font.bold: root.windows.length > 0
                width: Math.min(implicitWidth, Math.max(160, thumbs.width))
                elide: Text.ElideRight
            }

            Grid {
                id: thumbs
                visible: root.windows.length > 0
                rows: root.vertical ? -1 : 1
                columns: root.vertical ? 1 : -1
                spacing: 10

                Repeater {
                    model: root.windows

                    Item {
                        id: thumb
                        required property var modelData
                        required property int index
                        readonly property var size: root.sizes[index] ?? { w: 160, h: 100 }
                        readonly property string special: Dock.specialName(modelData)
                        width: size.w * root.fit
                        height: size.h * root.fit + 22

                        ClippingRectangle {
                            id: shot
                            width: parent.width
                            height: parent.height - 22
                            radius: Theme.round(10, width, height)
                            color: Qt.alpha(Theme.base, 0.6)
                            border.width: thumbMouse.containsMouse || thumb.modelData.activated ? 2 : 0
                            border.color: thumbMouse.containsMouse ? Theme.selectedFill : Qt.alpha(Theme.text, 0.35)

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: root.open ? thumb.modelData.wayland : null
                                live: root.open
                            }

                            Rectangle {
                                visible: thumb.special !== ""
                                x: 6
                                y: parent.height - height - 6
                                width: specialLabel.implicitWidth + 12
                                height: 20
                                radius: 10
                                color: Theme.special

                                Label {
                                    id: specialLabel
                                    anchors.centerIn: parent
                                    text: Special.info(thumb.special).label
                                    color: Theme.specialText
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }
                        }

                        Label {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            text: thumb.modelData.title || root.title
                            color: thumbMouse.containsMouse ? Theme.text : Theme.subtext
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: thumbMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: event => {
                                if (event.button === Qt.MiddleButton) {
                                    Dock.closeWindow(thumb.modelData);
                                    return;
                                }
                                root.dock.closePreview();
                                Dock.focusWindow(thumb.modelData);
                            }
                        }

                        Rectangle {
                            visible: thumbMouse.containsMouse || closeMouse.containsMouse
                            width: 22
                            height: 22
                            radius: 11
                            x: shot.width - width - 6
                            y: 6
                            color: closeMouse.containsMouse ? Theme.red : Qt.alpha(Theme.base, 0.85)

                            Icon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 14
                                color: closeMouse.containsMouse ? Theme.base : Theme.text
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Dock.closeWindow(thumb.modelData)
                            }

                            Tooltip {
                                text: "Close window"
                            }
                        }
                    }
                }
            }
        }
    }
}
