pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The signed-in user: name, host and profile picture. The picture is ~/.face (what display
// managers read too), square-cropped to 512 px by magick when it's set from the Account tab.
Singleton {
    id: root

    readonly property string userName: Quickshell.env("USER") ?? ""
    readonly property string facePath: Quickshell.env("HOME") + "/.face"
    property string fullName: ""
    property string hostName: ""
    // Image source for the picture, or "" when there is none; the mtime busts the image cache
    property string avatar: ""
    readonly property string displayName: fullName !== "" ? fullName : userName

    // Picks an image with a file dialog and makes it the profile picture
    function choosePicture() {
        Quickshell.execDetached(["sh", "-c",
            'f=$(zenity --file-selection --title "Choose a profile picture" '
            + '--file-filter "Images | *.png *.jpg *.jpeg *.webp *.gif *.bmp *.svg" '
            + '--file-filter "All files | *") || exit 0; '
            + 'magick "$f[0]" -auto-orient -gravity center -resize 512x512^ -extent 512x512 "png:$1.tmp" '
            + '&& mv "$1.tmp" "$1" || { rm -f "$1.tmp"; notify-send -a Account "Couldn\'t use that picture" "$f"; exit 1; }; '
            + 'busctl --system call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" '
            + 'org.freedesktop.Accounts.User SetIconFile s "$1" >/dev/null 2>&1; '
            + 'qs ipc call account refresh',
            "sh", facePath]);
    }

    function removePicture() {
        Quickshell.execDetached(["sh", "-c", 'rm -f "$1"; qs ipc call account refresh', "sh", facePath]);
    }

    function refresh() {
        check.running = true;
    }

    Component.onCompleted: {
        refresh();
        info.running = true;
    }

    IpcHandler {
        target: "account"
        function refresh(): void { root.refresh(); }
    }

    Process {
        id: check
        command: ["stat", "-L", "-c", "%Y", root.facePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const mtime = text.trim();
                root.avatar = mtime ? "file://" + root.facePath + "?" + mtime : "";
            }
        }
        onExited: code => { if (code !== 0) root.avatar = ""; }
    }

    // Full name from the passwd GECOS field, and the hostname
    Process {
        id: info
        command: ["sh", "-c", 'getent passwd "$USER" | cut -d: -f5 | cut -d, -f1; cat /etc/hostname 2>/dev/null || uname -n']
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.fullName = (lines[0] ?? "").trim();
                root.hostName = (lines[1] ?? "").trim();
            }
        }
    }
}
