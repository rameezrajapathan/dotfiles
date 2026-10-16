import Quickshell
import QtQuick
import QtQuick.Layouts

// Control center widget: capture (its page), the wallpaper picker and the Settings app.
RowLayout {
    id: root
    property var cc

    spacing: 8

    CCAction {
        icon: "screenshot_region"
        text: "Capture"
        onClicked: root.cc.openDetail("capture")
    }
    CCAction {
        icon: "wallpaper"
        text: "Wallpaper"
        onClicked: {
            root.cc.close();
            Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"]);
        }
    }
    CCAction {
        icon: "settings"
        text: "Settings"
        onClicked: {
            root.cc.close();
            Settings.openRequested("");
        }
    }
}
