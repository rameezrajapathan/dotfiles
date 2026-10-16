import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.controlcenter
import qs.services
import qs.widgets

Item {
    id: root
    property bool shown: false
    signal closeRequested()

    implicitHeight: content.implicitHeight + 40

    function typeIcon(type) {
        return { PullRequest: "merge", Issue: "adjust", CheckSuite: "rule", Release: "commit", Discussion: "forum" }[type] ?? "inbox";
    }

    onShownChanged: if (shown) GitHub.refresh()

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
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
                    icon: "done_all"
                    onClicked: GitHub.markAllRead()
                }
                Pill {
                    icon: "open_in_new"
                    onClicked: {
                        root.closeRequested();
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
                            root.closeRequested();
                            GitHub.open(row.modelData);
                        }
                    }
                }
            }
        }
    }
}
