import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

PanelWindow {
    id: root

    readonly property string mark: Quickshell.env("HOME") + "/.local/state/pikadots/setup-done"
    readonly property string wallpapers: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property var steps: [
        { id: "welcome", title: "Welcome" },
        { id: "wallpaper", title: "Wallpaper" },
        { id: "bar", title: "Bar" },
        { id: "dock", title: "Dock" },
        { id: "widgets", title: "Widgets" },
        { id: "account", title: "You" },
        { id: "keys", title: "Keys" },
        { id: "done", title: "Done" }
    ]
    readonly property string stepId: steps[step].id
    readonly property var tips: [
        { desc: "Open app launcher", fallback: "Super + A", icon: "apps", text: "Find and open apps, files, emoji, the calculator and your clipboard" },
        { desc: "Open settings (control center)", fallback: "Super + S", icon: "dashboard_customize", text: "Wi-Fi, Bluetooth, sound, music and notifications" },
        { desc: "Switch workspaces (hold Super)", fallback: "Super + Tab", icon: "view_carousel", text: "See every workspace and window at once" },
        { desc: "Show desktop widgets", fallback: "Super + H", icon: "widgets", text: "Bring your desktop widgets in front of the windows" },
        { desc: "Pick wallpaper", fallback: "Super + Shift + W", icon: "wallpaper", text: "Change the wallpaper, and the colors with it" },
        { desc: "Show keybindings", fallback: "Super + Shift + /", icon: "keyboard_command_key", text: "Every shortcut, searchable" }
    ]

    property bool open: false
    property int step: 0
    property bool starter: true
    property string wallpaper: ""

    function keysFor(t) {
        const b = Keybinds.binds.find(b => b.desc === t.desc);
        return b ? b.keys.join(" + ") : t.fallback;
    }

    function show() {
        step = 0;
        starter = Desktop.layout(Desktop.focusedScreen).length === 0;
        Keybinds.refresh();
        visible = true;
        open = true;
    }

    function finish() {
        if (starter && Settings.desktop.enabled)
            Desktop.addStarter(Desktop.focusedScreen);
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && touch "$1"', "sh", mark]);
        open = false;
    }

    function next() {
        if (step < steps.length - 1)
            step++;
        else
            finish();
    }

    Process {
        running: true
        command: ["sh", "-c", 'if [ -e "$1" ]; then echo done; elif [ -e "$2" ]; then mkdir -p "${1%/*}" && touch "$1"; echo done; else echo new; fi',
            "sh", root.mark, Settings.path]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() === "new") root.show()
        }
    }

    IpcHandler {
        target: "setup"
        function open(): void {
            root.show();
        }
        function next(): void {
            if (root.open)
                root.next();
        }
    }

    Exclusive { panel: root }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-setup"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    visible: false

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(260) } }
        onOpacityChanged: if (opacity === 0 && !root.open) root.visible = false
    }

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 940)
        height: Math.min(parent.height - 64, 640)
        radius: Theme.round(30, width, height)
        color: Theme.denseTranslucent
        border.width: Glass.active ? 0 : 1
        border.color: Qt.alpha(Theme.text, 0.1)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: Theme.ms(220) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutCubic } }
        GlassRim {}

        Item {
            anchors.fill: parent
            focus: root.open
            Keys.onEscapePressed: root.finish()
            Keys.onReturnPressed: root.next()
            Keys.onRightPressed: root.next()
            Keys.onLeftPressed: if (root.step > 0) root.step--
        }

        ColumnLayout {
            anchors { fill: parent; margins: 32 }
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: root.steps
                    Rectangle {
                        required property int index
                        implicitWidth: index === root.step ? 26 : 8
                        implicitHeight: 8
                        radius: 4
                        color: index <= root.step ? Theme.accent : Qt.alpha(Theme.text, 0.15)
                        Behavior on implicitWidth { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
                    }
                }
                Item { Layout.fillWidth: true }
                Label {
                    visible: root.step > 0 && root.stepId !== "done"
                    text: "Skip setup"
                    color: skipMouse.containsMouse ? Theme.text : Theme.overlay
                    MouseArea {
                        id: skipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.finish()
                    }
                }
            }

            Loader {
                id: page
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: ({
                    welcome: welcomePage, wallpaper: wallpaperPage, bar: barPage, dock: dockPage,
                    widgets: widgetsPage, account: accountPage, keys: keysPage, done: donePage
                })[root.stepId]
                opacity: 0
                onLoaded: fade.restart()
                NumberAnimation { id: fade; target: page; property: "opacity"; from: 0; to: 1; duration: Theme.ms(220) }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Pill {
                    visible: root.step > 0
                    text: "Back"
                    implicitHeight: 40
                    onClicked: root.step--
                }
                Item { Layout.fillWidth: true }
                Pill {
                    visible: root.stepId !== "welcome" && root.stepId !== "done"
                    text: "Skip this step"
                    implicitHeight: 40
                    onClicked: root.step++
                }
                Pill {
                    text: root.stepId === "welcome" ? "Get started" : root.stepId === "done" ? "Start using Pikadots" : "Next"
                    active: true
                    implicitHeight: 40
                    onClicked: root.next()
                }
            }
        }
    }

    component Heading: ColumnLayout {
        property string title
        property string subtitle
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: parent.title
            color: Theme.text
            font.family: Theme.displayFont
            font.pixelSize: 30
            font.weight: Font.Bold
        }
        Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: parent.subtitle
            color: Theme.subtext
            font.pixelSize: Theme.fontSize + 1
            wrapMode: Text.WordWrap
        }
    }

    component Choice: Rectangle {
        id: choice
        property string icon
        property string title
        property string subtitle
        property bool selected: false
        signal clicked()
        implicitHeight: 76
        radius: Theme.round(18, width, height)
        color: selected ? Qt.alpha(Theme.accent, 0.18) : mouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : Qt.alpha(Theme.surface, 0.45)
        border.width: selected ? 2 : 0
        border.color: Theme.accent
        RowLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            spacing: 14
            Icon {
                name: choice.icon
                size: 26
                color: choice.selected ? Theme.accent : Theme.subtext
                filled: choice.selected
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { text: choice.title; font.weight: Font.DemiBold }
                Label {
                    Layout.fillWidth: true
                    text: choice.subtitle
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 1
                    elide: Text.ElideRight
                }
            }
            Icon {
                visible: choice.selected
                name: "check_circle"
                filled: true
                size: 22
                color: Theme.accent
            }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: choice.clicked()
        }
    }

    Component {
        id: welcomePage
        ColumnLayout {
            spacing: 18
            Item { Layout.fillHeight: true }
            ClippingRectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 112
                implicitHeight: 112
                radius: 56
                color: Theme.accent
                Icon {
                    anchors.centerIn: parent
                    visible: User.avatar === ""
                    name: "waving_hand"
                    size: 56
                    filled: true
                    color: Theme.accentText
                }
                Image {
                    anchors.fill: parent
                    visible: User.avatar !== ""
                    source: User.avatar
                    fillMode: Image.PreserveAspectCrop
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome, " + User.displayName.split(" ")[0]
                color: Theme.text
                font.family: Theme.displayFont
                font.pixelSize: 40
                font.weight: Font.Bold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 560
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Let's make this desktop yours. A few quick choices: a wallpaper, how the bar and dock look, some widgets and your picture. Everything can be changed later in Settings (Super + ,)."
                color: Theme.subtext
                font.pixelSize: Theme.fontSize + 1
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: wallpaperPage
        ColumnLayout {
            spacing: 16
            Heading {
                title: "Pick a wallpaper"
                subtitle: "The colors of the whole desktop follow it."
            }
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / 4)
                cellHeight: Math.round(cellWidth * 0.62)
                boundsBehavior: Flickable.StopAtBounds
                model: FolderListModel {
                    folder: root.visible ? "file://" + root.wallpapers : ""
                    nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
                    showDirs: false
                }
                delegate: Item {
                    id: cell
                    required property string filePath
                    readonly property bool chosen: root.wallpaper === filePath
                    width: grid.cellWidth
                    height: grid.cellHeight
                    ClippingRectangle {
                        anchors { fill: parent; margins: 5 }
                        radius: Theme.round(14, width, height)
                        color: Qt.alpha(Theme.surface, 0.5)
                        border.width: cell.chosen ? 3 : 0
                        border.color: Theme.accent
                        Image {
                            anchors.fill: parent
                            source: "file://" + cell.filePath
                            sourceSize.width: 320
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.wallpaper = cell.filePath;
                                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/theme.sh", cell.filePath]);
                            }
                        }
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: grid.count === 0
                    text: "No wallpapers in ~/Pictures/Wallpapers yet. You can add some later with Super + Shift + W."
                    color: Theme.overlay
                }
            }
        }
    }

    Component {
        id: barPage
        ColumnLayout {
            spacing: 16
            Heading {
                title: "Choose a bar"
                subtitle: "From one small pill to a classic full-width bar. Settings > Bar has more."
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: BarStyles.presets.slice(0, 8)
                    Choice {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: modelData.icon
                        title: modelData.label
                        subtitle: modelData.description
                        selected: BarStyles.current === modelData.id
                        onClicked: BarStyles.apply(modelData.id)
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: dockPage
        ColumnLayout {
            spacing: 16
            Heading {
                title: "A dock for your apps?"
                subtitle: "Pinned apps and the ones you have open, on a screen edge of their own."
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Choice {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "dock_to_bottom"
                    title: "Show the dock"
                    subtitle: "Click to open and switch apps"
                    selected: Settings.dock.enabled
                    onClicked: Settings.dock.enabled = true
                }
                Choice {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "do_not_disturb_on"
                    title: "No dock"
                    subtitle: "Use the launcher and the overview"
                    selected: !Settings.dock.enabled
                    onClicked: Settings.dock.enabled = false
                }
            }
            Label {
                visible: Settings.dock.enabled
                Layout.topMargin: 6
                text: "Where should it go?"
                font.weight: Font.DemiBold
            }
            RowLayout {
                visible: Settings.dock.enabled
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        { value: "bottom", label: "Bottom", icon: "vertical_align_bottom" },
                        { value: "left", label: "Left", icon: "align_horizontal_left" },
                        { value: "right", label: "Right", icon: "align_horizontal_right" }
                    ].filter(o => o.value !== Theme.barPosition)
                    Choice {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: modelData.icon
                        title: modelData.label
                        selected: Dock.edge === modelData.value
                        onClicked: Settings.dock.position = modelData.value
                    }
                }
            }
            RowLayout {
                visible: Settings.dock.enabled
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: [
                        { value: "always", label: "Always there", text: "Windows make room for it" },
                        { value: "intellihide", label: "Out of the way", text: "Hides when a window touches it" },
                        { value: "autohide", label: "Hidden", text: "Point at the edge to show it" }
                    ]
                    Choice {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: modelData.value === "always" ? "push_pin" : modelData.value === "intellihide" ? "auto_awesome" : "visibility_off"
                        title: modelData.label
                        subtitle: modelData.text
                        selected: Dock.mode === modelData.value
                        onClicked: Settings.dock.mode = modelData.value
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: widgetsPage
        ColumnLayout {
            spacing: 16
            Heading {
                title: "Widgets on your desktop"
                subtitle: "Cards that sit on the wallpaper behind your windows: a clock, the weather, your calendar, what's playing. Super + H brings them forward."
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Choice {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "auto_awesome"
                    title: "Add a few to start"
                    subtitle: "Clock, weather, calendar and now playing"
                    selected: Settings.desktop.enabled && root.starter
                    onClicked: {
                        Settings.desktop.enabled = true;
                        root.starter = true;
                    }
                }
                Choice {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "crop_free"
                    title: "Keep it clean"
                    subtitle: "Add widgets later with a right click on the desktop"
                    selected: Settings.desktop.enabled && !root.starter
                    onClicked: {
                        Settings.desktop.enabled = true;
                        root.starter = false;
                    }
                }
                Choice {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "block"
                    title: "No widgets"
                    subtitle: "Turn them off. Settings > Desktop brings them back"
                    selected: !Settings.desktop.enabled
                    onClicked: Settings.desktop.enabled = false
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: accountPage
        ColumnLayout {
            spacing: 16
            Heading {
                title: "Add your picture"
                subtitle: "It shows in the bar, the control center and on the lock screen."
            }
            Item { Layout.fillHeight: true }
            ClippingRectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 150
                implicitHeight: 150
                radius: 75
                color: Qt.alpha(Theme.surface, 0.8)
                Icon {
                    anchors.centerIn: parent
                    visible: User.avatar === ""
                    name: "person"
                    size: 72
                    color: Theme.overlay
                }
                Image {
                    anchors.fill: parent
                    visible: User.avatar !== ""
                    source: User.avatar
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: User.choosePicture()
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: User.displayName
                font.pixelSize: Theme.fontSize + 4
                font.weight: Font.Bold
            }
            Pill {
                Layout.alignment: Qt.AlignHCenter
                text: User.avatar ? "Choose another picture" : "Choose a picture"
                implicitHeight: 38
                onClicked: User.choosePicture()
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: keysPage
        ColumnLayout {
            spacing: 16
            Heading {
                title: "Six keys worth knowing"
                subtitle: "Super is the Windows key. The full list is one shortcut away."
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10
                Repeater {
                    model: root.tips
                    Rectangle {
                        id: tip
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 84
                        radius: Theme.round(18, width, height)
                        color: Qt.alpha(Theme.surface, 0.45)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            spacing: 14
                            Icon {
                                name: tip.modelData.icon
                                size: 26
                                color: Theme.accent
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Rectangle {
                                    implicitWidth: keyLabel.implicitWidth + 16
                                    implicitHeight: 26
                                    radius: Theme.round(8, width, height)
                                    color: Qt.alpha(Theme.text, 0.1)
                                    Label {
                                        id: keyLabel
                                        anchors.centerIn: parent
                                        text: root.keysFor(tip.modelData)
                                        font.family: Settings.appearance.monoFont
                                        font.weight: Font.Bold
                                        font.pixelSize: Theme.fontSize - 1
                                    }
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: tip.modelData.text
                                    color: Theme.subtext
                                    font.pixelSize: Theme.fontSize - 1
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    Component {
        id: donePage
        ColumnLayout {
            spacing: 18
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 104
                implicitHeight: 104
                radius: 52
                color: Theme.accent
                Icon {
                    anchors.centerIn: parent
                    name: "check"
                    size: 60
                    color: Theme.accentText
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "You're all set"
                color: Theme.text
                font.family: Theme.displayFont
                font.pixelSize: 36
                font.weight: Font.Bold
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 540
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "Settings (Super + ,) has everything you chose here and much more. To go through this again, run pikadots setup."
                color: Theme.subtext
                font.pixelSize: Theme.fontSize + 1
            }
            Item { Layout.fillHeight: true }
        }
    }
}
