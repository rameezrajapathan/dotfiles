import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

CCCard {
    id: root
    property var cc

    readonly property bool any: Updates.count > 0
    color: any ? Qt.alpha(Theme.accent, 0.14) : Qt.alpha(Theme.surface, 0.3)
    implicitHeight: 64

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.pad(16, 22); rightMargin: Theme.pad(12, 22) }
        spacing: 12

        Icon {
            name: Updates.checking ? "sync" : root.any ? "system_update_alt" : "verified"
            filled: root.any
            color: root.any ? Theme.accent : Theme.subtext
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                Layout.fillWidth: true
                text: Updates.checking ? "Checking…" : Updates.systemCount > 0
                    ? Updates.systemCount + (Updates.systemCount === 1 ? " package update" : " package updates")
                    : Updates.behind > 0 ? "pikadots update" : "Up to date"
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                text: Updates.behind > 0 ? "pikadots: " + Updates.behind + (Updates.behind === 1 ? " new change" : " new changes")
                    : Updates.checked > 0 ? "Checked " + Updates.ago(Updates.checked) : "Not checked yet"
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
        }
        Rectangle {
            implicitWidth: buttonLabel.implicitWidth + 28
            implicitHeight: 34
            radius: Theme.round(17, width, height)
            color: root.any ? (buttonMouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                : Qt.alpha(Theme.surface, buttonMouse.containsMouse ? 0.85 : 0.55)
            gradient: Theme.accentFill(root.any)

            Label {
                id: buttonLabel
                anchors.centerIn: parent
                text: root.any ? "Update" : "Check"
                color: root.any ? Theme.accentText : Theme.text
                font.weight: Font.DemiBold
                font.pixelSize: Theme.fontSize - 1
            }
            MouseArea {
                id: buttonMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.any) {
                        Updates.check();
                        return;
                    }
                    root.cc.close();
                    if (Updates.systemCount > 0)
                        Updates.updateSystem();
                    else
                        Updates.updatePikadots();
                }
            }
        }
    }

    MouseArea {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width - 110
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.cc.close();
            Settings.openRequested("updates");
        }
    }
}
