import QtQuick

// Settings app > Drives: the control center's Drives panel and what happens when a drive is
// plugged in (Drives.qml).
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

        SettingsRow {
            icon: "usb"
            title: "Open it right away"
            description: "Mounts it and shows a notification with Open and Eject. Off: the notification asks first."
            Switch {
                checked: Settings.drives.automount
                onToggled: Settings.drives.automount = !checked
            }
        }

        SettingsRow {
            icon: "folder_open"
            title: "Show it in the file manager"
            description: "Opens a window on the drive as soon as it's mounted."
            enabled: Settings.drives.automount
            opacity: enabled ? 1 : 0.5
            Switch {
                checked: Settings.drives.openFiles
                onToggled: Settings.drives.openFiles = !checked
            }
        }
    }
}
