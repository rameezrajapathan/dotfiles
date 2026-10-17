import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.bar
import qs.panels
import qs.services
import qs.widgets

Item {
    id: root

    required property var lock
    property string screenName: ""

    property bool shown: false
    readonly property bool leaving: lock.unlocking
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
        interval: Math.max(1, Settings.lock.restSeconds) * 1000
        running: Settings.lock.restSeconds > 0 && root.awake && root.lock.password === "" && !root.lock.checking
        onTriggered: root.awake = false
    }

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
        blur: root.leaving || !root.shown ? 0 : root.awake ? Settings.lock.blur : Settings.lock.blur * 0.53
        brightness: root.leaving || !root.shown ? 0 : root.awake ? -0.22 : -0.12
        saturation: root.leaving || !root.shown ? 0 : 0.15
        scale: root.leaving || !root.shown ? 1 : 1.06
        Behavior on blur { NumberAnimation { duration: Theme.ms(900); easing.type: Easing.OutCubic } }
        Behavior on brightness { NumberAnimation { duration: Theme.ms(900); easing.type: Easing.OutCubic } }
        Behavior on saturation { NumberAnimation { duration: Theme.ms(900) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(1400); easing.type: Easing.OutQuint } }
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.leaving ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.ms(450) } }
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Theme.base, wallpaper.status === Image.Ready ? 0.15 : 1) }
            GradientStop { position: 0.55; color: Qt.alpha(Theme.base, wallpaper.status === Image.Ready ? 0 : 1) }
            GradientStop { position: 1; color: Qt.alpha(Theme.base, wallpaper.status === Image.Ready ? 0.55 : 1) }
        }
    }

    Item {
        id: ui
        anchors.fill: parent
        opacity: root.leaving || !root.shown ? 0 : 1
        scale: root.leaving ? 1.04 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.ms(root.leaving ? 380 : 600); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(450); easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            property point last
            onPositionChanged: mouse => {
                if (Math.abs(mouse.x - last.x) + Math.abs(mouse.y - last.y) > 4 && last.x !== 0)
                    root.wake();
                last = Qt.point(mouse.x, mouse.y);
            }
            onClicked: root.wake()
        }

        Rectangle {
            id: statusPill
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.shown ? (Theme.barHeight - Theme.pillHeight) / 2 : -height
            Behavior on y { NumberAnimation { duration: Theme.ms(700); easing.type: Easing.OutQuint } }
            width: statusRow.implicitWidth + 2 * Theme.pillInset + 8
            height: Theme.pillHeight
            radius: Theme.round(height / 2, width, height)
            color: "transparent"
            border.width: Glass.active ? 0 : 1
            border.color: Qt.alpha(Theme.text, 0.08)
            onYChanged: statusGlass.updateMap()

            GlassPanel {
                id: statusGlass
                radius: statusPill.radius
                tint: Qt.alpha(Theme.base, 0.55)
                backdropItem: root
                backdropSource: root.lock.wallpaper
                fill: false
            }

            Row {
                id: statusRow
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.pillInset
                spacing: 10

                Rectangle {
                    width: Theme.pillCircle
                    height: Theme.pillCircle
                    radius: Theme.round(width / 2, width, height)
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
                    font.family: Theme.displayFont
                    font.weight: Font.Medium
                    color: Theme.subtext
                }

                GlassDivider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Glass.active ? 2 : 1
                    height: 14
                    vertical: true
                    strength: 0.33
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
                        font.family: Theme.displayFont
                        font.weight: Font.Medium
                    }
                }

                Item { width: 2; height: 1 }
            }
            GlassRim {}
        }

        Column {
            id: leftSide
            x: root.width * 0.28 - width / 2
            y: (root.height - height) / 2 + (root.shown ? 0 : 40)
            spacing: 28
            Behavior on x { NumberAnimation { duration: Theme.ms(900); easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: Theme.ms(800); easing.type: Easing.OutQuint } }

            Column {
                id: clockColumn
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.text
                    opacity: 0.85
                    font.family: Theme.displayFont
                    font.weight: Font.Medium
                    font.pixelSize: 24
                    font.letterSpacing: 0.5
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.35; shadowBlur: 0.6 }
                }

                Row {
                    id: time
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property var parts: Qt.formatDateTime(clock.date, Settings.bar.clock24 ? "HH:mm" : "h:mm AP").split(" ")[0].split(":")
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.4; shadowBlur: 1; shadowVerticalOffset: 4 }

                    Text {
                        text: time.parts[0]
                        color: Theme.text
                        font.family: Theme.displayFont
                        font.weight: Font.Light
                        font.pixelSize: 190
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        text: ":"
                        color: Theme.accent
                        font.family: Theme.displayFont
                        font.weight: Font.Light
                        font.pixelSize: 190
                        anchors.baseline: parent.children[0].baseline
                        opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                        Behavior on opacity { NumberAnimation { duration: Theme.ms(600); easing.type: Easing.InOutSine } }
                    }
                    Text {
                        text: time.parts[1]
                        color: Theme.text
                        font.family: Theme.displayFont
                        font.weight: Font.Light
                        font.pixelSize: 190
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: !Settings.bar.clock24
                        text: Qt.formatDateTime(clock.date, "AP")
                        color: Theme.accent
                        font.family: Theme.displayFont
                        font.weight: Font.Medium
                        font.pixelSize: 30
                        font.letterSpacing: 1
                        anchors.baseline: parent.children[0].baseline
                        leftPadding: 10
                    }
                }
            }

            Rectangle {
                id: mediaCard
                anchors.horizontalCenter: parent.horizontalCenter
                width: 380
                height: 96
                radius: Theme.round(24, width, height)
                color: "transparent"
                border.width: Glass.active ? 0 : 1
                border.color: Qt.alpha(Theme.text, 0.08)
                onYChanged: mediaGlass.updateMap()

                GlassPanel {
                    id: mediaGlass
                    radius: mediaCard.radius
                    tint: Qt.alpha(Theme.base, 0.5)
                    backdropItem: root
                    backdropSource: root.lock.wallpaper
                    fill: false
                }
                opacity: root.player ? 1 : 0
                visible: root.player !== null && Settings.lock.showMedia
                Behavior on opacity { NumberAnimation { duration: Theme.ms(300) } }

                ClippingRectangle {
                    id: cover
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.pad(14, 24, parent.width, parent.height)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 68
                    height: 68
                    radius: Theme.round(16, width, height)
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
                    GlassRim {}
                }

                Column {
                    anchors.left: cover.right
                    anchors.leftMargin: Theme.pad(14, 24, parent.width, parent.height)
                    anchors.right: controls.left
                    anchors.rightMargin: Theme.pad(8, 24, parent.width, parent.height)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.player?.trackTitle || "Unknown track"
                        color: Theme.text
                        elide: Text.ElideRight
                        font.family: Theme.displayFont
                        font.weight: Font.DemiBold
                        font.pixelSize: 15
                    }
                    Text {
                        width: parent.width
                        text: root.player?.trackArtist || root.player?.identity || ""
                        color: Theme.subtext
                        elide: Text.ElideRight
                        font.family: Theme.displayFont
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
                    anchors.rightMargin: Theme.pad(12, 24, parent.width, parent.height)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Repeater {
                        model: ["previous", "toggle", "next"]

                        Rectangle {
                            required property string modelData
                            readonly property bool main: modelData === "toggle"
                            width: main ? 44 : 34
                            height: width
                            radius: Theme.round(width / 2, width, height)
                            anchors.verticalCenter: parent.verticalCenter
                            color: main ? Theme.selectedFill : controlMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                            scale: controlMouse.pressed ? 0.9 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.ms(100) } }

                            MediaGlyph {
                                anchors.centerIn: parent
                                size: parent.main ? 16 : 13
                                kind: parent.main ? (root.player?.isPlaying ? "pause" : "play") : parent.modelData
                                color: parent.main ? Theme.selectedText : Theme.text
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
                            GlassRim {}
                        }
                    }
                }
                GlassRim {}
            }

            Row {
                visible: Settings.lock.showPower
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

        Item {
            id: separator
            x: root.width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: root.shown ? root.height * 0.56 : 0
            opacity: root.awake ? 1 : 0.5
            Behavior on height { NumberAnimation { duration: Theme.ms(1000); easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: Theme.ms(400) } }

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

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 3
                height: parent.height
                clip: true

                Rectangle {
                    width: parent.width
                    height: 140
                    radius: Theme.round(width / 2, width, height)
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

            Rectangle {
                anchors.centerIn: parent
                width: 22
                height: 22
                radius: Theme.round(3, width, height)
                rotation: 45
                color: "transparent"
                border.width: 1
                border.color: Theme.gradientAccent ? "transparent" : Qt.alpha(Theme.accent, 0.55)
                GradientBorder {
                    strength: 0.55
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: Theme.round(2, width, height)
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

        Column {
            id: auth
            x: root.width * 0.72 - width / 2 + (root.shown ? 0 : 60)
            y: (root.height - height) / 2
            spacing: 14
            opacity: root.awake ? 1 : 0.55
            Behavior on x { NumberAnimation { duration: Theme.ms(800); easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: Theme.ms(400) } }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 120

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.round(width / 2, width, height)
                    color: "transparent"
                    border.width: 2
                    border.color: root.lock.failed ? Theme.red : Qt.alpha(Theme.text, root.lock.checking ? 0.12 : 0.3)
                    Behavior on border.color { ColorAnimation { duration: Theme.ms(250) } }
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
                            sweepAngle: root.leaving ? 360 : 100
                            Behavior on sweepAngle { NumberAnimation { duration: Theme.ms(300); easing.type: Easing.OutCubic } }
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
                font.family: Theme.displayFont
                font.weight: Font.Medium
                font.pixelSize: 20
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.3; shadowBlur: 0.5 }
            }

            Item { width: 1; height: 4 }

            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 52
                radius: Theme.round(height / 2, width, height)
                color: Qt.alpha(Theme.base, 0.5)
                border.width: 1.5
                border.color: root.lock.failed ? Qt.alpha(Theme.red, 0.8)
                    : input.activeFocus && root.lock.password !== "" ? Qt.alpha(Theme.accent, 0.7)
                    : Qt.alpha(Theme.text, 0.14)
                Behavior on border.color { ColorAnimation { duration: Theme.ms(200) } }

                transform: Translate { id: shake }

                SequentialAnimation {
                    id: shakeAnimation
                    NumberAnimation { target: shake; property: "x"; to: -14; duration: Theme.ms(50); easing.type: Easing.OutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 12; duration: Theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: Theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 5; duration: Theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: Theme.ms(80); easing.type: Easing.OutQuad }
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
                    font.family: Theme.displayFont
                    font.pixelSize: 15
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    Repeater {
                        model: dots
                        Rectangle {
                            width: 10
                            height: 10
                            radius: Theme.round(5, width, height)
                            color: root.lock.checking ? Theme.subtext : Theme.text
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                            Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: Theme.round(20, width, height)
                    color: Theme.accent
                    opacity: root.lock.password !== "" && !root.lock.checking ? 1 : 0
                    scale: opacity > 0 ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: Theme.ms(180) } }
                    Behavior on scale { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutBack } }

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
                GlassRim {}
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 420
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.lock.failed ? root.lock.message : root.lock.capsLock ? "Caps Lock is on" : " "
                color: root.lock.failed ? Theme.red : Theme.yellow
                font.family: Theme.displayFont
                font.weight: Font.Medium
                font.pixelSize: 14
            }
        }
    }
}
