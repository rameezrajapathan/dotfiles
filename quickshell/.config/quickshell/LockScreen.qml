import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// What one monitor shows while locked (Lock.qml): the wallpaper blurred; on the left the clock, now
// playing and power actions; a separator; on the right the profile picture and password pill. After a
// while without input it rests: the blur softens and the right side dims.
Item {
    id: root

    required property var lock
    property string screenName: ""

    // Drives the entrance; false for the first frame so everything animates in
    property bool shown: false
    readonly property bool leaving: lock.unlocking
    // The password pill is out; it goes away after a while without input
    property bool awake: true

    readonly property var battery: UPower.displayDevice
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged
    readonly property var connectedDevices: Networking.devices.values.filter(d => d.connected)
    readonly property var netDevice: connectedDevices.find(d => d.type === DeviceType.Wired) ?? connectedDevices[0] ?? null
    readonly property var wifi: netDevice?.type === DeviceType.Wifi ? netDevice.networks.values.find(n => n.connected) ?? null : null
    readonly property var player: Media.active

    function wake() {
        awake = true;
        restTimer.restart();
        input.forceActiveFocus();
    }

    function batteryIcon() {
        if (charging)
            return "battery_android_frame_bolt";
        const pct = battery.percentage;
        if (pct < 0.1)
            return "battery_android_alert";
        if (pct > 0.95)
            return "battery_android_full";
        return "battery_android_frame_" + Math.max(1, Math.min(6, Math.round(pct * 6)));
    }

    function greeting() {
        const h = clock.date.getHours();
        const part = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
        return part + ", " + User.displayName.split(" ")[0];
    }

    Component.onCompleted: {
        Qt.callLater(() => root.shown = true);
        input.forceActiveFocus();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Timer {
        id: restTimer
        interval: 15000
        running: root.awake && root.lock.password === "" && !root.lock.checking
        onTriggered: root.awake = false
    }

    // ── Wallpaper ──────────────────────────────────────────────────────────────────────────────
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.lock.wallpaper
        sourceSize: Qt.size(root.width, root.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: wallpaper.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        // Starts sharp like the desktop it covers, blurs in, and sharpens again on the way out
        blur: root.leaving || !root.shown ? 0 : root.awake ? 0.85 : 0.45
        brightness: root.leaving || !root.shown ? 0 : root.awake ? -0.22 : -0.12
        saturation: root.leaving || !root.shown ? 0 : 0.15
        scale: root.leaving || !root.shown ? 1 : 1.06
        Behavior on blur { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        Behavior on brightness { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
        Behavior on saturation { NumberAnimation { duration: 900 } }
        Behavior on scale { NumberAnimation { duration: 1400; easing.type: Easing.OutQuint } }
    }

    // A soft shade at the bottom for the pill and cards, and the theme color when there's no image
    Rectangle {
        anchors.fill: parent
        opacity: root.leaving ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 450 } }
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.base, wallpaper.status === Image.Ready ? 0.15 : 1) }
            GradientStop { position: 0.55; color: Qt.alpha(Theme.base, wallpaper.status === Image.Ready ? 0 : 1) }
            GradientStop { position: 1; color: Qt.alpha(Theme.base, wallpaper.status === Image.Ready ? 0.55 : 1) }
        }
    }

    // ── Everything on top fades and grows a little on unlock ───────────────────────────────────
    Item {
        id: ui
        anchors.fill: parent
        opacity: root.leaving || !root.shown ? 0 : 1
        scale: root.leaving ? 1.04 : 1
        Behavior on opacity { NumberAnimation { duration: root.leaving ? 380 : 600; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        // Wakes on mouse movement and clicks; the field keeps the keyboard
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            property point last
            onPositionChanged: mouse => {
                // Ignore the synthetic move when the surface appears under the pointer
                if (Math.abs(mouse.x - last.x) + Math.abs(mouse.y - last.y) > 4 && last.x !== 0)
                    root.wake();
                last = Qt.point(mouse.x, mouse.y);
            }
            onClicked: root.wake()
        }

        // Status pill where the bar's pill sits
        Rectangle {
            id: statusPill
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.shown ? (Theme.barHeight - Theme.pillHeight) / 2 : -height
            Behavior on y { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
            width: statusRow.implicitWidth + 2 * Theme.pillInset + 8
            height: Theme.pillHeight
            radius: height / 2
            color: Qt.alpha(Theme.base, 0.55)
            border.width: 1
            border.color: Qt.alpha(Theme.text, 0.08)

            Row {
                id: statusRow
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.pillInset
                spacing: 10

                Rectangle {
                    width: Theme.pillCircle
                    height: Theme.pillCircle
                    radius: width / 2
                    color: Theme.accent

                    Icon {
                        anchors.centerIn: parent
                        name: "lock"
                        filled: true
                        size: 16
                        color: Theme.accentText
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: User.hostName || "Locked"
                    font.family: "Fira Sans"
                    font.weight: Font.Medium
                    color: Theme.subtext
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 14
                    color: Qt.alpha(Theme.text, 0.2)
                }

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: !root.netDevice ? "wifi_off" : root.wifi ? Theme.wifiIcon(root.wifi.signalStrength) : "lan"
                    size: 18
                    color: root.netDevice ? Theme.text : Theme.subtext
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.battery.isLaptopBattery
                    spacing: 4

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.batteryIcon()
                        size: 18
                        color: !root.charging && root.battery.percentage < 0.15 ? Theme.red
                            : root.charging ? Theme.green : Theme.text
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.battery.percentage * 100) + "%"
                        font.family: "Fira Sans"
                        font.weight: Font.Medium
                    }
                }

                Item { width: 2; height: 1 }
            }
        }

        // ── Left: date and time, now playing, power ────────────────────────────────────────────
        // In the middle of the left half
        Column {
            id: leftSide
            x: root.width * 0.28 - width / 2
            y: (root.height - height) / 2 + (root.shown ? 0 : 40)
            spacing: 28
            Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }

            Column {
                id: clockColumn
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.text
                    opacity: 0.85
                    font.family: "Fira Sans"
                    font.weight: Font.Medium
                    font.pixelSize: 24
                    font.letterSpacing: 0.5
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.35; shadowBlur: 0.6 }
                }

                Row {
                    id: time
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property var parts: Qt.formatDateTime(clock.date, "h:mm AP").split(" ")[0].split(":")
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.4; shadowBlur: 1; shadowVerticalOffset: 4 }

                    Text {
                        text: time.parts[0]
                        color: Theme.text
                        font.family: "Fira Sans"
                        font.weight: Font.Light
                        font.pixelSize: 190
                        font.features: { "tnum": 1 }
                    }
                    // The colon breathes with the seconds
                    Text {
                        text: ":"
                        color: Theme.accent
                        font.family: "Fira Sans"
                        font.weight: Font.Light
                        font.pixelSize: 190
                        anchors.baseline: parent.children[0].baseline
                        opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
                    }
                    Text {
                        text: time.parts[1]
                        color: Theme.text
                        font.family: "Fira Sans"
                        font.weight: Font.Light
                        font.pixelSize: 190
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        text: Qt.formatDateTime(clock.date, "AP")
                        color: Theme.accent
                        font.family: "Fira Sans"
                        font.weight: Font.Medium
                        font.pixelSize: 30
                        font.letterSpacing: 1
                        anchors.baseline: parent.children[0].baseline
                        leftPadding: 10
                    }
                }
            }

            // Now playing
            Rectangle {
                id: mediaCard
                anchors.horizontalCenter: parent.horizontalCenter
                width: 380
                height: 96
                radius: 24
                color: Qt.alpha(Theme.base, 0.5)
                border.width: 1
                border.color: Qt.alpha(Theme.text, 0.08)
                opacity: root.player ? 1 : 0
                visible: root.player !== null
                Behavior on opacity { NumberAnimation { duration: 300 } }

                ClippingRectangle {
                    id: cover
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 68
                    height: 68
                    radius: 16
                    color: Theme.surface

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        sourceSize: Qt.size(136, 136)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        name: "music_note"
                        size: 28
                        color: Theme.subtext
                    }
                }

                Column {
                    anchors.left: cover.right
                    anchors.leftMargin: 14
                    anchors.right: controls.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.player?.trackTitle || "Unknown track"
                        color: Theme.text
                        elide: Text.ElideRight
                        font.family: "Fira Sans"
                        font.weight: Font.DemiBold
                        font.pixelSize: 15
                    }
                    Text {
                        width: parent.width
                        text: root.player?.trackArtist || root.player?.identity || ""
                        color: Theme.subtext
                        elide: Text.ElideRight
                        font.family: "Fira Sans"
                        font.pixelSize: 13
                    }
                    MusicBars {
                        width: 54
                        height: 16
                        count: 9
                        visible: root.player?.isPlaying ?? false
                    }
                }

                Row {
                    id: controls
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: ["previous", "toggle", "next"]

                        Rectangle {
                            required property string modelData
                            readonly property bool main: modelData === "toggle"
                            width: main ? 44 : 34
                            height: width
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: main ? Theme.accent : controlMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                            scale: controlMouse.pressed ? 0.9 : 1
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            MediaGlyph {
                                anchors.centerIn: parent
                                size: parent.main ? 16 : 13
                                kind: parent.main ? (root.player?.isPlaying ? "pause" : "play") : parent.modelData
                                color: parent.main ? Theme.accentText : Theme.text
                            }

                            MouseArea {
                                id: controlMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const p = root.player;
                                    if (!p)
                                        return;
                                    if (parent.modelData === "previous" && p.canGoPrevious) p.previous();
                                    else if (parent.modelData === "next" && p.canGoNext) p.next();
                                    else if (parent.main && p.canTogglePlaying) p.togglePlaying();
                                }
                            }
                        }
                    }
                }
            }

        // Power
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 4
                spacing: 14

                LockButton {
                    icon: "bedtime"
                    label: "Suspend"
                    onActivated: Quickshell.execDetached(["systemctl", "suspend"])
                }
                LockButton {
                    icon: "restart_alt"
                    label: "Restart"
                    confirm: true
                    onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                }
                LockButton {
                    icon: "power_settings_new"
                    label: "Power off"
                    confirm: true
                    onActivated: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }

        // ── The separator: a fading line with a glowing diamond, and a light running down it ──
        Item {
            id: separator
            x: root.width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            // Grows out from the diamond; dims while resting
            height: root.shown ? root.height * 0.56 : 0
            opacity: root.awake ? 1 : 0.5
            Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 400 } }

            readonly property real gap: 22

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 1.5
                height: Math.max(0, parent.height / 2 - parent.gap)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Theme.text, 0) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.text, 0.4) }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 1.5
                height: Math.max(0, parent.height / 2 - parent.gap)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Theme.text, 0.4) }
                    GradientStop { position: 1; color: Qt.alpha(Theme.text, 0) }
                }
            }

            // A short accent light travelling down the line
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 3
                height: parent.height
                clip: true

                Rectangle {
                    width: parent.width
                    height: 140
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha(Theme.accent, 0) }
                        GradientStop { position: 0.5; color: Theme.accent }
                        GradientStop { position: 1; color: Qt.alpha(Theme.accent, 0) }
                    }
                    NumberAnimation on y {
                        from: -140
                        to: separator.height
                        duration: 4200
                        loops: Animation.Infinite
                        easing.type: Easing.InOutSine
                        running: separator.visible
                    }
                }
            }

            // Outline diamond around a glowing one that breathes
            Rectangle {
                anchors.centerIn: parent
                width: 22
                height: 22
                radius: 3
                rotation: 45
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(Theme.accent, 0.55)
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 2
                rotation: 45
                color: Theme.accent
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Theme.accent; shadowBlur: 1; shadowOpacity: 1 }

                SequentialAnimation on scale {
                    running: separator.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.3; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
        }

        // ── Right: profile picture, name and password ─────────────────────────────────────────────────
        Column {
            id: auth
            // In the middle of the right half; slides in from the right, dims while resting
            x: root.width * 0.72 - width / 2 + (root.shown ? 0 : 60)
            y: (root.height - height) / 2
            spacing: 14
            opacity: root.awake ? 1 : 0.55
            Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: 400 } }

            // Picture with a ring: thin while waiting, a spinning arc while checking, red when wrong
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 120

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: root.lock.failed ? Theme.red : Qt.alpha(Theme.text, root.lock.checking ? 0.12 : 0.3)
                    Behavior on border.color { ColorAnimation { duration: 250 } }
                }

                Shape {
                    id: spinner
                    anchors.fill: parent
                    visible: root.lock.checking || root.leaving
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeColor: Theme.accent
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: 60; centerY: 60
                            radiusX: 59; radiusY: 59
                            startAngle: -90
                            // Closes into a full ring once accepted
                            sweepAngle: root.leaving ? 360 : 100
                            Behavior on sweepAngle { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        running: spinner.visible && !root.leaving
                    }
                }

                Avatar {
                    anchors.centerIn: parent
                    size: 104
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.greeting()
                color: Theme.text
                font.family: "Fira Sans"
                font.weight: Font.Medium
                font.pixelSize: 20
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.3; shadowBlur: 0.5 }
            }

            Item { width: 1; height: 4 }

            // The password pill
            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 52
                radius: height / 2
                color: Qt.alpha(Theme.base, 0.5)
                border.width: 1.5
                border.color: root.lock.failed ? Qt.alpha(Theme.red, 0.8)
                    : input.activeFocus && root.lock.password !== "" ? Qt.alpha(Theme.accent, 0.7)
                    : Qt.alpha(Theme.text, 0.14)
                Behavior on border.color { ColorAnimation { duration: 200 } }

                transform: Translate { id: shake }

                SequentialAnimation {
                    id: shakeAnimation
                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 50; easing.type: Easing.OutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 12; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 5; duration: 70; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 80; easing.type: Easing.OutQuad }
                }

                Connections {
                    target: root.lock
                    function onRejected() {
                        shakeAnimation.restart();
                        root.wake();
                    }
                    function onPasswordChanged() {
                        if (input.text !== root.lock.password)
                            input.text = root.lock.password;
                    }
                }

                Icon {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.lock.capsLock ? "keyboard_capslock_badge" : "lock"
                    size: 18
                    color: root.lock.capsLock ? Theme.yellow : Theme.subtext
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.lock.password === ""
                    text: root.lock.checking ? "Checking…" : root.awake ? "Enter password" : "Press any key"
                    color: Theme.subtext
                    opacity: 0.8
                    font.family: "Fira Sans"
                    font.pixelSize: 15
                }

                // One dot per character, popping in as you type
                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    Repeater {
                        model: dots
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: root.lock.checking ? Theme.subtext : Theme.text
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }

                // Submit, once there's something to submit
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: Theme.accent
                    opacity: root.lock.password !== "" && !root.lock.checking ? 1 : 0
                    scale: opacity > 0 ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                    Icon {
                        anchors.centerIn: parent
                        name: "arrow_forward"
                        size: 20
                        weight: 600
                        color: Theme.accentText
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.opacity > 0.5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lock.submit()
                    }
                }

                TextInput {
                    id: input
                    // Invisible: the dots above show it
                    width: 0
                    height: 0
                    opacity: 0
                    focus: true
                    echoMode: TextInput.Password
                    readOnly: root.lock.checking || root.leaving
                    onTextChanged: {
                        if (text !== root.lock.password)
                            root.lock.password = text;
                        if (text !== "")
                            root.lock.failed = false;
                        while (dots.count < Math.min(text.length, 20))
                            dots.append({});
                        while (dots.count > Math.min(text.length, 20))
                            dots.remove(dots.count - 1);
                    }
                    onAccepted: root.lock.submit()

                    Keys.onPressed: event => {
                        root.wake();
                        if (event.key === Qt.Key_Escape) {
                            if (text === "")
                                root.awake = false;
                            text = "";
                            event.accepted = true;
                        }
                    }
                    Keys.onReleased: root.lock.checkCapsLock()
                }

                ListModel { id: dots }
            }

            // Why the last try failed, or a Caps Lock warning
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 420
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.lock.failed ? root.lock.message : root.lock.capsLock ? "Caps Lock is on" : " "
                color: root.lock.failed ? Theme.red : Theme.yellow
                font.family: "Fira Sans"
                font.weight: Font.Medium
                font.pixelSize: 14
            }
        }
    }
}
