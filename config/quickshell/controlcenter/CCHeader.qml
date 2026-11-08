import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

RowLayout {
    id: root
    property var cc

    spacing: 10

    readonly property string uptime: "up " + SysStats.uptimeText(false)
    readonly property bool shown: cc?.open ?? false
    onShownChanged: if (shown) SysStats.refreshUptime()

    Item {
        implicitWidth: 46
        implicitHeight: 46

        Avatar {
            anchors.fill: parent
            size: 46
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cc.openDetail("account")
        }

        Tooltip {
            text: "Open account"
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Label {
            Layout.fillWidth: true
            text: User.displayName
            font.pixelSize: Theme.fontSize + 3
            font.weight: Font.DemiBold
            elide: Text.ElideRight

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cc.openDetail("account")
            }
        }
        Label {
            Layout.fillWidth: true
            text: [root.uptime,
                StatusInfo.battery.isLaptopBattery ? StatusInfo.batteryPercent + "%" + (StatusInfo.charging ? " · charging" : "") : ""
            ].filter(s => s).join(" · ")
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 2
            elide: Text.ElideRight
        }
    }

    CCIconButton {
        icon: "lock"
        tip: "Lock"
        tipKeys: "Super + L"
        onClicked: {
            root.cc.close();
            Quickshell.execDetached(["loginctl", "lock-session"]);
        }
    }
    CCIconButton {
        icon: "settings"
        tip: "Open settings · Right-click for control center settings"
        tipKeys: "Super + comma"
        onClicked: {
            root.cc.close();
            Settings.openRequested("");
        }
        onRightClicked: {
            root.cc.close();
            Settings.openRequested("controlcenter");
        }
    }
    CCIconButton {
        icon: "power_settings_new"
        tone: "danger"
        tip: "Power menu"
        tipKeys: "Super + Escape"
        onClicked: {
            root.cc.close();
            Quickshell.execDetached(["qs", "ipc", "call", "power", "toggle"]);
        }
    }
}
