import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// The Settings app: a normal window (floats centered, rules.lua) with categories on the left and
// one page at a time on the right. Super + Comma, the gear in the control center, the launcher
// entry, or `qs ipc call settings open <page|"">`. Choices are saved by Settings.qml.
// The window only exists while it's open.
Scope {
    id: root

    property bool open: false
    property string page: "appearance"

    readonly property var pages: [
        { key: "appearance", group: "Personalize", title: "Appearance", icon: "palette",
            keywords: "wallpaper colors theme dark light mode palette scheme transparency opacity", component: appearancePage },
        { key: "fonts", group: "Personalize", title: "Fonts & icons", icon: "font_download",
            keywords: "font typeface text size icons weight", component: fontsPage },
        { key: "bar", group: "Personalize", title: "Bar", icon: "toolbar",
            keywords: "bar pill height weather music spectrum clock 24 hour seconds", component: barPage },
        { key: "controlcenter", group: "Personalize", title: "Control center", icon: "dashboard_customize",
            keywords: "control center quick settings tiles widgets layout bento columns custom panel", component: controlCenterPage },
        { key: "accessibility", group: "Personalize", title: "Accessibility", icon: "accessibility_new",
            keywords: "accessibility zoom magnifier magnify larger text size bigger font reduce motion animations", component: accessibilityPage },
        { key: "windows", group: "Desktop", title: "Windows", icon: "select_window",
            keywords: "hyprland layout dwindle master scrolling gaps borders rounding corners resize", component: windowsPage },
        { key: "effects", group: "Desktop", title: "Effects", icon: "auto_awesome",
            keywords: "blur opacity transparency dim shadows animations speed workspace", component: effectsPage },
        { key: "rules", group: "Desktop", title: "Window rules", icon: "select_window",
            keywords: "window rules float floating center size workspace opacity pin fullscreen blur app class", component: rulesPage },
        { key: "input", group: "Desktop", title: "Keyboard & mouse", icon: "keyboard",
            keywords: "keyboard layout language repeat mouse pointer sensitivity acceleration touchpad tap scroll cursor", component: inputPage },
        { key: "notifications", group: "Shell", title: "Notifications", icon: "notifications",
            keywords: "notifications popups do not disturb dnd quiet hours schedule position timeout", component: notificationsPage },
        { key: "launcher", group: "Shell", title: "Launcher", icon: "apps",
            keywords: "launcher app grid columns icons most used calculator emoji clipboard projects run", component: launcherPage },
        { key: "weather", group: "Shell", title: "Weather", icon: "partly_cloudy_day",
            keywords: "weather temperature celsius fahrenheit city location forecast", component: weatherPage },
        { key: "lock", group: "Shell", title: "Lock screen", icon: "lock",
            keywords: "lock screen blur password media power rest idle", component: lockPage },
        { key: "keybinds", group: "Shell", title: "Keybindings", icon: "keyboard_command_key",
            keywords: "keybindings shortcuts keys hotkeys cheatsheet", component: keybindsPage },
        { key: "network", group: "System", title: "Network", icon: "wifi",
            keywords: "network wifi wi-fi ethernet wired vpn internet speed test", component: networkPage },
        { key: "bluetooth", group: "System", title: "Bluetooth", icon: "bluetooth",
            keywords: "bluetooth devices headphones pair", component: bluetoothPage },
        { key: "sound", group: "System", title: "Sound", icon: "volume_up",
            keywords: "sound audio volume speakers headphones microphone input output apps", component: soundPage },
        { key: "displays", group: "System", title: "Displays", icon: "monitor",
            keywords: "display monitor screen resolution refresh rate scale night light warmth", component: displaysPage },
        { key: "drives", group: "System", title: "Drives", icon: "usb",
            keywords: "drives usb stick flash sd card disk image iso mount eject automount removable", component: drivesPage },
        { key: "datetime", group: "System", title: "Date & time", icon: "schedule",
            keywords: "date time clock timezone time zone ntp sync 24 hour format week calendar world clocks", component: dateTimePage },
        { key: "power", group: "System", title: "Power", icon: "battery_android_frame_5",
            keywords: "power battery charge limit profile performance idle dim lock sleep suspend screen off keep awake", component: powerPage },
        { key: "apps", group: "System", title: "Default apps", icon: "apps",
            keywords: "default apps browser terminal files editor mail pictures video music pdf open with", component: defaultAppsPage },
        { key: "startup", group: "System", title: "Startup apps", icon: "rocket_launch",
            keywords: "startup autostart login apps commands", component: startupPage },
        { key: "updates", group: "System", title: "Updates", icon: "system_update_alt",
            keywords: "updates upgrade pikadots dotfiles git pull packages pacman aur flatpak", component: updatesPage },
        { key: "about", group: "System", title: "About", icon: "info",
            keywords: "about version system hyprland quickshell kernel memory cpu", component: aboutPage }
    ]

    // Pages that need hardware this machine may not have
    function available(key) {
        return key !== "bluetooth" || Bluetooth.defaultAdapter !== null;
    }

    function show(key) {
        if (key && pages.some(p => p.key === key))
            page = key;
        if (open)
            Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ window = "title:^Settings$" })']);
        open = true;
    }

    Connections {
        target: Settings
        function onOpenRequested(key) {
            root.show(key);
        }
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            id: window
            title: "Settings"
            implicitWidth: 1040
            implicitHeight: 720
            minimumSize: Qt.size(780, 520)
            color: Qt.alpha(Theme.base, 0.94)
            onClosed: root.open = false

            // Pages matching the search (all of them while it's empty)
            readonly property var shownPages: {
                const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
                return root.pages.filter(p => root.available(p.key) && words.every(w => (p.title + " " + p.keywords).toLowerCase().includes(w)));
            }

            // Individual settings matching the search: { key, page, title, row }
            property var hits: []
            readonly property bool searching: search.text.trim() !== ""

            function collectRows(item, out) {
                for (const child of item.children) {
                    if (child.objectName === "settingsRow" && child.title)
                        out.push(child);
                    collectRows(child, out);
                }
            }

            function findHits() {
                const words = search.text.toLowerCase().split(/\s+/).filter(w => w);
                const out = [];
                if (words.length) {
                    for (let i = 0; i < pageRepeater.count; i++) {
                        const flick = pageRepeater.itemAt(i);
                        if (!flick?.page || !root.available(flick.modelData.key))
                            continue;
                        const rows = [];
                        collectRows(flick.page, rows);
                        for (const row of rows) {
                            const text = (row.title + " " + row.description).toLowerCase();
                            if (words.every(w => text.includes(w)))
                                out.push({ key: flick.modelData.key, page: flick.modelData.title, title: row.title, row: row, flick: flick });
                        }
                    }
                }
                hits = out.slice(0, 8);
            }

            // Opens the hit's page, scrolls its row into view and makes it glow
            function jump(hit) {
                root.page = hit.key;
                pendingHit = hit;
                jumpTimer.restart();
            }
            property var pendingHit: null

            Timer {
                id: hitTimer
                // Lets pages built for the search finish loading
                interval: 120
                onTriggered: window.findHits()
            }
            Timer {
                id: jumpTimer
                interval: 60
                onTriggered: {
                    const hit = window.pendingHit;
                    if (!hit)
                        return;
                    const y = hit.row.mapToItem(hit.flick.contentItem, 0, 0).y;
                    hit.flick.contentY = Math.max(0, Math.min(hit.flick.contentHeight - hit.flick.height, y - 80));
                    hit.row.flash();
                }
            }

            function step(delta) {
                const list = shownPages.length ? shownPages : root.pages;
                const i = list.findIndex(p => p.key === root.page);
                root.page = list[(i + delta + list.length) % list.length].key;
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (search.text !== "")
                            search.text = "";
                        else
                            root.open = false;
                    } else if (event.key === Qt.Key_F && event.modifiers & Qt.ControlModifier) {
                        search.forceActiveFocus();
                    } else if (event.key === Qt.Key_Tab && event.modifiers & Qt.ControlModifier) {
                        window.step(1);
                    } else if (event.key === Qt.Key_Backtab && event.modifiers & Qt.ControlModifier) {
                        window.step(-1);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                // Sidebar
                Rectangle {
                    id: sidebar
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
                    width: 264
                    color: Qt.alpha(Theme.surface, 0.3)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        anchors.topMargin: 22
                        spacing: 4

                        // App title
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            Layout.bottomMargin: 14
                            spacing: 12

                            Rectangle {
                                implicitWidth: 42
                                implicitHeight: 42
                                radius: 14
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.lighter(Theme.accent, 1.15) }
                                    GradientStop { position: 1; color: Qt.darker(Theme.accent, 1.2) }
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    name: "tune"
                                    size: 24
                                    weight: 500
                                    color: Theme.accentText
                                }
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "Settings"
                                    color: Theme.text
                                    font.family: Theme.displayFont
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                }
                                Label {
                                    text: "pikadots"
                                    color: Theme.subtext
                                    font.pixelSize: Theme.fontSize - 2
                                }
                            }
                        }

                        // Search
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 10
                            implicitHeight: 38
                            radius: 12
                            color: Qt.alpha(Theme.base, 0.7)
                            border.width: search.activeFocus ? 1 : 0
                            border.color: Theme.accent

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Icon { name: "search"; size: 18; color: Theme.subtext }
                                TextInput {
                                    id: search
                                    Layout.fillWidth: true
                                    color: Theme.text
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                    selectionColor: Theme.accent
                                    selectedTextColor: Theme.accentText
                                    clip: true
                                    // The first match opens as you type
                                    onTextChanged: {
                                        if (window.shownPages.length && !window.shownPages.some(p => p.key === root.page))
                                            root.page = window.shownPages[0].key;
                                        hitTimer.restart();
                                    }
                                    // Enter jumps to the first matching setting
                                    Keys.onReturnPressed: if (window.hits.length) window.jump(window.hits[0])
                                    Keys.onDownPressed: window.step(1)
                                    Keys.onUpPressed: window.step(-1)

                                    Label {
                                        visible: !search.text
                                        text: "Search settings"
                                        color: Theme.overlay
                                    }
                                }
                            }
                        }

                        // Categories, under their group names; scrolls when the window is short
                        Flickable {
                            id: categoryFlick
                            Component.onCompleted: revealTimer.restart()
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: categories.implicitHeight

                            // Keeps the current page's row in view
                            Timer {
                                id: revealTimer
                                interval: 30
                                onTriggered: {
                                    for (const item of categories.children)
                                        if (item.current)
                                            categoryFlick.reveal(item);
                                }
                            }
                            Connections {
                                target: root
                                function onPageChanged() {
                                    revealTimer.restart();
                                }
                            }

                            function reveal(item) {
                                const y = item.mapToItem(categories, 0, 0).y;
                                if (y < contentY)
                                    contentY = y;
                                else if (y + item.height > contentY + height)
                                    contentY = Math.min(contentHeight - height, y + item.height - height);
                            }
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: categories
                                width: parent.width
                                spacing: 4

                                // Matching settings, above the matching pages
                                Label {
                                    visible: window.hits.length > 0
                                    Layout.leftMargin: 12
                                    Layout.bottomMargin: 2
                                    text: "SETTINGS"
                                    color: Theme.overlay
                                    font.pixelSize: Theme.fontSize - 3
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }
                                Repeater {
                                    model: window.hits

                                    Rectangle {
                                        id: hitRow
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        implicitHeight: hitColumn.implicitHeight + 14
                                        radius: 12
                                        color: hitMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8)
                                            : index === 0 ? Qt.alpha(Theme.accent, 0.12) : "transparent"

                                        ColumnLayout {
                                            id: hitColumn
                                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                                            spacing: 0
                                            Label {
                                                Layout.fillWidth: true
                                                text: hitRow.modelData.title
                                                elide: Text.ElideRight
                                            }
                                            Label {
                                                Layout.fillWidth: true
                                                text: hitRow.modelData.page + (hitRow.index === 0 ? "  ·  ↵" : "")
                                                color: Theme.accent
                                                font.pixelSize: Theme.fontSize - 3
                                                elide: Text.ElideRight
                                            }
                                        }
                                        MouseArea {
                                            id: hitMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: window.jump(hitRow.modelData)
                                        }
                                    }
                                }
                                Item {
                                    visible: window.hits.length > 0
                                    implicitHeight: 8
                                }

                                Repeater {
                                    model: window.shownPages

                                    ColumnLayout {
                                        id: entry
                                        required property var modelData
                                        required property int index
                                        readonly property bool current: root.page === modelData.key
                                        readonly property bool firstInGroup: index === 0 || window.shownPages[index - 1].group !== modelData.group

                                        Layout.fillWidth: true
                                        spacing: 4

                                        Label {
                                            visible: entry.firstInGroup
                                            Layout.leftMargin: 12
                                            Layout.topMargin: entry.index === 0 ? 0 : 12
                                            Layout.bottomMargin: 2
                                            text: entry.modelData.group.toUpperCase()
                                            color: Theme.overlay
                                            font.pixelSize: Theme.fontSize - 3
                                            font.bold: true
                                            font.letterSpacing: 1.2
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 38
                                            radius: 13
                                            color: entry.current ? Theme.accent
                                                : rowMouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
                                            Behavior on color { ColorAnimation { duration: Theme.ms(140) } }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 12
                                                spacing: 12

                                                Rectangle {
                                                    implicitWidth: 28
                                                    implicitHeight: 28
                                                    radius: 9
                                                    color: entry.current ? Qt.alpha(Theme.accentText, 0.14) : Qt.alpha(Theme.accent, 0.16)
                                                    Icon {
                                                        anchors.centerIn: parent
                                                        name: entry.modelData.icon
                                                        size: 18
                                                        filled: entry.current
                                                        color: entry.current ? Theme.accentText : Theme.accent
                                                    }
                                                }
                                                Label {
                                                    Layout.fillWidth: true
                                                    text: entry.modelData.title
                                                    color: entry.current ? Theme.accentText : Theme.text
                                                    font.weight: entry.current ? Font.DemiBold : Font.Normal
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: rowMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.page = entry.modelData.key
                                            }
                                        }
                                    }
                                }

                                Label {
                                    visible: window.shownPages.length === 0 && window.hits.length === 0
                                    Layout.leftMargin: 12
                                    text: "Nothing matches"
                                    color: Theme.subtext
                                }
                            }
                        }


                        Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.topMargin: 8
                            wrapMode: Text.WordWrap
                            text: "ctrl+f search · esc close"
                            color: Theme.overlay
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }

                // Pages; each is built the first time it's opened and keeps its scroll position
                Item {
                    anchors { top: parent.top; bottom: parent.bottom; left: sidebar.right; right: parent.right }

                    Repeater {
                        id: pageRepeater
                        model: root.pages

                        Flickable {
                            id: flick
                            readonly property Item page: loader.item
                            required property var modelData
                            readonly property bool current: root.page === modelData.key
                            property bool visited: false
                            onCurrentChanged: if (current) visited = true
                            Component.onCompleted: visited = current
                            // Searching builds every page so its settings can be found
                            Connections {
                                target: window
                                function onSearchingChanged() {
                                    if (window.searching)
                                        flick.visited = true;
                                }
                            }

                            anchors.fill: parent
                            opacity: current ? 1 : 0
                            visible: opacity > 0
                            transform: Translate {
                                y: flick.current ? 0 : 12
                                Behavior on y { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutQuint } }
                            }
                            Behavior on opacity { NumberAnimation { duration: Theme.ms(flick.current ? 220 : 70) } }
                            clip: true
                            contentWidth: width
                            contentHeight: loader.height + 72
                            boundsBehavior: Flickable.StopAtBounds

                            Loader {
                                id: loader
                                active: flick.visited
                                x: 40
                                y: 36
                                // Readable line length on wide windows
                                width: Math.min(flick.width - 80, 820)
                                height: item?.implicitHeight ?? 0
                                sourceComponent: flick.modelData.component
                            }
                            Binding {
                                target: loader.item
                                property: "shown"
                                value: flick.current
                            }
                        }
                    }
                }
            }
        }
    }

    Component { id: appearancePage; SettingsAppearancePage {} }
    Component { id: fontsPage; SettingsFontsPage {} }
    Component { id: barPage; SettingsBarPage {} }
    Component { id: controlCenterPage; SettingsControlCenterPage {} }
    Component { id: windowsPage; SettingsWindowsPage {} }
    Component { id: effectsPage; SettingsEffectsPage {} }
    Component { id: inputPage; SettingsInputPage {} }
    Component { id: notificationsPage; SettingsNotificationsPage {} }
    Component { id: launcherPage; SettingsLauncherPage {} }
    Component { id: weatherPage; SettingsWeatherPage {} }
    Component { id: lockPage; SettingsLockPage {} }
    Component { id: keybindsPage; SettingsKeybindsPage {} }
    Component { id: networkPage; SettingsNetworkPage {} }
    Component { id: bluetoothPage; SettingsBluetoothPage {} }
    Component { id: rulesPage; SettingsWindowRulesPage {} }
    Component { id: accessibilityPage; SettingsAccessibilityPage {} }
    Component { id: drivesPage; SettingsDrivesPage {} }
    Component { id: soundPage; SettingsSoundPage {} }
    Component { id: displaysPage; SettingsDisplaysPage {} }
    Component { id: powerPage; SettingsPowerPage {} }
    Component { id: defaultAppsPage; SettingsDefaultAppsPage {} }
    Component { id: startupPage; SettingsStartupPage {} }
    Component { id: dateTimePage; SettingsDateTimePage {} }
    Component { id: updatesPage; SettingsUpdatesPage {} }
    Component { id: aboutPage; SettingsAboutPage {} }
}
