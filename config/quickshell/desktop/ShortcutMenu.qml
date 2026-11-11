import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property bool open: false
    property int current: -1
    property bool choosing: false

    readonly property var info: Shortcuts.menu
    readonly property var item: info ? Shortcuts.itemOf(info.widget, info.item) : null

    readonly property var mainRows: {
        if (!item)
            return [];
        const rows = [];
        if (item.type === "web")
            rows.push({ icon: "open_in_new", label: "Open in…", more: true, run: () => { root.choosing = true; root.current = -1; } });
        else
            rows.push({ icon: "open_in_new", label: "Open", run: () => root.finish(() => Shortcuts.open(root.item)) });
        rows.push({ icon: "edit", label: "Edit", run: () => Shortcuts.edit(root.info.screen, root.info.widget, root.item.id) });
        rows.push({ separator: true });
        rows.push({ icon: "delete", label: "Remove", danger: true, run: () => root.finish(() => Shortcuts.remove(root.info.widget, root.item.id)) });
        return rows;
    }

    readonly property var browserRows: {
        const rows = [{ icon: "arrow_back", label: "Back", run: () => { root.choosing = false; root.current = -1; } }, { separator: true }];
        const def = Shortcuts.browserOf(Shortcuts.defaultBrowser);
        rows.push({ appIcon: def?.icon ?? "", icon: def ? "" : "public", label: "Default browser" + (def ? " (" + def.name + ")" : ""), run: () => root.openWith("", "") });
        for (const b of Shortcuts.browsers) {
            if (b.profiles.length === 0) {
                rows.push({ appIcon: b.icon, label: b.name, run: () => root.openWith(b.id, "") });
                continue;
            }
            for (const p of b.profiles)
                rows.push({ appIcon: b.icon, dot: Shortcuts.profileColor(b.id, p), label: b.name + " · " + Shortcuts.profileName(b.id, p), detail: p.detail, run: () => root.openWith(b.id, p.id) });
        }
        return rows;
    }

    readonly property var rows: choosing ? browserRows : mainRows

    function finish(f) {
        Shortcuts.menu = null;
        f();
    }

    function openWith(browserId, profileId) {
        const it = item;
        finish(() => Shortcuts.open(it, browserId, profileId));
    }

    function step(d) {
        let i = current;
        for (let n = 0; n < rows.length; n++) {
            i = (i + d + rows.length) % rows.length;
            if (!rows[i].separator)
                return i;
        }
        return current;
    }

    onOpenChanged: {
        current = -1;
        choosing = false;
        if (open)
            Qt.callLater(() => keys.forceActiveFocus());
    }
    onItemChanged: if (open && !item) Shortcuts.menu = null

    anchors.fill: parent
    visible: card.opacity > 0

    Rectangle {
        id: card
        readonly property real w: root.choosing ? 340 : 220
        x: Math.max(8, Math.min(root.info?.x ?? 0, root.width - w - 8))
        y: Math.max(8, Math.min(root.info?.y ?? 0, root.height - height - 8))
        width: w
        height: Math.min(list.implicitHeight + 12, root.height - 16)
        radius: Theme.round(16, width, height)
        color: Theme.denseTranslucent
        border.width: Glass.active ? 0 : 1
        border.color: Qt.alpha(Theme.text, 0.1)
        opacity: root.open && root.item ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopLeft
        clip: true
        Behavior on opacity { NumberAnimation { duration: Theme.ms(120) } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutCubic } }
        GlassRim {}

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: root.open
            Keys.onUpPressed: root.current = root.step(-1)
            Keys.onDownPressed: root.current = root.step(1)
            Keys.onReturnPressed: if (root.current >= 0) root.rows[root.current].run()
            Keys.onLeftPressed: if (root.choosing) root.choosing = false
            Keys.onEscapePressed: {
                if (root.choosing)
                    root.choosing = false;
                else
                    Shortcuts.menu = null;
            }
        }

        Flickable {
            anchors { fill: parent; margins: 6 }
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: list
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.rows
                    Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool hot: root.current === index
                        Layout.fillWidth: true
                        implicitHeight: modelData.separator ? 9 : modelData.detail ? 46 : 36

                        Rectangle {
                            visible: row.modelData.separator === true
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: Qt.alpha(Theme.text, 0.1)
                        }

                        Rectangle {
                            visible: !row.modelData.separator
                            anchors.fill: parent
                            radius: Theme.round(10, width, height)
                            color: row.hot ? (row.modelData.danger ? Theme.red : Theme.selectedFill) : "transparent"

                            RowLayout {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                spacing: 10

                                Item {
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    Icon {
                                        anchors.centerIn: parent
                                        visible: !row.modelData.appIcon
                                        name: row.modelData.icon ?? ""
                                        size: 18
                                        color: row.hot ? (row.modelData.danger ? Theme.base : Theme.selectedText) : row.modelData.danger ? Theme.red : Theme.subtext
                                    }
                                    AppIcon {
                                        anchors.centerIn: parent
                                        visible: !!row.modelData.appIcon
                                        icon: row.modelData.appIcon ?? ""
                                        implicitSize: 20
                                    }
                                    Rectangle {
                                        visible: row.modelData.dot !== undefined
                                        x: 11
                                        y: 11
                                        width: 11
                                        height: 11
                                        radius: 5.5
                                        color: row.modelData.dot ?? "transparent"
                                        border.width: 1.5
                                        border.color: Theme.base
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Label {
                                        Layout.fillWidth: true
                                        text: row.modelData.label ?? ""
                                        color: row.hot ? (row.modelData.danger ? Theme.base : Theme.selectedText) : row.modelData.danger ? Theme.red : Theme.text
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        visible: !!row.modelData.detail
                                        text: row.modelData.detail ?? ""
                                        color: row.hot ? Theme.selectedText : Theme.overlay
                                        font.pixelSize: Theme.fontSize - 3
                                        elide: Text.ElideRight
                                    }
                                }

                                Icon {
                                    visible: row.modelData.more === true
                                    name: "chevron_right"
                                    size: 18
                                    color: row.hot ? Theme.selectedText : Theme.overlay
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.current = row.index
                                onClicked: row.modelData.run()
                            }
                        }
                    }
                }
            }
        }
    }
}
