import QtQuick
import qs.panels
import qs.services

SettingsPage {
    id: root
    title: "Bluetooth"
    subtitle: "Paired devices, and nearby ones while this page is open."

    SettingsPanelCard {
        BluetoothPanel { shown: root.shown }
    }
}
