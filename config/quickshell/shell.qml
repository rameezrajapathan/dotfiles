//@ pragma UseQApplication
import Quickshell
import QtQuick
import qs.bar
import qs.desktop
import qs.dock
import qs.lock
import qs.overlays
import qs.services
import qs.settings

ShellRoot {
    readonly property var servicesStartedAtLaunch: [Updates, TimeDate, Drives]

    Variants {
        model: Quickshell.screens
        DesktopScreen {}
    }

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
    FirstRun {}
    VpnPassword {}
}
