import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property var unread: GitHub.items.filter(n => n.unread)
    onLiveChanged: if (live && GitHub.signedIn) GitHub.refresh()

    function typeIcon(t) {
        return t === "PullRequest" ? "merge" : t === "Issue" ? "adjust" : t === "Release" ? "sell" : t === "Discussion" ? "forum" : "notifications";
    }

    ColumnLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Icon {
                name: "code"
                size: 18
                color: Theme.accent
            }
            Label {
                Layout.fillWidth: true
                text: "GitHub"
                font.weight: Font.Bold
            }
        }

        Label {
            visible: !GitHub.signedIn
            Layout.fillWidth: true
            text: "Sign in with gh auth login"
            color: Theme.overlay
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            visible: GitHub.signedIn && root.size === "small"
            Layout.fillHeight: true
            spacing: 0
            Item { Layout.fillHeight: true }
            Text {
                text: root.unread.length
                color: root.unread.length ? Theme.text : Theme.overlay
                font.family: Theme.displayFont
                font.pixelSize: 64
                font.weight: Font.Light
            }
            Label {
                text: root.unread.length === 1 ? "unread notification" : "unread notifications"
                color: Theme.subtext
            }
        }

        Label {
            visible: GitHub.signedIn && root.size !== "small" && root.unread.length === 0
            text: "You're all caught up"
            color: Theme.overlay
        }

        Repeater {
            model: GitHub.signedIn && root.size !== "small" ? root.unread.slice(0, root.size === "large" ? 7 : 3) : []
            Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: root.size === "large" ? 50 : 40
                radius: Theme.round(12, width, height)
                color: mouse.containsMouse ? Qt.alpha(Theme.surface, 0.7) : "transparent"
                RowLayout {
                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                    spacing: 10
                    Icon {
                        name: root.typeIcon(row.modelData.type)
                        size: 18
                        color: Theme.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            Layout.fillWidth: true
                            text: row.modelData.title
                            elide: Text.ElideRight
                        }
                        Label {
                            visible: root.size === "large"
                            Layout.fillWidth: true
                            text: row.modelData.repo
                            color: Theme.subtext
                            font.pixelSize: Theme.fontSize - 2
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GitHub.open(row.modelData)
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
