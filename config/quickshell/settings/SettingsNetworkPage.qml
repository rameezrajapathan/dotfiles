import QtQuick
import qs.panels
import qs.services

SettingsPage {
    id: root
    title: "Network"
    subtitle: "Wired, Wi-Fi and VPN connections, and a speed test."

    SettingsPanelCard {
        NetworkPanel { shown: root.shown }
    }
}
