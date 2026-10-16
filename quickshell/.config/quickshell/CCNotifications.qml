import Quickshell
import QtQuick
import QtQuick.Layouts

// Control center widget: the latest notifications (click runs the app's action, × dismisses),
// Clear all, and the rest on the notifications page.
CCCard {
    id: root
    property var cc
    property int maxItems: 3

    readonly property var list: NotificationService.list
    implicitHeight: column.implicitHeight + 24

    function iconFor(n) {
        const themed = n.image.startsWith("image://icon/") ? n.image.slice(13) : "";
        if (n.image && !themed)
            return n.image;
        const icon = themed || n.appIcon;
        if (!icon)
            return "";
        return icon.startsWith("/") ? "file://" + icon : Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 6

            Label {
                text: "Notifications"
                font.weight: Font.DemiBold

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cc.openDetail("notifications")
                }
            }
            Label {
                visible: root.list.length > 0
                text: root.list.length
                color: Theme.overlay
            }
            Icon {
                visible: NotificationService.quiet
                name: "do_not_disturb_on"
                size: 16
                color: Theme.overlay
            }
            Item { Layout.fillWidth: true }
            Label {
                visible: root.list.length > 0
                text: "Clear all"
                color: Theme.accent
                font.pixelSize: Theme.fontSize - 1

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.dismissAll()
                }
            }
        }

        Label {
            visible: root.list.length === 0
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.bottomMargin: 4
            text: "You're all caught up"
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 1
        }

        Repeater {
            model: root.list.slice(0, root.maxItems)

            Rectangle {
                id: row
                required property var modelData
                readonly property string iconSource: root.iconFor(modelData)

                Layout.fillWidth: true
                implicitHeight: rowLayout.implicitHeight + 20
                radius: 16
                color: rowMouse.containsMouse ? Qt.alpha(Theme.surface, 0.85) : Qt.alpha(Theme.surface, 0.55)

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.cc.close();
                        NotificationService.activate(row.modelData);
                    }
                }

                RowLayout {
                    id: rowLayout
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 8 }
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 24
                        implicitHeight: 24
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            source: row.iconSource
                            sourceSize: Qt.size(48, 48)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }
                        Icon {
                            visible: appIcon.status !== Image.Ready
                            anchors.centerIn: parent
                            name: "notifications"
                            filled: true
                            color: Theme.accent
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: row.modelData.summary || row.modelData.appName
                                font.weight: Font.DemiBold
                                font.pixelSize: Theme.fontSize - 1
                                elide: Text.ElideRight
                            }
                            Label {
                                text: NotificationService.ago(row.modelData)
                                color: Theme.overlay
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: row.modelData.body.replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 2
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                        }
                    }
                    CCIconButton {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 26
                        implicitHeight: 26
                        tone: "flat"
                        icon: "close"
                        iconSize: 16
                        onClicked: row.modelData.dismiss()
                    }
                }
            }
        }

        Label {
            visible: root.list.length > root.maxItems
            Layout.alignment: Qt.AlignHCenter
            text: "+ " + (root.list.length - root.maxItems) + " more"
            color: Theme.overlay
            font.pixelSize: Theme.fontSize - 1

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.cc.openDetail("notifications")
            }
        }
    }
}
