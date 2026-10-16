import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import QtQuick

// The lock screen: an ext-session-lock surface per monitor (LockScreen.qml) and the password check
// through PAM. `qs ipc call lock lock` locks; hypridle's lock_cmd runs it, so loginctl lock-session,
// Super+L, the Account tab and suspend all end up here (hyprlock is the fallback when qs isn't
// running). While locked, $XDG_RUNTIME_DIR/quickshell-locked exists, and a restarted shell locks again
// (Hyprland's misc.allow_session_lock_restore lets it take over after a crash).
Scope {
    id: root

    // Shared by every monitor's surface, so typing on one shows on all of them
    property string password: ""
    property bool checking: false
    // The last attempt failed (until the next one); message says why
    property bool failed: false
    property string message: ""
    property bool capsLock: false
    // The unlock animation is playing; the lock goes away when it ends
    property bool unlocking: false
    readonly property string wallpaper: wallpaperPath(wallpaperConf.text())
    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-locked"

    signal rejected()

    // Read fresh on every call: WlSessionLock doesn't signal lockedChanged when it unlocks, so a
    // binding to it stays true after the first unlock
    function isLocked() {
        return sessionLock.locked && sessionLock.secure;
    }

    function lock() {
        if (isLocked())
            return;
        // A lock the compositor never confirmed (or ended): start over
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

    // Caps Lock from the main keyboard; LockScreen asks on key presses
    function checkCapsLock() {
        if (!caps.running)
            caps.running = true;
    }

    // "path = ~/Pictures/x.png" from hypr/wallpaper.conf → file URL
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

    // Lock again after a restart that happened while locked
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
        // The same stack as console logins and hyprlock, faillock included
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
                // faillock explains itself in an error message; keep that one
                root.reject(root.message !== "" ? root.message : "Wrong password");
            }
        }
        onError: error => {
            root.checking = false;
            root.reject("Authentication error: " + PamError.toString(error));
        }
    }

    // The compositor didn't take the lock: drop it so the next try (or hyprlock, scripts/lock.sh)
    // isn't blocked by a lock that only exists here
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

    // Lets LockScreen's fade-out finish before the surfaces go
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
