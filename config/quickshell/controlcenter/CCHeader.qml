import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.services
import qs.widgets

RowLayout {
    id: root
    property var cc

    spacing: 10

    property string uptime: ""
    readonly property bool shown: cc?.open ?? false
    onShownChanged: if (shown) uptimeView.reload()

    FileView {
        id: uptimeView
        path: "/proc/uptime"
        onLoaded: {
            const s = Math.floor(Number(text().split(" ")[0]));
            const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
            root.uptime = "up " + (d > 0 ? d + " d " : "") + (d > 0 || h > 0 ? h + " h " : "") + m + " min";
        }
    }

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
        onClicked: {
            root.cc.close();
            Quickshell.execDetached(["loginctl", "lock-session"]);
        }
    }
    CCIconButton {
        icon: "settings"
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
        onClicked: {
            root.cc.close();
            Quickshell.execDetached(["qs", "ipc", "call", "power", "toggle"]);
        }
    }
}
