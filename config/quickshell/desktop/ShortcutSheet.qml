import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property bool open: false

    readonly property var info: Shortcuts.sheet
    readonly property var existing: info && info.item ? Shortcuts.itemOf(info.widget, info.item) : null

    property string mode: "app"
    property string appId: ""
    property string address: ""
    property string browser: ""
    property string profile: ""
    property string label: ""
    property string icon: ""
    property string query: ""
    property string renaming: ""

    readonly property var parsed: Shortcuts.classify(address)
    readonly property bool web: mode === "address" && parsed.type === "web"
    readonly property var browserInfo: Shortcuts.browserOf(browser)
    readonly property var draft: mode === "app"
        ? { type: "app", target: appId, label: label, icon: icon }
        : { type: parsed.type, target: parsed.target, browser: browser, profile: profile, label: label, icon: icon,
            folder: existing?.type === "local" && existing.target === parsed.target ? existing.folder : picker.folder && picker.picked === parsed.target }
    readonly property bool valid: mode === "app" ? appId !== "" : parsed.type !== ""

    function load() {
        const s = Shortcuts.sheet;
        const e = s?.item ? Shortcuts.itemOf(s.widget, s.item) : null;
        mode = !e || e.type === "app" ? "app" : "address";
        appId = e?.type === "app" ? e.target : "";
        address = e && e.type !== "app" ? e.target : "";
        browser = e?.browser ?? "";
        profile = e?.profile ?? "";
        label = e?.label ?? "";
        icon = e?.icon ?? "";
        query = "";
        renaming = "";
        picker.picked = "";
        Qt.callLater(() => (mode === "app" ? search : addressInput).forceActiveFocus());
    }

    function commit() {
        if (!valid || !info)
            return;
        Shortcuts.save(info.widget, Object.assign({ id: existing?.id ?? "" }, draft));
        Shortcuts.sheet = null;
    }

    function cancel() {
        picker.running = false;
        Shortcuts.sheet = null;
    }

    onOpenChanged: {
        if (open)
            Qt.callLater(load);
        else
            picker.running = false;
    }
    onInfoChanged: if (open && info) Qt.callLater(load)
    onExistingChanged: if (open && info?.item && !existing) Qt.callLater(cancel)

    anchors.fill: parent
    visible: card.opacity > 0

    Process {
        id: picker
        property bool folder: false
        property string picked: ""
        onRunningChanged: Shortcuts.picking = running
        function choose(dir) {
            folder = dir;
            command = ["zenity", "--file-selection", "--title", dir ? "Choose a folder" : "Choose a file"].concat(dir ? ["--directory"] : []);
            running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                if (p) {
                    root.address = p.startsWith(Quickshell.env("HOME") + "/") ? "~" + p.slice(Quickshell.env("HOME").length) : p;
                    picker.picked = root.address;
                    Qt.callLater(() => labelInput.forceActiveFocus());
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        opacity: root.open ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.cancel()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 580)
        height: Math.min(parent.height - 96, 700)
        radius: Theme.round(28, width, height)
        color: Qt.alpha(Theme.base, 0.95)
        border.width: Glass.active ? 0 : 1
        border.color: Qt.alpha(Theme.text, 0.1)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(200); easing.type: Easing.OutCubic } }
        GlassRim {}

        MouseArea {
            anchors.fill: parent
        }

        Keys.onEscapePressed: root.cancel()

        ColumnLayout {
            anchors { fill: parent; margins: 20 }
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.existing ? "Edit shortcut" : "Add a shortcut"
                    color: Theme.text
                    font.family: Theme.displayFont
                    font.pixelSize: 24
                    font.weight: Font.Bold
                }
                IconButton {
                    icon: "close"
                    tone: "flat"
                    tip: "Cancel"
                    onClicked: root.cancel()
                }
            }

            RowLayout {
                spacing: 6
                IconButton {
                    icon: "apps"
                    iconSize: 18
                    text: "App"
                    tone: root.mode === "app" ? "selected" : ""
                    onClicked: {
                        root.mode = "app";
                        search.forceActiveFocus();
                    }
                }
                IconButton {
                    icon: "link"
                    iconSize: 18
                    text: "Website, file or link"
                    tone: root.mode === "address" ? "selected" : ""
                    onClicked: {
                        root.mode = "address";
                        addressInput.forceActiveFocus();
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.mode === "app"
                spacing: 8

                Field {
                    Layout.fillWidth: true
                    iconName: "search"
                    TextInput {
                        id: search
                        anchors.fill: parent
                        text: root.query
                        onTextChanged: root.query = text
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        clip: true
                        selectByMouse: true
                        Keys.onEscapePressed: root.cancel()
                        Keys.onDownPressed: apps.incrementCurrentIndex()
                        Keys.onUpPressed: apps.decrementCurrentIndex()
                        onAccepted: if (apps.currentItem) {
                            root.appId = apps.currentItem.entry.id;
                            root.commit();
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text === ""
                            text: "Search apps"
                            color: Theme.overlay
                        }
                    }
                }

                ListView {
                    id: apps
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.open && root.mode === "app" ? LauncherApps.search(root.query.trim().toLowerCase(), "") : []
                    onModelChanged: currentIndex = Math.max(0, model.findIndex?.(e => e.id === root.appId) ?? 0)
                    delegate: Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index
                        readonly property var entry: modelData
                        readonly property bool chosen: modelData.id === root.appId
                        width: apps.width
                        height: 40
                        radius: Theme.round(10, width, height)
                        color: chosen ? Theme.selectedFill : apps.currentIndex === index || appMouse.containsMouse ? Qt.alpha(Theme.text, 0.07) : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10
                            AppIcon {
                                icon: appRow.modelData.icon
                                implicitSize: 24
                            }
                            Label {
                                Layout.fillWidth: true
                                text: appRow.modelData.name
                                color: appRow.chosen ? Theme.selectedText : Theme.text
                                elide: Text.ElideRight
                            }
                            Icon {
                                visible: appRow.chosen
                                name: "check"
                                size: 18
                                color: Theme.selectedText
                            }
                        }
                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.appId = appRow.modelData.id;
                                apps.currentIndex = appRow.index;
                            }
                            onDoubleClicked: {
                                root.appId = appRow.modelData.id;
                                root.commit();
                            }
                        }
                    }
                }
            }

            Flickable {
                id: addressPane
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.mode === "address"
                contentHeight: addressCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                ColumnLayout {
                    id: addressCol
                    width: addressPane.width
                    spacing: 10

                    Field {
                        Layout.fillWidth: true
                        iconName: root.parsed.type === "web" ? "public" : root.parsed.type === "local" ? "folder" : "link"
                        TextInput {
                            id: addressInput
                            anchors.fill: parent
                            text: root.address
                            onTextChanged: root.address = text
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            verticalAlignment: Text.AlignVCenter
                            clip: true
                            selectByMouse: true
                            Keys.onEscapePressed: root.cancel()
                            onAccepted: root.commit()
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: addressInput.text === ""
                                text: "github.com, ~/Projects, mailto:me@example.com…"
                                color: Theme.overlay
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Label {
                            Layout.fillWidth: true
                            text: root.address.trim() === "" ? "Type a web address, a path, or any link."
                                : root.parsed.type === "web" ? "A website. Pick the browser and profile below."
                                : root.parsed.type === "local" ? "A file or folder. It opens in the app your system uses for it."
                                : root.parsed.type === "uri" ? "A link. It opens in the app your system uses for " + root.parsed.target.split(":")[0] + ": links."
                                : "That doesn't look like an address, a path or a link."
                            color: root.address.trim() !== "" && root.parsed.type === "" ? Theme.red : Theme.subtext
                            font.pixelSize: Theme.fontSize - 1
                            wrapMode: Text.WordWrap
                        }
                        IconButton {
                            icon: "description"
                            iconSize: 16
                            text: "File…"
                            onClicked: picker.choose(false)
                        }
                        IconButton {
                            icon: "folder_open"
                            iconSize: 16
                            text: "Folder…"
                            onClicked: picker.choose(true)
                        }
                    }

                    Heading {
                        visible: root.web
                        text: "Browser"
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: root.web
                        spacing: 6

                        Chip {
                            appIcon: Shortcuts.browserOf(Shortcuts.defaultBrowser)?.icon ?? ""
                            text: "Default"
                            chosen: root.browser === ""
                            onPicked: {
                                root.browser = "";
                                root.profile = "";
                            }
                        }
                        Repeater {
                            model: Shortcuts.browsers
                            Chip {
                                required property var modelData
                                appIcon: modelData.icon
                                text: modelData.name
                                chosen: root.browser === modelData.id
                                onPicked: {
                                    if (root.browser !== modelData.id)
                                        root.profile = "";
                                    root.browser = modelData.id;
                                }
                            }
                        }
                        Chip {
                            visible: root.browser !== "" && !root.browserInfo && Shortcuts.browsersLoaded
                            appIcon: ""
                            text: root.browser.replace(/\.desktop$/, "") + " (not installed)"
                            chosen: true
                            warn: true
                        }
                    }

                    Heading {
                        visible: root.web && root.browserInfo !== null && root.browserInfo.profiles.length > 0
                        text: "Profile"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.web && root.browserInfo !== null && root.browserInfo.profiles.length > 0
                        spacing: 2

                        ProfileRow {
                            profileData: null
                            name: "Usual profile"
                            detail: "Whichever profile " + (root.browserInfo?.name ?? "the browser") + " opens normally"
                            chosen: root.profile === ""
                            onPicked: root.profile = ""
                        }
                        Repeater {
                            model: root.browserInfo?.profiles ?? []
                            ProfileRow {
                                required property var modelData
                                profileData: modelData
                                name: Shortcuts.profileName(root.browser, modelData)
                                detail: (Shortcuts.profileName(root.browser, modelData) !== modelData.name ? modelData.name + " · " : "") + modelData.detail
                                chosen: root.profile === modelData.id
                                onPicked: root.profile = modelData.id
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: root.profile !== "" && root.browserInfo !== null && !Shortcuts.profileOf(root.browser, root.profile)
                            text: "The profile this shortcut used is gone. Pick another one."
                            color: Theme.yellow
                            font.pixelSize: Theme.fontSize - 1
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Theme.text, 0.1)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    implicitWidth: 72
                    implicitHeight: 72
                    radius: Theme.round(18, width, height)
                    color: Qt.alpha(Theme.text, 0.05)
                    ShortcutIcon {
                        anchors.centerIn: parent
                        size: 46
                        item: root.valid ? root.draft : null
                        visible: root.valid
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: !root.valid
                        name: "help"
                        size: 30
                        color: Theme.overlay
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Field {
                        Layout.fillWidth: true
                        iconName: "label"
                        TextInput {
                            id: labelInput
                            anchors.fill: parent
                            text: root.label
                            onTextChanged: root.label = text
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            verticalAlignment: Text.AlignVCenter
                            clip: true
                            selectByMouse: true
                            Keys.onEscapePressed: root.cancel()
                            onAccepted: root.commit()
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: labelInput.text === ""
                                text: root.valid ? Shortcuts.autoLabel(root.draft) + " (automatic)" : "Name"
                                color: Theme.overlay
                            }
                        }
                    }

                    Field {
                        Layout.fillWidth: true
                        iconName: root.icon || "image"
                        TextInput {
                            id: iconInput
                            anchors.fill: parent
                            text: root.icon
                            onTextChanged: root.icon = text.trim().toLowerCase().replace(/\s+/g, "_")
                            color: Theme.text
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            verticalAlignment: Text.AlignVCenter
                            clip: true
                            selectByMouse: true
                            Keys.onEscapePressed: root.cancel()
                            onAccepted: root.commit()
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: iconInput.text === ""
                                text: "Icon: automatic, or a Material icon name like rocket_launch"
                                color: Theme.overlay
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IconButton {
                    visible: root.existing !== null
                    icon: "delete"
                    iconSize: 18
                    text: "Remove"
                    onClicked: {
                        Shortcuts.remove(root.info.widget, root.existing.id);
                        Shortcuts.sheet = null;
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                IconButton {
                    text: "Cancel"
                    onClicked: root.cancel()
                }
                IconButton {
                    tone: root.valid ? "accent" : ""
                    opacity: root.valid ? 1 : 0.5
                    icon: "check"
                    iconSize: 18
                    text: root.existing ? "Save" : "Add"
                    onClicked: root.commit()
                }
            }
        }
    }

    component Field: Rectangle {
        id: field
        property string iconName: ""
        default property alias inner: slot.data
        implicitHeight: 40
        radius: height / 2
        color: Qt.alpha(Theme.surface, 0.6)
        border.width: 1
        border.color: slot.children.length && slot.children[0].activeFocus ? Theme.accent : Qt.alpha(Theme.text, 0.08)
        HoverHandler {
            cursorShape: Qt.IBeamCursor
        }
        Icon {
            id: fieldIcon
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            name: field.iconName
            size: 18
            color: Theme.subtext
        }
        Item {
            id: slot
            anchors { left: fieldIcon.right; leftMargin: 8; right: parent.right; rightMargin: 14; top: parent.top; bottom: parent.bottom }
        }
    }

    component Heading: Label {
        Layout.topMargin: 6
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 1
        font.weight: Font.Bold
    }

    component Chip: Rectangle {
        id: chip
        property string appIcon: ""
        property string text: ""
        property bool chosen: false
        property bool warn: false
        signal picked()
        implicitWidth: chipRow.implicitWidth + 24
        implicitHeight: 36
        radius: height / 2
        color: chosen ? (warn ? Qt.alpha(Theme.yellow, 0.3) : Theme.selectedFill) : chipMouse.containsMouse ? Qt.alpha(Theme.text, 0.1) : Qt.alpha(Theme.text, 0.05)
        border.width: 1
        border.color: Qt.alpha(Theme.text, chosen ? 0 : 0.1)
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 8
            AppIcon {
                visible: chip.appIcon !== ""
                anchors.verticalCenter: parent.verticalCenter
                icon: chip.appIcon
                implicitSize: 20
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.chosen && !chip.warn ? Theme.selectedText : Theme.text
                font.weight: chip.chosen ? Font.DemiBold : Font.Normal
            }
        }
        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.picked()
        }
    }

    component ProfileRow: Rectangle {
        id: prow
        property var profileData: null
        property string name: ""
        property string detail: ""
        property bool chosen: false
        readonly property bool editingName: profileData !== null && root.renaming === profileData.id
        signal picked()
        Layout.fillWidth: true
        implicitHeight: 50
        radius: Theme.round(12, width, height)
        color: chosen ? Theme.selectedFill : rowMouse.containsMouse ? Qt.alpha(Theme.text, 0.07) : "transparent"

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: prow.picked()
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
            spacing: 10

            Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: prow.profileData ? Shortcuts.profileColor(root.browser, prow.profileData) : Qt.alpha(Theme.text, 0.1)
                Icon {
                    anchors.centerIn: parent
                    visible: !prow.profileData?.picture
                    name: prow.profileData ? "person" : "auto_mode"
                    size: 18
                    color: prow.profileData ? "white" : Theme.subtext
                    filled: true
                }
                ClippingRectangle {
                    anchors.fill: parent
                    radius: 15
                    color: "transparent"
                    visible: !!prow.profileData?.picture
                    Image {
                        anchors.fill: parent
                        source: prow.profileData?.picture ? "file://" + prow.profileData.picture : ""
                        sourceSize: Qt.size(60, 60)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    visible: !prow.editingName
                    text: prow.name
                    color: prow.chosen ? Theme.selectedText : Theme.text
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                TextInput {
                    id: nameInput
                    Layout.fillWidth: true
                    visible: prow.editingName
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: Font.DemiBold
                    clip: true
                    selectByMouse: true
                    onVisibleChanged: if (visible) {
                        text = prow.name;
                        selectAll();
                        forceActiveFocus();
                    }
                    onAccepted: {
                        Shortcuts.renameProfile(root.browser, prow.profileData.id, text);
                        root.renaming = "";
                    }
                    Keys.onEscapePressed: root.renaming = ""
                    onActiveFocusChanged: if (!activeFocus && prow.editingName) {
                        Shortcuts.renameProfile(root.browser, prow.profileData.id, text);
                        root.renaming = "";
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: prow.detail
                    color: prow.chosen ? Theme.selectedText : Theme.overlay
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
            }

            IconButton {
                visible: prow.profileData !== null
                width: 30
                height: 30
                tone: "flat"
                icon: prow.editingName ? "check" : "edit"
                iconSize: 16
                iconColor: prow.chosen ? Theme.selectedText : Theme.text
                tip: prow.editingName ? "Save name" : "Rename this profile everywhere in Pikadots"
                onClicked: {
                    if (prow.editingName) {
                        Shortcuts.renameProfile(root.browser, prow.profileData.id, nameInput.text);
                        root.renaming = "";
                    } else {
                        root.renaming = prow.profileData.id;
                    }
                }
            }
        }
    }
}
