import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: Theme.base

    NetworkPanel {
        id: networkPanel
        bar: bar
    }

    Workspaces {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    Clock {
        anchors.centerIn: parent
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        Recording {}
        Vpn { onClicked: networkPanel.toggle() }
        Network { onClicked: networkPanel.toggle() }
        Volume {}
        Battery {}
    }
}
