import QtQuick

// Settings app > Bluetooth: the control center's Bluetooth panel.
SettingsPage {
    id: root
    title: "Bluetooth"
    subtitle: "Paired devices, and nearby ones while this page is open."

    SettingsPanelCard {
        BluetoothPanel { shown: root.shown }
    }
}
