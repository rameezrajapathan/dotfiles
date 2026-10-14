import Quickshell.Services.UPower
import QtQuick

Label {
    readonly property var dev: UPower.displayDevice
    readonly property int percent: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
        || dev.state === UPowerDeviceState.FullyCharged

    visible: dev.isLaptopBattery
    text: (charging ? "󰂄" : ["󰁺", "󰁼", "󰁾", "󰂀", "󰂂", "󰁹"][Math.min(5, Math.floor(percent / 20))]) + " " + percent + "%"
    color: charging ? Theme.green : percent <= 15 ? Theme.red : percent <= 30 ? Theme.yellow : Theme.text
}
