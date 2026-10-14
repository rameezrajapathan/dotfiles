import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown under the bar: Bluetooth on/off, paired devices (click to connect or disconnect) and,
// while the panel is open, nearby devices to pair. A transparent full-screen overlay: clicks
// outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: (adapter?.devices.values ?? []).filter(d => d.name !== "")
    readonly property var paired: devices.filter(d => d.paired)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // Devices that don't broadcast a name show up as their address; skip those
    readonly property var nearby: devices.filter(d => !d.paired && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name))
        .sort((a, b) => a.name.localeCompare(b.name))

    function toggle() {
        visible = !visible;
    }

    // Material Symbols name for BlueZ's device icon (audio-headset, input-mouse, phone, …)
    function deviceIcon(device) {
        const icon = device.icon ?? "";
        const map = [
            [/headset/, "headset_mic"], [/headphone|audio-card/, "headphones"], [/speaker/, "speaker"],
            [/mouse/, "mouse"], [/keyboard/, "keyboard"], [/gaming|joystick/, "sports_esports"],
            [/phone/, "mobile"], [/computer/, "computer"], [/watch/, "watch"], [/video|tv/, "tv"],
            [/printer/, "print"]
        ];
        return map.find(m => m[0].test(icon))?.[1] ?? "devices";
    }

    function activate(device) {
        if (device.connected) {
            device.disconnect();
        } else if (device.paired) {
            device.connect();
        } else {
            // Trusted devices reconnect on their own later
            device.trusted = true;
            device.pair();
        }
    }

    function status(device) {
        if (device.pairing)
            return "pairing…";
        if (device.state === BluetoothDeviceState.Connecting)
            return "connecting…";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "disconnecting…";
        if (device.connected)
            return device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "connected";
        return "";
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-bluetooth"
    color: "transparent"
    visible: false

    // Look for nearby devices only while the panel is open
    onVisibleChanged: {
        if (adapter?.enabled)
            adapter.discovering = visible;
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
        width: 360
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
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 10

                Label {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    font.bold: true
                }
                Pill {
                    text: "settings"
                    onClicked: {
                        root.visible = false;
                        Quickshell.execDetached(["kitty", "-e", "bluetoothctl"]);
                    }
                }
                Switch {
                    checked: root.adapter?.enabled ?? false
                    onToggled: {
                        if (!root.adapter)
                            return;
                        root.adapter.enabled = !root.adapter.enabled;
                        if (root.adapter.enabled)
                            root.adapter.discovering = true;
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                visible: !(root.adapter?.enabled ?? false)
                horizontalAlignment: Text.AlignHCenter
                text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter"
                color: Theme.subtext
            }

            // Paired
            SectionLabel {
                text: "My devices"
                visible: (root.adapter?.enabled ?? false) && root.paired.length > 0
            }
            Repeater {
                model: (root.adapter?.enabled ?? false) ? root.paired : []

                PanelRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: root.deviceIcon(modelData)
                    title: modelData.name
                    highlighted: modelData.connected
                    detail: root.status(modelData)
                    onClicked: root.activate(modelData)

                    Pill {
                        visible: !modelData.connected
                        text: "forget"
                        onClicked: modelData.forget()
                    }
                }
            }

            // Nearby
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: root.adapter?.enabled ?? false

                Label {
                    Layout.fillWidth: true
                    text: "Nearby"
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                }
                Icon {
                    visible: root.adapter?.discovering ?? false
                    name: "bluetooth_searching"
                    size: 16
                    color: Theme.accent

                    SequentialAnimation on opacity {
                        running: root.visible && (root.adapter?.discovering ?? false)
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 700 }
                        NumberAnimation { to: 1; duration: 700 }
                    }
                }
            }
            Label {
                Layout.leftMargin: 8
                visible: (root.adapter?.enabled ?? false) && root.nearby.length === 0
                text: root.adapter?.discovering ? "Searching…" : "No devices found"
                color: Theme.overlay
                font.pixelSize: Theme.fontSize - 1
            }
            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(nearbyColumn.implicitHeight, 6 * 36)
                visible: (root.adapter?.enabled ?? false) && root.nearby.length > 0
                contentHeight: nearbyColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: nearbyColumn
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.nearby

                        PanelRow {
                            required property var modelData
                            Layout.fillWidth: true
                            icon: root.deviceIcon(modelData)
                            title: modelData.name
                            detail: root.status(modelData) || "pair"
                            onClicked: root.activate(modelData)
                        }
                    }
                }
            }
        }
    }

    component SectionLabel: Label {
        Layout.topMargin: 6
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }
}
