import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar: one card per monitor with on/off, resolution, refresh rate, scale and,
// with two or more screens, where it sits next to the other one (or mirrors it). Changes apply at
// once and are remembered (Displays.qml); "reset" goes back to hypr/monitors.lua. A transparent
// full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    function toggle() {
        visible = !visible;
    }

    // Logical size (what positions are measured in)
    function size(m) {
        const sideways = m.transform % 2 === 1;
        return {
            w: Math.round((sideways ? m.height : m.width) / m.scale),
            h: Math.round((sideways ? m.width : m.height) / m.scale)
        };
    }

    function placement(m, other) {
        if (m.mirrorOf !== "none")
            return "mirror";
        const a = size(m), b = size(other);
        if (m.x + a.w <= other.x)
            return "left";
        if (m.x >= other.x + b.w)
            return "right";
        if (m.y + a.h <= other.y)
            return "above";
        if (m.y >= other.y + b.h)
            return "below";
        return "";
    }

    // Put m next to other; keep coordinates non-negative by moving other instead when needed
    function place(m, other, where) {
        if (where === "mirror") {
            Displays.set(m, { mirror: other.name });
            return;
        }
        const a = size(m), b = size(other);
        let x = other.x, y = other.y;
        if (where === "left")
            x -= a.w;
        else if (where === "right")
            x += b.w;
        else if (where === "above")
            y -= a.h;
        else
            y += b.h;
        const dx = Math.max(0, -x), dy = Math.max(0, -y);
        if (dx || dy)
            Displays.set(other, { position: `${other.x + dx}x${other.y + dy}` });
        Displays.set(m, { position: `${x + dx}x${y + dy}`, mirror: undefined });
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-displays"
    color: "transparent"
    visible: false

    onVisibleChanged: {
        if (visible)
            Displays.refresh();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 420
        height: content.implicitHeight + 28
        color: Theme.baseTranslucent
        radius: 10
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            Label {
                text: "Displays"
                font.bold: true
            }

            Repeater {
                model: Displays.monitors

                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var m: modelData
                    readonly property var rule: Displays.current(m)
                    readonly property string resolution: m.disabled ? "" : `${m.width}x${m.height}`
                    readonly property var other: Displays.enabled.find(o => o.name !== m.name) ?? null
                    readonly property bool lastOn: !m.disabled && Displays.enabled.length === 1

                    Layout.fillWidth: true
                    implicitHeight: cardContent.implicitHeight + 20
                    radius: 8
                    color: Qt.alpha(Theme.surface, 0.5)

                    ColumnLayout {
                        id: cardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Icon {
                                name: Displays.isLaptop(card.m) ? "computer" : "monitor"
                                filled: !card.m.disabled
                                color: card.m.disabled ? Theme.overlay : Theme.accent
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Label {
                                    Layout.fillWidth: true
                                    text: Displays.isLaptop(card.m) ? "Built-in display" : `${card.m.make} ${card.m.model}`.trim() || card.m.name
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: card.m.disabled ? `${card.m.name} · off`
                                        : `${card.m.name} · ${card.resolution} @ ${Math.round(card.m.refreshRate)} Hz · ×${+card.m.scale.toFixed(2)}`
                                    color: Theme.subtext
                                    font.pixelSize: Theme.fontSize - 2
                                    elide: Text.ElideRight
                                }
                            }
                            Pill {
                                visible: Displays.saved[card.m.description] !== undefined
                                icon: "restart_alt"
                                onClicked: Displays.reset(card.m)
                            }
                            Switch {
                                // Never turn off the last screen
                                visible: !card.lastOn
                                checked: !card.m.disabled
                                onToggled: Displays.set(card.m, card.m.disabled ? { disabled: undefined } : { disabled: true })
                            }
                        }

                        DisplayOption {
                            visible: !card.m.disabled
                            label: "Resolution"
                            Repeater {
                                model: card.m.disabled ? [] : Displays.resolutions(card.m)
                                Pill {
                                    required property string modelData
                                    text: modelData
                                    active: modelData === card.resolution
                                    onClicked: Displays.set(card.m, { mode: Displays.rates(card.m, modelData)[0] })
                                }
                            }
                        }

                        DisplayOption {
                            visible: !card.m.disabled
                            label: "Refresh"
                            Repeater {
                                model: card.m.disabled ? [] : Displays.rates(card.m, card.resolution)
                                Pill {
                                    required property string modelData
                                    readonly property real hz: parseFloat(modelData.split("@")[1])
                                    text: Math.round(hz) + " Hz"
                                    active: Math.abs(hz - card.m.refreshRate) < 0.5
                                    onClicked: Displays.set(card.m, { mode: modelData })
                                }
                            }
                        }

                        DisplayOption {
                            visible: !card.m.disabled
                            label: "Scale"
                            Repeater {
                                model: Displays.scales
                                Pill {
                                    required property real modelData
                                    text: modelData + "×"
                                    active: Math.abs(modelData - card.m.scale) < 0.01
                                    onClicked: Displays.set(card.m, { scale: modelData })
                                }
                            }
                        }

                        DisplayOption {
                            visible: !card.m.disabled && card.other !== null
                            label: "Position"
                            Repeater {
                                model: ["left", "right", "above", "below", "mirror"]
                                Pill {
                                    required property string modelData
                                    text: modelData
                                    active: card.other !== null && root.placement(card.m, card.other) === modelData
                                    onClicked: root.place(card.m, card.other, modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
