import Quickshell.Services.UPower
import QtQuick

Label {
    id: root
    signal clicked()

    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
        || dev.state === UPowerDeviceState.FullyCharged

    visible: dev.isLaptopBattery
    font.pixelSize: Theme.fontSize + 3
    text: charging ? "󰂄" : ["󰁺", "󰁼", "󰁾", "󰂀", "󰂂", "󰁹"][Math.min(5, Math.floor(percent / 20))]
    color: charging ? Theme.green : percent <= 15 ? Theme.red : percent <= 30 ? Theme.yellow : Theme.text

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
