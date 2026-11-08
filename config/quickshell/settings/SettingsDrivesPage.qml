import QtQuick
import qs.panels
import qs.services
import qs.widgets

SettingsPage {
    id: root
    title: "Drives"
    subtitle: "USB drives, SD cards and disk images."

    SettingsPanelCard {
        DrivesPanel { shown: root.shown }
    }

    SettingsSection {
        title: "When a drive is plugged in"
        canReset: !Settings.drives.automount || Settings.drives.openFiles
        onReset: {
            Settings.drives.automount = true;
            Settings.drives.openFiles = false;
        }

        SettingsSwitchRow {
            icon: "usb"
            title: "Open it right away"
            description: "Mounts it and shows a notification with Open and Eject. Off: the notification asks first."
            target: Settings.drives
            key: "automount"
        }

        SettingsSwitchRow {
            icon: "folder_open"
            title: "Show it in the file manager"
            description: "Opens a window on the drive as soon as it's mounted."
            enabled: Settings.drives.automount
            opacity: enabled ? 1 : 0.5
            target: Settings.drives
            key: "openFiles"
        }
    }
}
