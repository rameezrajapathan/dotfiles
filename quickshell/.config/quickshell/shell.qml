//@ pragma UseQApplication
// Needed for tray app menus (Tray.qml), which are native Qt menus
import Quickshell
import QtQuick

ShellRoot {
    // Background services that nothing else wakes up at start (singletons load on first use)
    Component.onCompleted: [Updates.checked, TimeDate.timezone, Drives.loaded]

    Variants {
        model: Quickshell.screens
        Bar {}
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
