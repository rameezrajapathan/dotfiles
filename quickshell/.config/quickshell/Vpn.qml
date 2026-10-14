import QtQuick

// Green while any VPN is connected; click opens the network panel.
Label {
    id: root
    signal clicked()

    text: "󰖂 vpn"
    color: VpnService.anyActive ? Theme.green : Theme.overlay

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
