//@ pragma UseQApplication
// Needed for tray app menus (Tray.qml), which are native Qt menus
import Quickshell

ShellRoot {
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
}
