import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification: icon, app and time, summary, body, action buttons and a dismiss ✕.
// Clicking the card runs the app's default action. As a popup it hides itself after the timeout
// (paused while hovered); the notification stays in the list until dismissed.
Rectangle {
    id: root
    required property var notification
    property bool popup: false

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property var actions: notification.actions.filter(a => a.identifier !== "default")
    readonly property string iconSource: {
        const n = notification;
        // Theme icon names can arrive as image://icon/<name>; drop ones the theme doesn't have
        const themed = n.image.startsWith("image://icon/") ? n.image.slice(13) : "";
        if (n.image && !themed)
            return n.image;
        const icon = themed || n.appIcon;
        if (!icon)
            return "";
        return icon.startsWith("/") ? "file://" + icon : Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }

    implicitHeight: layout.implicitHeight + 24
    radius: 10
    color: Theme.base
    border.width: 2
    border.color: critical ? Theme.red : popup ? Theme.accent : Theme.surface

    Timer {
        // expireTimeout is in seconds; 0 means never, -1 means the server's default
        readonly property real seconds: root.notification.expireTimeout > 0 ? root.notification.expireTimeout : 5
        running: root.popup && !root.critical && root.notification.expireTimeout !== 0 && !hover.hovered
        interval: seconds * 1000
        onTriggered: NotificationService.hidePopup(root.notification)
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.activate(root.notification)
    }

    RowLayout {
        id: layout
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 12

        Image {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            visible: root.iconSource !== "" && status === Image.Ready
            source: root.iconSource
            sourceSize: Qt.size(72, 72)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    Layout.fillWidth: true
                    text: [root.notification.appName, NotificationService.ago(root.notification)]
                        .filter(s => s).join(" · ")
                    color: Theme.subtext
                    font.pixelSize: Theme.fontSize - 2
                    elide: Text.ElideRight
                }
                Label {
                    text: "󰅖"
                    color: close.containsMouse ? Theme.red : Theme.overlay

                    MouseArea {
                        id: close
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notification.dismiss()
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: root.notification.summary
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification.body
                textFormat: Text.StyledText
                color: Theme.subtext
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: root.actions.length > 0
                spacing: 6

                Repeater {
                    model: root.actions

                    Pill {
                        required property var modelData
                        text: modelData.text
                        onClicked: {
                            modelData.invoke();
                            NotificationService.hidePopup(root.notification);
                        }
                    }
                }
            }
        }
    }
}
