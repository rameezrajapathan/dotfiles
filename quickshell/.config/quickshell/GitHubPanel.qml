import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Dropdown listing GitHub notifications (GitHub.qml). Click one to open it in the browser and
// mark it read. A transparent full-screen overlay: clicks outside the panel close it.
PanelWindow {
    id: root
    required property var bar

    function toggle() {
        visible = !visible;
    }

    function typeIcon(type) {
        return { PullRequest: "merge", Issue: "adjust", CheckSuite: "rule", Release: "commit", Discussion: "forum" }[type] ?? "inbox";
    }

    screen: bar.screen
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-github"
    color: "transparent"
    visible: false

    onVisibleChanged: if (visible) GitHub.refresh()

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 420
        height: content.implicitHeight + 28
        color: Theme.baseTranslucent
        radius: 10
        border.color: Theme.surface
        border.width: 2

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4

                Label {
                    Layout.fillWidth: true
                    text: "GitHub"
                    font.bold: true
                }
                Pill {
                    visible: GitHub.unread > 0
                    text: "mark all read"
                    onClicked: GitHub.markAllRead()
                }
                Pill {
                    text: "open"
                    onClicked: {
                        root.visible = false;
                        Quickshell.execDetached(["xdg-open", "https://github.com/notifications"]);
                    }
                }
            }

            Label {
                visible: GitHub.items.length === 0
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                text: "All caught up"
                color: Theme.overlay
            }

            Repeater {
                model: GitHub.items

                Rectangle {
                    id: row
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: rowLayout.implicitHeight + 16
                    radius: 8
                    color: rowMouse.containsMouse ? Theme.surface : "transparent"

                    RowLayout {
                        id: rowLayout
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                        spacing: 10

                        Icon {
                            Layout.alignment: Qt.AlignTop
                            name: root.typeIcon(row.modelData.type)
                            filled: row.modelData.unread
                            color: row.modelData.unread ? Theme.accent : Theme.overlay
                            size: 18
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Label {
                                Layout.fillWidth: true
                                text: row.modelData.title
                                font.bold: row.modelData.unread
                                color: row.modelData.unread ? Theme.text : Theme.subtext
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: row.modelData.repo + "  ·  " + row.modelData.reason
                                color: Theme.overlay
                                font.pixelSize: Theme.fontSize - 2
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false;
                            GitHub.open(row.modelData);
                        }
                    }
                }
            }
        }
    }
}
