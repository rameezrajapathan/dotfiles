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
    property bool unlocking: false
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
        Wallpaper.reload();
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

    Component.onCompleted: restore.running = true

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return root.isLocked(); }
    }

    Process {
        id: restore
        command: ["test", "-e", root.marker]
        onExited: code => { if (code === 0) root.lock(); }
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
