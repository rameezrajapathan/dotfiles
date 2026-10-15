import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// One window, centered under the bar's profile picture, holding everything that used to sit on the
// right of the bar as tabs: account (with quick settings), music, notifications, network, Bluetooth, sound,
// displays, drives (while one is plugged in), battery, system, capture and GitHub. The sidebar also has the tray and background apps,
// the wallpaper picker and the power menu. Works from the keyboard alone (Super + S opens it): Esc
// or a click outside closes it; Up/Down, Tab, Ctrl+Tab or J/K switch tabs, 1–9/0 jump. A
// transparent full-screen overlay.
PanelWindow {
    id: root

    // Closes the other panels when this one opens, and the other way round
    Exclusive { panel: root }
    required property var bar
    property string tab: "account"
    // The window stays mapped until the close animation ends
    property bool open: false

    readonly property var tabs: [
        { key: "account", title: "Account", page: accountPage },
        { key: "music", title: "Music", page: musicPage },
        { key: "notifications", title: "Notifications", page: notificationsPage },
        { key: "network", title: "Network", page: networkPage },
        { key: "bluetooth", title: "Bluetooth", page: bluetoothPage },
        { key: "audio", title: "Sound", page: audioPage },
        { key: "display", title: "Displays", page: displayPage },
        { key: "drives", title: "Drives", page: drivesPage },
        { key: "battery", title: "Battery", page: batteryPage },
        { key: "system", title: "System", page: systemPage },
        { key: "capture", title: "Capture", page: capturePage },
        { key: "github", title: "GitHub", page: gitHubPage }
    ]

    // State for the sidebar's icons and badges (StatusInfo.qml, shared with the bar's icons)
    readonly property var btAdapter: StatusInfo.btAdapter
    readonly property var sink: StatusInfo.sink
    readonly property var battery: StatusInfo.battery

    function available(key) {
        switch (key) {
        case "bluetooth": return btAdapter !== null;
        case "battery": return battery.isLaptopBattery;
        case "github": return GitHub.signedIn;
        case "drives": return Drives.volumes.length > 0;
        default: return true;
        }
    }

    function icon(key) {
        return StatusInfo.icon(key);
    }

    // Short text at the end of a tab row
    function detail(key) {
        return StatusInfo.detail(key);
    }

    function count(key) {
        switch (key) {
        case "notifications": return NotificationService.list.length;
        case "github": return GitHub.unread;
        }
        return 0;
    }

    function show(key) {
        if (key)
            tab = key;
        visible = true;
        open = true;
    }

    function close() {
        open = false;
    }

    // Opens on `key` (or the last tab); a second call for the tab already shown closes it
    function toggle(key) {
        if (open && (!key || key === tab))
            close();
        else
            show(key);
    }

    // Tabs available on this machine, in sidebar order
    function shownTabs() {
        return tabs.filter(t => available(t.key));
    }

    function jump(index) {
        const shown = shownTabs();
        if (index < shown.length)
            tab = shown[index].key;
    }

    function step(delta) {
        const shown = shownTabs();
        const i = shown.findIndex(t => t.key === tab);
        tab = shown[(i + delta + shown.length) % shown.length].key;
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-controlcenter"
    // Takes the keyboard while open so it works without the mouse; prompts it starts (Wi-Fi
    // password, VPN removal) close it first so they can have the keyboard
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // Drops down from under the bar, like the launcher
    Sheet {
        id: card
        open: root.open
        kind: "settings"
        // Comes out of the tab's own bar icon when it's on the bar, else the profile picture
        anchorIds: (({ audio: ["sound"], music: ["media"], capture: ["capture", "recording"] })[root.tab] ?? [root.tab]).concat(["avatar"])
        sheetWidth: Math.min(860, root.width - 56)
        sheetHeight: Math.min(640, root.height - Theme.barHeight - 20)
        // More opaque than the bar: it's large and full of text
        color: Qt.alpha(Theme.base, 0.92)
        onClosed: root.visible = false
        onDismiss: root.close()

        // Clips the sidebar and pages to the sheet's rounded corners
        ClippingRectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"

            Item {
                anchors.fill: parent

                Item {
                    anchors.fill: parent
                    focus: root.open

                    // Esc closes; Up/Down, Tab/Shift+Tab, Ctrl+Tab or J/K move between tabs;
                    // 1–9 and 0 jump to a tab (in sidebar order)
                    Keys.onEscapePressed: root.close()
                    Keys.onUpPressed: root.step(-1)
                    Keys.onDownPressed: root.step(1)
                    Keys.onTabPressed: root.step(1)
                    Keys.onBacktabPressed: root.step(-1)
                    Keys.onPressed: event => {
                        const n = "1234567890".indexOf(event.text);
                        if (event.text !== "" && n >= 0) {
                            root.jump(n);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_J) {
                            root.step(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_K) {
                            root.step(-1);
                            event.accepted = true;
                        }
                    }
                }

                // Sidebar
                Rectangle {
                    id: sidebar
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                    width: 220
                    color: Qt.alpha(Theme.surface, 0.35)

                    // Selected-tab highlight; glides from tab to tab
                    Rectangle {
                        readonly property Item target: {
                            tabRepeater.count;
                            return tabRepeater.itemAt(root.tabs.findIndex(t => t.key === root.tab));
                        }
                        x: tabColumn.x
                        y: tabColumn.y + (target?.y ?? 0)
                        width: tabColumn.width
                        height: target?.height ?? 0
                        radius: 12
                        color: Theme.accent
                        Behavior on y { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutQuint } }
                    }

                    ColumnLayout {
                        id: tabColumn
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 2

                        Repeater {
                            id: tabRepeater
                            model: root.tabs

                            Rectangle {
                                id: tabRow
                                required property var modelData
                                readonly property string key: modelData.key
                                readonly property bool current: root.tab === key
                                readonly property int badge: root.count(key)

                                visible: root.available(key)
                                Layout.fillWidth: true
                                implicitHeight: 38
                                radius: 12
                                color: !current && tabMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    Icon {
                                        name: root.icon(tabRow.key)
                                        filled: tabRow.current
                                        size: 20
                                        color: tabRow.current ? Theme.accentText
                                            : tabRow.key === "capture" && Recorder.active ? Theme.red
                                            : Theme.text
                                        Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: tabRow.modelData.title
                                        color: tabRow.current ? Theme.accentText : Theme.text
                                        font.bold: tabRow.current
                                        Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        visible: text !== "" && tabRow.badge === 0
                                        Layout.maximumWidth: 80
                                        text: root.detail(tabRow.key)
                                        color: tabRow.current ? Qt.alpha(Theme.accentText, 0.75) : Theme.subtext
                                        font.pixelSize: Theme.fontSize - 2
                                        elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        visible: tabRow.badge > 0
                                        implicitWidth: Math.max(20, badgeLabel.implicitWidth + 10)
                                        implicitHeight: 18
                                        radius: 9
                                        color: tabRow.current ? Theme.accentText : Theme.accent

                                        Label {
                                            id: badgeLabel
                                            anchors.centerIn: parent
                                            text: tabRow.badge > 99 ? "99+" : tabRow.badge
                                            color: tabRow.current ? Theme.accent : Theme.accentText
                                            font.pixelSize: Theme.fontSize - 3
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    // Right click: the old bar shortcuts (mute, Bluetooth power, Do Not Disturb, play/pause)
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) {
                                            root.tab = tabRow.key;
                                        } else if (tabRow.key === "audio" && root.sink?.audio) {
                                            root.sink.audio.muted = !root.sink.audio.muted;
                                        } else if (tabRow.key === "bluetooth" && root.btAdapter) {
                                            root.btAdapter.enabled = !root.btAdapter.enabled;
                                        } else if (tabRow.key === "notifications") {
                                            NotificationService.dnd = !NotificationService.dnd;
                                        } else if (tabRow.key === "music" && Media.active?.canTogglePlaying) {
                                            Media.active.togglePlaying();
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Keyboard hints
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 12
                    text: "↑↓ tabs   1–9 jump   esc close"
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                }

                // Tray icons and hidden background apps
                        Flow {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.bottomMargin: 10
                            visible: SystemTray.items.values.length > 0 || backgroundApps.count > 0
                            spacing: 14

                            BackgroundApps { id: backgroundApps; bar: root }
                            Tray { bar: root }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 8
                            implicitHeight: 1
                            color: Qt.alpha(Theme.overlay, 0.4)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            FooterButton {
                                icon: "settings"
                                onClicked: {
                                    root.close();
                                    Settings.openRequested("");
                                }
                            }
                            FooterButton {
                                icon: "palette"
                                onClicked: {
                                    root.close();
                                    Quickshell.execDetached(["qs", "ipc", "call", "wallpaper", "toggle"]);
                                }
                            }
                            FooterButton {
                                visible: Toggles.keepAwake
                                icon: "coffee"
                                active: true
                                onClicked: Toggles.keepAwake = false
                            }
                            Item { Layout.fillWidth: true }
                            FooterButton {
                                icon: "power_settings_new"
                                danger: true
                                onClicked: {
                                    root.close();
                                    Quickshell.execDetached(["qs", "ipc", "call", "power", "toggle"]);
                                }
                            }
                        }
                    }
                }

                // Pages; each keeps its own scroll position
                Item {
                    id: pages
                    anchors { top: parent.top; bottom: parent.bottom; left: sidebar.right; right: parent.right }

                    Repeater {
                        model: root.tabs

                        Flickable {
                            id: flick
                            required property var modelData
                            readonly property bool current: root.tab === modelData.key

                            anchors.fill: parent
                            // Crossfade, with a small rise, when switching tabs
                            opacity: current ? 1 : 0
                            visible: opacity > 0
                            transform: Translate {
                                y: flick.current ? 0 : 10
                                Behavior on y { NumberAnimation { duration: Theme.ms(220); easing.type: Easing.OutQuint } }
                            }
                            // The old page goes quickly so the two barely overlap
                            Behavior on opacity { NumberAnimation { duration: Theme.ms(flick.current ? 220 : 70) } }
                            clip: true
                            contentWidth: width
                            contentHeight: loader.height
                            boundsBehavior: Flickable.StopAtBounds

                            Loader {
                                id: loader
                                width: flick.width
                                height: Math.max(item?.implicitHeight ?? 0, flick.height)
                                sourceComponent: flick.modelData.page
                            }
                            Binding {
                                target: loader.item
                                property: "shown"
                                value: root.open && flick.current
                            }
                            Connections {
                                target: loader.item
                                function onCloseRequested() {
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component { id: musicPage; MediaPanel {} }
    Component { id: notificationsPage; NotificationPanel {} }
    Component { id: networkPage; NetworkPanel {} }
    Component { id: bluetoothPage; BluetoothPanel {} }
    Component { id: audioPage; AudioPanel {} }
    Component { id: displayPage; DisplayPanel {} }
    Component { id: drivesPage; DrivesPanel {} }
    Component { id: batteryPage; BatteryPanel {} }
    Component { id: systemPage; SystemPanel {} }
    Component { id: capturePage; CapturePanel {} }
    Component { id: gitHubPage; GitHubPanel {} }
    Component { id: accountPage; AccountPanel {} }

    component FooterButton: Rectangle {
        id: button
        property string icon
        property bool active: false
        property bool danger: false
        signal clicked()

        implicitWidth: 36
        implicitHeight: 36
        radius: 12
        color: active ? Qt.alpha(Theme.accent, 0.25)
            : mouse.containsMouse ? (danger ? Qt.alpha(Theme.red, 0.2) : Qt.alpha(Theme.surface, 0.8))
            : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

        Icon {
            anchors.centerIn: parent
            name: button.icon
            filled: button.active
            color: button.active ? Theme.accent : button.danger && mouse.containsMouse ? Theme.red : Theme.text
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
