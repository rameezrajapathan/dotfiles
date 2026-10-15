import QtQuick

// Settings app > Network: the control center's network panel (wired, Wi-Fi, VPN, speed).
SettingsPage {
    id: root
    title: "Network"
    subtitle: "Wired, Wi-Fi and VPN connections, and a speed test."

    SettingsPanelCard {
        NetworkPanel { shown: root.shown }
    }
}
