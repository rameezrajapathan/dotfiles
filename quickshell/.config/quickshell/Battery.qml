import Quickshell.Services.UPower
import QtQuick

Icon {
    id: root
    signal clicked()

    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
        || dev.state === UPowerDeviceState.FullyCharged

    visible: dev.isLaptopBattery
    name: charging ? "battery_android_frame_bolt"
        : percent <= 10 ? "battery_android_frame_alert"
        : percent >= 95 ? "battery_android_frame_full"
        : "battery_android_frame_" + Math.max(1, Math.min(6, Math.round(percent / 100 * 6)))
    color: charging ? Theme.green : percent <= 15 ? Theme.red : percent <= 30 ? Theme.yellow : Theme.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
