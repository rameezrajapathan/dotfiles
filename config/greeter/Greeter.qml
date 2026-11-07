import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
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
    property bool leaving: false
    signal leave()
    property var launchCommand: null

    readonly property bool main: modelData === Quickshell.screens[0]
    readonly property string iconFont: "Material Symbols " + theme.iconStyle

    property int userIndex: 0
    property int sessionIndex: 0
    property string password: ""
    property string message: ""
    property bool failed: false
    property bool busy: false
    property bool usersOpen: false
    property bool sessionsOpen: false
    property string layout: ""

    readonly property var user: users[userIndex] ?? { name: theme.user || "", full: theme.user || "" }
    readonly property var session: sessions[sessionIndex] ?? null

    function round(r) {
        return r * Math.max(0, Math.min(2, theme.roundness));
    }

    onUsersChanged: {
        const i = users.findIndex(u => u.name === theme.user);
        userIndex = i >= 0 ? i : 0;
    }
    onSessionsChanged: {
        const i = sessions.findIndex(s => s.file === theme.session);
        sessionIndex = i >= 0 ? i : Math.max(0, sessions.findIndex(s => s.file === "hyprland.desktop"));
    }

    function submit() {
        if (busy || !user.name)
            return;
        failed = false;
        message = "";
        if (!Greetd.available) {
            message = "Preview: greetd isn't running, so nothing happens";
            failed = true;
            return;
        }
        busy = true;
        Greetd.createSession(user.name);
    }

    function fail(text) {
        busy = false;
        failed = true;
        message = text || "That password didn't work";
        password = "";
        input.text = "";
        shake.restart();
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    Connections {
        target: Greetd
        enabled: root.main
        function onAuthMessage(text, error, responseRequired, echoResponse) {
            if (error) {
                root.message = text;
                root.failed = true;
            }
            if (responseRequired)
                Greetd.respond(root.password);
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
                root.message = "Your last session closed right after it started. Pick another session, or press Ctrl + Alt + F3 for a text console";
                root.failed = true;
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

    component Glyph: Text {
        property string name
        property bool filled: false
        property int size: 20
        text: name
        color: root.theme.text
        font.family: root.iconFont
        font.pixelSize: size
        font.variableAxes: ({ "FILL": filled ? 1 : 0, "wght": 400, "opsz": Math.min(48, Math.max(20, size)) })
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component Chip: Rectangle {
        id: chip
        property string icon
        property string label
        property string tip
        signal clicked()
        implicitWidth: row.implicitWidth + (label ? 28 : 0) + (label ? 0 : 20)
        implicitHeight: 44
        radius: root.round(22)
        color: mouse.containsMouse ? Qt.alpha(root.theme.surface, 0.85) : Qt.alpha(root.theme.base, 0.5)
        border.width: 1
        border.color: Qt.alpha(root.theme.text, 0.1)
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Glyph { name: chip.icon; size: 20; anchors.verticalCenter: parent.verticalCenter }
            Text {
                visible: chip.label !== ""
                text: chip.label
                color: root.theme.text
                font.family: root.theme.font
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    Image {
        id: wall
        anchors.fill: parent
        source: root.theme.wallpaper ? "file://" + root.dir + "/" + root.theme.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blurMax: 64
        blur: root.theme.blur
        brightness: -0.08
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(root.theme.base, 0.1) }
            GradientStop { position: 1; color: Qt.alpha(root.theme.base, 0.55) }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.usersOpen = false;
            root.sessionsOpen = false;
            input.forceActiveFocus();
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.1 }
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowOpacity: 0.4; shadowBlur: 1; shadowVerticalOffset: 4 }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: root.theme.text
            opacity: 0.85
            font.family: root.theme.displayFont
            font.weight: Font.Medium
            font.pixelSize: 24
        }
        Row {
            id: time
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property var parts: Qt.formatDateTime(clock.date, root.theme.clock24 ? "HH:mm" : "h:mm AP").split(" ")[0].split(":")
            Text {
                id: hours
                text: time.parts[0]
                color: root.theme.text
                font.family: root.theme.displayFont
                font.weight: Font.Light
                font.pixelSize: 170
                font.features: { "tnum": 1 }
            }
            Text {
                text: ":"
                color: root.theme.accent
                font.family: root.theme.displayFont
                font.weight: Font.Light
                font.pixelSize: 170
                anchors.baseline: hours.baseline
                opacity: clock.date.getSeconds() % 2 === 0 ? 1 : 0.35
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutSine } }
            }
            Text {
                text: time.parts[1]
                color: root.theme.text
                font.family: root.theme.displayFont
                font.weight: Font.Light
                font.pixelSize: 170
                font.features: { "tnum": 1 }
            }
            Text {
                visible: !root.theme.clock24
                text: Qt.formatDateTime(clock.date, "AP")
                color: root.theme.accent
                font.family: root.theme.displayFont
                font.weight: Font.Medium
                font.pixelSize: 28
                anchors.baseline: hours.baseline
                leftPadding: 10
            }
        }
    }

    Column {
        id: login
        visible: root.main
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.14 }
        spacing: 14

        ClippingRectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 108
            height: 108
            radius: 54
            color: root.theme.accent
            border.width: 3
            border.color: Qt.alpha(root.theme.text, 0.2)
            Text {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: (root.user.full || "?").charAt(0).toUpperCase()
                color: root.theme.accentText
                font.family: root.theme.displayFont
                font.pixelSize: 46
                font.weight: Font.Bold
            }
            Image {
                id: face
                anchors.fill: parent
                source: root.user.name ? "file://" + root.dir + "/faces/" + root.user.name : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Text {
                text: root.user.full || root.user.name
                color: root.theme.text
                font.family: root.theme.displayFont
                font.pixelSize: 22
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
            Glyph {
                visible: root.users.length > 1
                name: "expand_more"
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.usersOpen = !root.usersOpen
                }
            }
        }

        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            width: 340
            height: 52
            radius: root.round(26)
            color: Qt.alpha(root.theme.base, 0.55)
            border.width: 1
            border.color: root.failed ? root.theme.red : input.activeFocus ? Qt.alpha(root.theme.accent, 0.8) : Qt.alpha(root.theme.text, 0.12)

            SequentialAnimation {
                id: shake
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
                NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
            }

            Text {
                anchors.centerIn: parent
                visible: input.text === ""
                text: root.busy ? "Signing in…" : "Password"
                color: Qt.alpha(root.theme.text, 0.5)
                font.family: root.theme.font
                font.pixelSize: 15
            }
            Row {
                anchors.centerIn: parent
                spacing: 7
                Repeater {
                    model: Math.min(input.text.length, 20)
                    Rectangle { width: 9; height: 9; radius: 4.5; color: root.theme.text }
                }
            }
            Rectangle {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                width: 40
                height: 40
                radius: root.round(20)
                color: root.theme.accent
                opacity: input.text !== "" && !root.busy ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Glyph { anchors.centerIn: parent; name: "arrow_forward"; color: root.theme.accentText }
                MouseArea {
                    anchors.fill: parent
                    visible: parent.opacity > 0.5
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submit()
                }
            }
            TextInput {
                id: input
                width: 0
                height: 0
                opacity: 0
                focus: root.main
                echoMode: TextInput.Password
                readOnly: root.busy
                onTextChanged: {
                    root.password = text;
                    if (text !== "")
                        root.failed = false;
                }
                onAccepted: root.submit()
                Keys.onEscapePressed: {
                    if (text === "" && !Greetd.available)
                        Qt.quit();
                    text = "";
                }
                Component.onCompleted: if (root.main) forceActiveFocus()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 420
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: root.message || " "
            color: root.failed ? root.theme.red : root.theme.subtext
            font.family: root.theme.displayFont
            font.weight: Font.Medium
            font.pixelSize: 14
        }
    }

    Rectangle {
        visible: root.main && root.usersOpen
        anchors { horizontalCenter: parent.horizontalCenter; bottom: login.top; bottomMargin: -150 }
        width: 260
        height: userList.implicitHeight + 12
        radius: root.round(16)
        color: Qt.alpha(root.theme.base, 0.92)
        border.width: 1
        border.color: Qt.alpha(root.theme.text, 0.1)
        Column {
            id: userList
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            Repeater {
                model: root.users
                Rectangle {
                    required property var modelData
                    required property int index
                    width: userList.width
                    height: 40
                    radius: root.round(10)
                    color: index === root.userIndex ? Qt.alpha(root.theme.accent, 0.25) : um.containsMouse ? Qt.alpha(root.theme.surface, 0.8) : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        text: modelData.full + (modelData.full !== modelData.name ? "  (" + modelData.name + ")" : "")
                        color: root.theme.text
                        font.family: root.theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: um
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.userIndex = index;
                            root.usersOpen = false;
                            input.text = "";
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    Row {
        visible: root.main
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
        spacing: 10
        Chip {
            icon: "desktop_windows"
            label: root.session?.name ?? "No sessions found"
            onClicked: root.sessionsOpen = !root.sessionsOpen
        }
        Chip {
            visible: root.layout !== ""
            icon: "keyboard"
            label: root.layout.toUpperCase()
        }
    }

    Rectangle {
        visible: root.main && root.sessionsOpen
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 28; bottomMargin: 82 }
        width: 260
        height: sessionList.implicitHeight + 12
        radius: root.round(16)
        color: Qt.alpha(root.theme.base, 0.92)
        border.width: 1
        border.color: Qt.alpha(root.theme.text, 0.1)
        Column {
            id: sessionList
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
            Repeater {
                model: root.sessions
                Rectangle {
                    required property var modelData
                    required property int index
                    width: sessionList.width
                    height: 40
                    radius: root.round(10)
                    color: index === root.sessionIndex ? Qt.alpha(root.theme.accent, 0.25) : sm.containsMouse ? Qt.alpha(root.theme.surface, 0.8) : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        text: modelData.name
                        color: root.theme.text
                        font.family: root.theme.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.sessionIndex = index;
                            root.sessionsOpen = false;
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    Row {
        visible: root.main
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
        spacing: 10
        Chip { icon: "bedtime"; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
        Chip { icon: "restart_alt"; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
        Chip { icon: "power_settings_new"; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
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
            source: wall.source
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
            id: greeting
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
                radius: 60
                color: root.theme.accent
                border.width: 3
                border.color: Qt.alpha(root.theme.text, 0.25)
                Text {
                    anchors.centerIn: parent
                    visible: splashFace.status !== Image.Ready
                    text: (root.user.full || "?").charAt(0).toUpperCase()
                    color: root.theme.accentText
                    font.family: root.theme.displayFont
                    font.pixelSize: 52
                    font.weight: Font.Bold
                }
                Image {
                    id: splashFace
                    anchors.fill: parent
                    source: face.source
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
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
                    NumberAnimation { target: greeting; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: greeting; property: "anchors.verticalCenterOffset"; to: 0; duration: 320; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 160 }
                NumberAnimation { target: fade; property: "opacity"; to: 1; duration: 220; easing.type: Easing.InQuad }
            }
        }
    }
}
