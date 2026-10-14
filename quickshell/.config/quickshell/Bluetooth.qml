import Quickshell.Bluetooth
import QtQuick

// Bluetooth: off, on, or connected (filled, in the accent color). Click opens BluetoothPanel,
// right click turns the adapter on or off.
Icon {
    id: root
    signal clicked()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool connected: (adapter?.devices.values ?? []).some(d => d.connected)

    visible: adapter !== null
    name: !adapter?.enabled ? "bluetooth_disabled" : connected ? "bluetooth_connected" : "bluetooth"
    filled: connected
    color: !adapter?.enabled ? Theme.overlay : connected ? Theme.accent : Theme.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.adapter)
                    root.adapter.enabled = !root.adapter.enabled;
            } else {
                root.clicked();
            }
        }
    }
}
