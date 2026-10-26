import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Rectangle {
    id: root
    required property var notification
    property bool popup: false

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property color tint: critical ? Theme.red : Theme.accent
    readonly property var actions: notification.actions.filter(a => a.identifier !== "default")
    readonly property string iconSource: {
        const n = notification;
        const themed = n.image.startsWith("image://icon/") ? n.image.slice(13) : "";
        if (n.image && !themed)
            return n.image;
        const icon = themed || n.appIcon;
        if (!icon)
            return "";
        return icon.startsWith("/") ? "file://" + icon : Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }
    readonly property bool expires: popup && !critical && notification.expireTimeout !== 0
    property real remaining: 1
    readonly property int inset: Theme.pad(14, 18)

    implicitHeight: layout.implicitHeight + inset * 2 + (expires ? 8 : 0)
    radius: Theme.round(18, width, height)
    color: "transparent"
    border.width: 1
    border.color: Theme.gradientAccent && (!root.critical) ? "transparent" : Qt.alpha(root.tint, critical ? 0.7 : Glass.active ? 0.2 : 0.35)
    GlassPanel {
        radius: root.radius
        tint: root.popup ? Theme.denseTranslucent : Theme.glassFill(1)
        lens: root.popup
        tracking: root.popup
    }
    GradientBorder {
        active: !root.critical
        strength: 0.35
    }
    clip: true

    readonly property string edge: Settings.notifications.position
    transform: Translate {
        id: slide
        x: !root.popup ? 0 : root.edge.endsWith("right") ? root.width + 20 : root.edge.endsWith("left") ? -root.width - 20 : 0
        y: !root.popup || root.edge.endsWith("right") || root.edge.endsWith("left") ? 0 : root.edge.startsWith("bottom") ? 60 : -60
    }
    Component.onCompleted: if (popup) slideIn.start()
    ParallelAnimation {
        id: slideIn
        NumberAnimation { target: slide; property: "x"; to: 0; duration: Theme.ms(260); easing.type: Easing.OutCubic }
        NumberAnimation { target: slide; property: "y"; to: 0; duration: Theme.ms(260); easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(root.tint, root.critical ? 0.2 : 0.12) }
            GradientStop { position: 0.6; color: "transparent" }
        }
    }

    NumberAnimation on remaining {
        running: root.expires
        paused: running && hover.hovered
        from: 1
        to: 0
        duration: (Settings.notifications.appTimeout && root.notification.expireTimeout > 0
            ? root.notification.expireTimeout : Settings.notifications.timeout) * 1000
        onFinished: NotificationService.hidePopup(root.notification)
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
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.inset }
        spacing: 14

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 44
            implicitHeight: 44
            radius: Theme.round(14, width, height)
            color: Qt.alpha(root.tint, 0.16)

            Image {
                id: icon
                anchors.centerIn: parent
                width: 30
                height: 30
                visible: status === Image.Ready
                source: root.iconSource
                sourceSize: Qt.size(60, 60)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Icon {
                anchors.centerIn: parent
                visible: !icon.visible
                name: root.critical ? "warning" : "notifications"
                filled: true
                color: root.tint
                size: 24
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    text: root.notification.appName || "Notification"
                    color: root.tint
                    font.pixelSize: Theme.fontSize - 2
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.maximumWidth: 200
                }
                Label {
                    visible: NotificationService.ago(root.notification) !== ""
                    text: "· " + NotificationService.ago(root.notification)
                    color: Theme.overlay
                    font.pixelSize: Theme.fontSize - 2
                }
                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: Theme.round(12, width, height)
                    color: close.containsMouse ? Qt.alpha(Theme.red, 0.2) : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 16
                        color: close.containsMouse ? Theme.red : Theme.overlay
                    }

                    MouseArea {
                        id: close
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notification.dismiss()
                    }

                    Tooltip {
                        text: "Dismiss"
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: root.notification.summary
                font.bold: true
                font.pixelSize: Theme.fontSize + 1
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
                Layout.topMargin: 6
                visible: root.actions.length > 0
                spacing: 6

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: action
                        required property var modelData

                        implicitWidth: actionLabel.implicitWidth + 24
                        implicitHeight: 28
                        radius: Theme.round(14, width, height)
                        color: actionMouse.containsMouse ? root.tint : Qt.alpha(root.tint, 0.18)

                        Label {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: action.modelData.text
                            color: actionMouse.containsMouse ? Theme.accentText : Theme.text
                            font.pixelSize: Theme.fontSize - 1
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const n = root.notification;
                                const a = action.modelData;
                                NotificationService.hidePopup(n);
                                a.invoke();
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.expires
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.inset
        anchors.bottomMargin: root.inset - 6
        width: (parent.width - root.inset * 2) * root.remaining
        height: 3
        radius: Theme.round(1.5, width, height)
        color: Qt.alpha(root.tint, 0.7)
        gradient: Theme.accentFill(!root.critical)
        opacity: Theme.gradientAccent && !root.critical ? 0.8 : 1
    }
}
