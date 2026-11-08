import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Greetd
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root
    required property var modelData
    required property var theme
    required property string dir
    required property var users
    required property var sessions
    required property string hostName
    property bool leaving: false
    signal leave()
    property var launchCommand: null

    readonly property bool main: modelData === Quickshell.screens[0]

    property int userIndex: 0
    property int sessionIndex: 0
    property string layout: ""
    property string menu: ""

    readonly property var user: users[userIndex] ?? { name: theme.user || "", full: theme.user || "" }
    readonly property var session: sessions[sessionIndex] ?? null
    readonly property string face: user.name ? "file://" + dir + "/faces/" + user.name : ""

    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged
    readonly property int batteryPercent: Math.round(battery.percentage * 100)
    readonly property var connectedDevices: Networking.devices.values.filter(d => d.connected)
    readonly property var netDevice: connectedDevices.find(d => d.type === DeviceType.Wired) ?? connectedDevices[0] ?? null
    readonly property var wifi: netDevice?.type === DeviceType.Wifi ? netDevice.networks.values.find(n => n.connected) ?? null : null

    onUsersChanged: {
        const i = users.findIndex(u => u.name === theme.user);
        userIndex = i >= 0 ? i : 0;
    }
    onSessionsChanged: {
        const i = sessions.findIndex(s => s.file === theme.session);
        sessionIndex = i >= 0 ? i : Math.max(0, sessions.findIndex(s => s.file === "hyprland.desktop"));
    }

    function submit() {
        if (greeterAuth.checking || !user.name)
            return;
        greeterAuth.failed = false;
        greeterAuth.message = "";
        if (!Greetd.available) {
            greeterAuth.message = "Preview: greetd isn't running, so nothing happens";
            greeterAuth.failed = true;
            return;
        }
        greeterAuth.checking = true;
        Greetd.createSession(user.name);
    }

    function fail(text) {
        greeterAuth.checking = false;
        greeterAuth.failed = true;
        greeterAuth.message = text || "That password didn't work";
        greeterAuth.password = "";
        greeterAuth.rejected();
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    function openMenu(name, anchor) {
        if (menu === name) {
            menu = "";
            return;
        }
        const p = anchor.mapToItem(root.contentItem, 0, 0);
        const m = name === "users" ? userMenu : sessionMenu;
        m.x = Math.max(16, Math.min(root.width - m.width - 16, p.x + anchor.width / 2 - m.width / 2));
        m.y = name === "users" ? p.y + anchor.height + 12 : p.y - m.height - 12;
        menu = name;
    }

    function closeMenu() {
        menu = "";
        surface.wake();
    }

    QtObject {
        id: greeterAuth
        property string password: ""
        property bool checking: false
        property bool failed: false
        property string message: ""
        signal rejected()
        function submit() { root.submit(); }
    }

    Connections {
        target: Greetd
        enabled: root.main
        function onAuthMessage(text, error, responseRequired, echoResponse) {
            if (error) {
                greeterAuth.message = text;
                greeterAuth.failed = true;
            }
            if (responseRequired)
                Greetd.respond(greeterAuth.password);
        }
        function onAuthFailure(text) {
            root.fail(text);
        }
        function onError(text) {
            root.fail(text);
        }
        function onReadyToLaunch() {
            Quickshell.execDetached(["sh", "-c", 'printf "%s\\n%s\\n%s\\n" "$1" "$2" "$(date +%s)" > "$3/last" 2>/dev/null', "sh", root.user.name, root.session?.file ?? "", root.dir]);
            const exec = (root.session?.exec ?? "start-hyprland").replace(/\s%[a-zA-Z]/g, "").replace(/'/g, "'\\''");
            root.launchCommand = "sh -c 'printf \"\\033[?25l\\033[2J\\033[3J\\033[H\"; command -v systemd-cat >/dev/null || exec " + exec + "; exec systemd-cat -t pikadots-session " + exec + "'";
            root.leave();
            launchTimer.start();
        }
    }

    Timer {
        id: launchTimer
        interval: 780
        onTriggered: Greetd.launch([root.launchCommand], ["XDG_SESSION_TYPE=wayland"], true)
    }

    FileView {
        path: root.dir + "/kb_layout"
        printErrors: false
        onLoaded: root.layout = text().trim()
    }

    FileView {
        path: root.dir + "/last"
        printErrors: false
        onLoaded: {
            const [u, s, at] = text().split("\n");
            const since = Date.now() / 1000 - parseInt(at);
            if (since >= 0 && since < 20) {
                greeterAuth.message = "Your last session closed right after it started. Pick another session, or press Ctrl + Alt + F3 for a text console";
                greeterAuth.failed = true;
            }
            const ui = root.users.findIndex(x => x.name === u);
            if (ui >= 0)
                root.userIndex = ui;
            const si = root.sessions.findIndex(x => x.file === s);
            if (si >= 0)
                root.sessionIndex = si;
        }
    }

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pikadots-greeter"
    WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: theme.base

    component Menu: Rectangle {
        id: menuBox
        required property var theme
        property var labels: []
        property int current: -1
        signal picked(int index)

        width: 260
        height: menuList.implicitHeight + 12
        radius: theme.round(16)
        color: Qt.alpha(theme.base, 0.92)
        border.width: 1
        border.color: Qt.alpha(theme.text, 0.1)

        Column {
            id: menuList
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            Repeater {
                model: menuBox.labels
                Rectangle {
                    required property string modelData
                    required property int index
                    width: menuList.width
                    height: 40
                    radius: menuBox.theme.round(10)
                    color: index === menuBox.current ? Qt.alpha(menuBox.theme.accent, 0.25)
                        : rowMouse.containsMouse ? Qt.alpha(menuBox.theme.surface, 0.8) : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        text: parent.modelData
                        color: menuBox.theme.text
                        font.family: menuBox.theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menuBox.picked(parent.index)
                    }
                }
            }
        }
    }

    LockSurface {
        id: surface
        anchors.fill: parent
        theme: root.theme
        auth: greeterAuth
        leaving: root.leaving
        primary: root.main
        wallpaper: root.theme.wallpaper
        blur: root.theme.blur
        restSeconds: root.theme.restSeconds
        use24h: root.theme.clock24
        userName: root.user.full || root.user.name
        face: root.face
        hostName: root.hostName
        busyText: "Signing in…"
        showPower: root.theme.showPower

        networkIcon: !root.netDevice ? "wifi_off" : root.wifi ? root.theme.wifiIcon(root.wifi.signalStrength) : "lan"
        networkConnected: root.netDevice !== null
        hasBattery: root.battery.isLaptopBattery
        batteryIcon: root.charging ? "battery_android_frame_bolt"
            : root.batteryPercent <= 10 ? "battery_android_frame_alert"
            : root.batteryPercent >= 95 ? "battery_android_frame_full"
            : "battery_android_frame_" + Math.max(1, Math.min(6, Math.round(root.batteryPercent / 100 * 6)))
        batteryPercent: root.batteryPercent
        charging: root.charging

        onCancelled: {
            if (!Greetd.available)
                Qt.quit();
        }

        belowClock: Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            LockButton {
                id: sessionButton
                theme: root.theme
                icon: "desktop_windows"
                text: root.session?.name ?? "No sessions found"
                label: "Session"
                onActivated: root.openMenu("sessions", sessionButton)
            }
            LockButton {
                visible: root.layout !== ""
                theme: root.theme
                icon: "keyboard"
                text: root.layout.toUpperCase()
                label: "Keyboard layout"
            }
        }

        userPicker: LockIcon {
            id: userChevron
            visible: root.users.length > 1
            theme: root.theme
            name: "expand_more"
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openMenu("users", userChevron)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: root.menu !== ""
        onClicked: root.closeMenu()
    }

    Menu {
        id: userMenu
        visible: root.menu === "users"
        theme: root.theme
        labels: root.users.map(u => u.full + (u.full !== u.name ? "  (" + u.name + ")" : ""))
        current: root.userIndex
        onPicked: index => {
            root.userIndex = index;
            greeterAuth.password = "";
            root.closeMenu();
        }
    }

    Menu {
        id: sessionMenu
        visible: root.menu === "sessions"
        theme: root.theme
        labels: root.sessions.map(s => s.name)
        current: root.sessionIndex
        onPicked: index => {
            root.sessionIndex = index;
            root.closeMenu();
        }
    }

    Item {
        id: splash
        anchors.fill: parent
        visible: root.leaving
        onVisibleChanged: if (visible) splashAnim.start()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        Image {
            id: sharp
            anchors.fill: parent
            source: root.theme.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0
            scale: 1.04
        }

        Rectangle {
            anchors.fill: parent
            opacity: sharp.opacity
            gradient: Gradient {
                GradientStop { position: 0.45; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha(root.theme.base, 0.6) }
            }
        }

        Column {
            id: welcome
            visible: root.main
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 24
            spacing: 16
            opacity: 0
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.45; shadowBlur: 1; shadowVerticalOffset: 4 }

            ClippingRectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 120
                radius: root.theme.round(width / 2, width, height)
                color: root.theme.surface
                border.width: 3
                border.color: Qt.alpha(root.theme.text, 0.25)
                Image {
                    id: splashFace
                    anchors.fill: parent
                    source: root.face
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                LockIcon {
                    anchors.centerIn: parent
                    visible: splashFace.status !== Image.Ready
                    theme: root.theme
                    name: "person"
                    filled: true
                    size: 78
                    color: root.theme.subtext
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Welcome back"
                color: root.theme.text
                opacity: 0.8
                font.family: root.theme.font
                font.pixelSize: 22
                font.weight: Font.Medium
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.user.full || root.user.name
                color: root.theme.text
                font.family: root.theme.displayFont
                font.pixelSize: 44
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            id: fade
            anchors.fill: parent
            color: "black"
            opacity: 0
        }

        ParallelAnimation {
            id: splashAnim
            NumberAnimation { target: sharp; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: sharp; property: "scale"; to: 1; duration: 800; easing.type: Easing.OutCubic }
            SequentialAnimation {
                PauseAnimation { duration: 60 }
                ParallelAnimation {
                    NumberAnimation { target: welcome; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: welcome; property: "anchors.verticalCenterOffset"; to: 0; duration: 320; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 160 }
                NumberAnimation { target: fade; property: "opacity"; to: 1; duration: 220; easing.type: Easing.InQuad }
            }
        }
    }
}
