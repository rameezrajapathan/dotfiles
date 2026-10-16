import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick
import qs.services

Scope {
    id: root

    property string password: ""
    property bool checking: false
    property bool failed: false
    property string message: ""
    property bool capsLock: false
    property bool unlocking: false
    readonly property string wallpaper: wallpaperPath(wallpaperConf.text())
    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-locked"

    signal rejected()

    function isLocked() {
        return sessionLock.locked && sessionLock.secure;
    }

    function lock() {
        if (isLocked())
            return;
        sessionLock.locked = false;
        password = "";
        failed = false;
        message = "";
        checking = false;
        unlocking = false;
        wallpaperConf.reload();
        sessionLock.locked = true;
        Quickshell.execDetached(["touch", marker]);
        confirmTimer.restart();
    }

    function submit() {
        if (checking || unlocking || password === "")
            return;
        failed = false;
        message = "";
        checking = true;
        if (!pam.start()) {
            checking = false;
            reject("Couldn't start the password check");
        }
    }

    function reject(why) {
        password = "";
        failed = true;
        message = why;
        rejected();
    }

    function checkCapsLock() {
        if (!caps.running)
            caps.running = true;
    }

    function wallpaperPath(conf) {
        const match = /^\s*path\s*=\s*(.+?)\s*$/m.exec(conf ?? "");
        if (!match)
            return "";
        return "file://" + match[1].replace(/^~(?=\/)/, Quickshell.env("HOME"));
    }

    Component.onCompleted: restore.running = true

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return root.isLocked(); }
    }

    FileView {
        id: wallpaperConf
        path: Quickshell.env("HOME") + "/.config/hypr/wallpaper.conf"
    }

    Process {
        id: restore
        command: ["test", "-e", root.marker]
        onExited: code => { if (code === 0) root.lock(); }
    }

    Process {
        id: caps
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards ?? [];
                    const main = keyboards.find(k => k.main) ?? keyboards[0];
                    root.capsLock = main?.capsLock ?? false;
                } catch (e) {}
            }
        }
    }

    PamContext {
        id: pam
        config: "login"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
            else if (messageIsError)
                root.message = message;
        }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                root.unlocking = true;
                unlockTimer.start();
            } else {
                root.reject(root.message !== "" ? root.message : "Wrong password");
            }
        }
        onError: error => {
            root.checking = false;
            root.reject("Authentication error: " + PamError.toString(error));
        }
    }

    Timer {
        id: confirmTimer
        interval: 2000
        onTriggered: {
            if (!sessionLock.secure) {
                sessionLock.locked = false;
                Quickshell.execDetached(["rm", "-f", root.marker]);
            }
        }
    }

    Timer {
        id: unlockTimer
        interval: 550
        onTriggered: {
            sessionLock.locked = false;
            root.unlocking = false;
            root.password = "";
            Quickshell.execDetached(["rm", "-f", root.marker]);
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface
            color: Theme.base

            LockScreen {
                anchors.fill: parent
                lock: root
                screenName: surface.screen?.name ?? ""
            }
        }
    }
}
