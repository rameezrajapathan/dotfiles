//@ pragma UseQApplication
import Quickshell
import QtQuick
import qs.bar
import qs.dock
import qs.lock
import qs.overlays
import qs.services
import qs.settings

ShellRoot {
    Component.onCompleted: [Updates.checked, TimeDate.timezone, Drives.loaded]

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        DockWindow {}
    }

    Cheatsheet {}
    WallpaperPicker {}
    NotificationPopups {}
    Launcher {}
    PowerMenu {}
    Osd {}
    SpecialToast {}
    WindowSwitcher {}
    Overview {}
    CursorGlide {}
    Lock {}
    PolkitDialog {}
    SettingsApp {}
}
