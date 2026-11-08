import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    required property var theme
    required property var auth
    property bool leaving: false
    property bool primary: true

    property string wallpaper: ""
    property real blur: 0.85
    property int restSeconds: 15
    property bool use24h: false
    property bool glassActive: false

    property string userName: ""
    property string face: ""
    property string hostName: ""
    property string busyText: "Checking…"
    property bool showPower: true

    property string networkIcon: "wifi_off"
    property bool networkConnected: false
    property bool hasBattery: false
    property string batteryIcon: ""
    property int batteryPercent: 0
    property bool charging: false

    property Component rim: null
    property Component backdrop: null
    property Component divider: null
    property Component accentBorder: null

    property alias belowClock: belowClockSlot.data
    property alias userPicker: userPickerSlot.data

    property bool shown: false
    property bool awake: true
    property bool capsLock: false

    signal cancelled()

    function wake() {
        awake = true;
        restTimer.restart();
        input.forceActiveFocus();
    }

    function greeting() {
        const h = clock.date.getHours();
        const part = h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
        return part + ", " + userName.split(" ")[0];
    }

    function clearPassword() {
        input.text = "";
    }

    function checkCapsLock() {
        if (!caps.running)
            caps.running = true;
    }

    Component.onCompleted: {
        Qt.callLater(() => root.shown = true);
        if (primary)
            input.forceActiveFocus();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Timer {
        id: restTimer
        interval: Math.max(1, root.restSeconds) * 1000
        running: root.restSeconds > 0 && root.awake && root.auth.password === "" && !root.auth.checking
        onTriggered: root.awake = false
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

    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.wallpaper
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
        blur: root.leaving || !root.shown ? 0 : root.awake ? root.blur : root.blur * 0.53
        brightness: root.leaving || !root.shown ? 0 : root.awake ? -0.22 : -0.12
        saturation: root.leaving || !root.shown ? 0 : 0.15
        scale: root.leaving || !root.shown ? 1 : 1.06
        Behavior on blur { NumberAnimation { duration: root.theme.ms(900); easing.type: Easing.OutCubic } }
        Behavior on brightness { NumberAnimation { duration: root.theme.ms(900); easing.type: Easing.OutCubic } }
        Behavior on saturation { NumberAnimation { duration: root.theme.ms(900) } }
        Behavior on scale { NumberAnimation { duration: root.theme.ms(1400); easing.type: Easing.OutQuint } }
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.leaving ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: root.theme.ms(450) } }
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(root.theme.base, wallpaper.status === Image.Ready ? 0.15 : 1) }
            GradientStop { position: 0.55; color: Qt.alpha(root.theme.base, wallpaper.status === Image.Ready ? 0 : 1) }
            GradientStop { position: 1; color: Qt.alpha(root.theme.base, wallpaper.status === Image.Ready ? 0.55 : 1) }
        }
    }

    Item {
        id: ui
        anchors.fill: parent
        opacity: root.leaving || !root.shown ? 0 : 1
        scale: root.leaving ? 1.04 : 1
        Behavior on opacity { NumberAnimation { duration: root.theme.ms(root.leaving ? 380 : 600); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.theme.ms(450); easing.type: Easing.OutCubic } }

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
            y: root.shown ? root.theme.barGap : -height
            Behavior on y { NumberAnimation { duration: root.theme.ms(700); easing.type: Easing.OutQuint } }
            width: statusRow.implicitWidth + 2 * root.theme.pillInset + 8
            height: root.theme.pillHeight
            radius: root.theme.round(height / 2, width, height)
            color: "transparent"
            border.width: root.glassActive ? 0 : 1
            border.color: Qt.alpha(root.theme.text, 0.08)

            Loader {
                anchors.fill: parent
                z: -1
                sourceComponent: root.backdrop
            }

            Row {
                id: statusRow
                anchors.verticalCenter: parent.verticalCenter
                x: root.theme.pillInset
                spacing: 10

                Rectangle {
                    width: root.theme.pillCircle
                    height: root.theme.pillCircle
                    radius: root.theme.round(width / 2, width, height)
                    color: root.theme.accent

                    LockIcon {
                        anchors.centerIn: parent
                        theme: root.theme
                        name: "lock"
                        filled: true
                        size: 16
                        color: root.theme.accentText
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hostName || "Locked"
                    font.family: root.theme.displayFont
                    font.pixelSize: root.theme.fontSize
                    font.weight: Font.Medium
                    color: root.theme.subtext
                }

                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: root.divider ?? plainDivider
                }

                LockIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    theme: root.theme
                    name: root.networkIcon
                    size: 18
                    color: root.networkConnected ? root.theme.text : root.theme.subtext
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.hasBattery
                    spacing: 4

                    LockIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        theme: root.theme
                        name: root.batteryIcon
                        size: 18
                        color: !root.charging && root.batteryPercent < 15 ? root.theme.red
                            : root.charging ? root.theme.green : root.theme.text
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.batteryPercent + "%"
                        color: root.theme.text
                        font.family: root.theme.displayFont
                        font.pixelSize: root.theme.fontSize
                        font.weight: Font.Medium
                    }
                }

                Item { width: 2; height: 1 }
            }
            Loader {
                anchors.fill: parent
                sourceComponent: root.rim
            }
        }

        Component {
            id: plainDivider
            Rectangle {
                width: 1
                height: 14
                color: Qt.alpha(root.theme.overlay, 0.2)
            }
        }

        Column {
            id: leftSide
            x: root.width * 0.28 - width / 2
            y: (root.height - height) / 2 + (root.shown ? 0 : 40)
            spacing: 28
            Behavior on x { NumberAnimation { duration: root.theme.ms(900); easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: root.theme.ms(800); easing.type: Easing.OutQuint } }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: root.theme.text
                    opacity: 0.85
                    font.family: root.theme.displayFont
                    font.weight: Font.Medium
                    font.pixelSize: 24
                    font.letterSpacing: 0.5
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.35; shadowBlur: 0.6 }
                }

                Row {
                    id: time
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property var parts: Qt.formatDateTime(clock.date, root.use24h ? "HH:mm" : "h:mm AP").split(" ")[0].split(":")
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.4; shadowBlur: 1; shadowVerticalOffset: 4 }

                    Text {
                        id: hours
                        text: time.parts[0]
                        color: root.theme.text
                        font.family: root.theme.displayFont
                        font.weight: Font.Light
                        font.pixelSize: 190
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        text: ":"
                        color: root.theme.accent
                        font.family: root.theme.displayFont
                        font.weight: Font.Light
                        font.pixelSize: 190
                        anchors.baseline: hours.baseline
                        opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                        Behavior on opacity { NumberAnimation { duration: root.theme.ms(600); easing.type: Easing.InOutSine } }
                    }
                    Text {
                        text: time.parts[1]
                        color: root.theme.text
                        font.family: root.theme.displayFont
                        font.weight: Font.Light
                        font.pixelSize: 190
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: !root.use24h
                        text: Qt.formatDateTime(clock.date, "AP")
                        color: root.theme.accent
                        font.family: root.theme.displayFont
                        font.weight: Font.Medium
                        font.pixelSize: 30
                        font.letterSpacing: 1
                        anchors.baseline: hours.baseline
                        leftPadding: 10
                    }
                }
            }

            Column {
                id: belowClockSlot
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.primary
                spacing: 28
            }

            Row {
                visible: root.primary && root.showPower
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 4
                spacing: 14

                LockButton {
                    theme: root.theme
                    rim: root.rim
                    icon: "bedtime"
                    label: "Suspend"
                    onActivated: Quickshell.execDetached(["systemctl", "suspend"])
                }
                LockButton {
                    theme: root.theme
                    rim: root.rim
                    icon: "restart_alt"
                    label: "Restart"
                    confirm: true
                    onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                }
                LockButton {
                    theme: root.theme
                    rim: root.rim
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
            Behavior on height { NumberAnimation { duration: root.theme.ms(1000); easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: root.theme.ms(400) } }

            readonly property real gap: 22

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 1.5
                height: Math.max(0, parent.height / 2 - parent.gap)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(root.theme.text, 0) }
                    GradientStop { position: 1; color: Qt.alpha(root.theme.text, 0.4) }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 1.5
                height: Math.max(0, parent.height / 2 - parent.gap)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(root.theme.text, 0.4) }
                    GradientStop { position: 1; color: Qt.alpha(root.theme.text, 0) }
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
                    radius: root.theme.round(width / 2, width, height)
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha(root.theme.accent, 0) }
                        GradientStop { position: 0.5; color: root.theme.accent }
                        GradientStop { position: 1; color: Qt.alpha(root.theme.accent, 0) }
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
                radius: root.theme.round(3, width, height)
                rotation: 45
                color: "transparent"
                border.width: 1
                border.color: root.theme.gradientAccent ? "transparent" : Qt.alpha(root.theme.accent, 0.55)
                Loader {
                    anchors.fill: parent
                    sourceComponent: root.accentBorder
                }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: root.theme.round(2, width, height)
                rotation: 45
                color: root.theme.accent
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: root.theme.accent; shadowBlur: 1; shadowOpacity: 1 }

                SequentialAnimation on scale {
                    running: separator.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.3; duration: 1400; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 1400; easing.type: Easing.InOutSine }
                }
            }
        }

        Column {
            id: authColumn
            visible: root.primary
            x: root.width * 0.72 - width / 2 + (root.shown ? 0 : 60)
            y: (root.height - height) / 2
            spacing: 14
            opacity: root.awake ? 1 : 0.55
            Behavior on x { NumberAnimation { duration: root.theme.ms(800); easing.type: Easing.OutQuint } }
            Behavior on opacity { NumberAnimation { duration: root.theme.ms(400) } }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 120

                Rectangle {
                    anchors.fill: parent
                    radius: root.theme.round(width / 2, width, height)
                    color: "transparent"
                    border.width: 2
                    border.color: root.auth.failed ? root.theme.red : Qt.alpha(root.theme.text, root.auth.checking ? 0.12 : 0.3)
                    Behavior on border.color { ColorAnimation { duration: root.theme.ms(250) } }
                }

                Shape {
                    id: spinner
                    anchors.fill: parent
                    visible: root.auth.checking || root.leaving
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeColor: root.theme.accent
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: 60; centerY: 60
                            radiusX: 59; radiusY: 59
                            startAngle: -90
                            sweepAngle: root.leaving ? 360 : 100
                            Behavior on sweepAngle { NumberAnimation { duration: root.theme.ms(300); easing.type: Easing.OutCubic } }
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

                ClippingRectangle {
                    id: avatar
                    anchors.centerIn: parent
                    width: 104
                    height: 104
                    radius: root.theme.round(width / 2, width, height)
                    color: picture.status === Image.Ready ? "transparent" : root.theme.surface

                    Image {
                        id: picture
                        anchors.fill: parent
                        source: root.face
                        sourceSize: Qt.size(208, 208)
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        smooth: true
                        mipmap: true
                    }
                    LockIcon {
                        anchors.centerIn: parent
                        theme: root.theme
                        visible: picture.status !== Image.Ready
                        name: "person"
                        filled: true
                        size: avatar.width * 0.65
                        color: root.theme.subtext
                    }
                    Loader {
                        anchors.fill: parent
                        sourceComponent: root.rim
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.greeting()
                    color: root.theme.text
                    font.family: root.theme.displayFont
                    font.weight: Font.Medium
                    font.pixelSize: 20
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.3; shadowBlur: 0.5 }
                }
                Row {
                    id: userPickerSlot
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { width: 1; height: 4 }

            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 52
                radius: root.theme.round(height / 2, width, height)
                color: Qt.alpha(root.theme.base, 0.5)
                border.width: 1.5
                border.color: root.auth.failed ? Qt.alpha(root.theme.red, 0.8)
                    : input.activeFocus && root.auth.password !== "" ? Qt.alpha(root.theme.accent, 0.7)
                    : Qt.alpha(root.theme.text, 0.14)
                Behavior on border.color { ColorAnimation { duration: root.theme.ms(200) } }

                transform: Translate { id: shake }

                SequentialAnimation {
                    id: shakeAnimation
                    NumberAnimation { target: shake; property: "x"; to: -14; duration: root.theme.ms(50); easing.type: Easing.OutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 12; duration: root.theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: -8; duration: root.theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 5; duration: root.theme.ms(70); easing.type: Easing.InOutQuad }
                    NumberAnimation { target: shake; property: "x"; to: 0; duration: root.theme.ms(80); easing.type: Easing.OutQuad }
                }

                Connections {
                    target: root.auth
                    function onRejected() {
                        shakeAnimation.restart();
                        root.wake();
                    }
                    function onPasswordChanged() {
                        if (input.text !== root.auth.password)
                            input.text = root.auth.password;
                    }
                }

                LockIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    theme: root.theme
                    name: root.capsLock ? "keyboard_capslock_badge" : "lock"
                    size: 18
                    color: root.capsLock ? root.theme.yellow : root.theme.subtext
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.auth.password === ""
                    text: root.auth.checking ? root.busyText : root.awake ? "Enter password" : "Press any key"
                    color: root.theme.subtext
                    opacity: 0.8
                    font.family: root.theme.displayFont
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
                            radius: root.theme.round(5, width, height)
                            color: root.auth.checking ? root.theme.subtext : root.theme.text
                            scale: 0
                            Component.onCompleted: scale = 1
                            Behavior on scale { NumberAnimation { duration: root.theme.ms(160); easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                            Behavior on color { ColorAnimation { duration: root.theme.ms(200) } }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: root.theme.round(20, width, height)
                    color: root.theme.accent
                    opacity: root.auth.password !== "" && !root.auth.checking ? 1 : 0
                    scale: opacity > 0 ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: root.theme.ms(180) } }
                    Behavior on scale { NumberAnimation { duration: root.theme.ms(220); easing.type: Easing.OutBack } }

                    LockIcon {
                        anchors.centerIn: parent
                        theme: root.theme
                        name: "arrow_forward"
                        size: 20
                        weight: 600
                        color: root.theme.accentText
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: parent.opacity > 0.5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.auth.submit()
                    }
                }

                TextInput {
                    id: input
                    width: 0
                    height: 0
                    opacity: 0
                    focus: root.primary
                    echoMode: TextInput.Password
                    readOnly: root.auth.checking || root.leaving
                    onTextChanged: {
                        if (text !== root.auth.password)
                            root.auth.password = text;
                        if (text !== "")
                            root.auth.failed = false;
                        while (dots.count < Math.min(text.length, 20))
                            dots.append({});
                        while (dots.count > Math.min(text.length, 20))
                            dots.remove(dots.count - 1);
                    }
                    onAccepted: root.auth.submit()

                    Keys.onPressed: event => {
                        root.wake();
                        if (event.key === Qt.Key_Escape) {
                            if (text === "") {
                                root.awake = false;
                                root.cancelled();
                            }
                            text = "";
                            event.accepted = true;
                        }
                    }
                    Keys.onReleased: root.checkCapsLock()
                }

                ListModel { id: dots }
                Loader {
                    anchors.fill: parent
                    sourceComponent: root.rim
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 420
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.auth.failed ? root.auth.message : root.capsLock ? "Caps Lock is on" : " "
                color: root.auth.failed ? root.theme.red : root.theme.yellow
                font.family: root.theme.displayFont
                font.weight: Font.Medium
                font.pixelSize: 14
            }
        }
    }
}
