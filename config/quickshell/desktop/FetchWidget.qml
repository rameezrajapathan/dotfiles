import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    readonly property var info: SysStats.facts
    readonly property string uptime: SysStats.uptimeSeconds > 0 ? SysStats.uptimeText(true) : ""

    readonly property string mono: Settings.appearance.monoFont
    readonly property bool wide: width >= 320
    readonly property var rows: [
        ["OS", info.os], ["Kernel", info.kernel], ["Uptime", uptime], ["Packages", info.packages],
        ["Shell", info.shell], ["WM", info.wm], ["CPU", info.cpu], ["Memory", SysStats.memTotal > 0 ? SysStats.gib(SysStats.memUsed) + " / " + SysStats.gib(SysStats.memTotal) + " GiB" : info.memory]
    ].filter(r => r[1])
    readonly property int fitRows: Math.max(1, Math.floor((height - (wide ? 70 : 150)) / (Theme.fontSize + 9)))

    SysStatsWatch {
        active: root.live && root.visible
    }

    Component.onCompleted: SysStats.loadFacts()

    GridLayout {
        anchors { fill: parent; margins: 18 }
        columns: root.wide ? 2 : 1
        columnSpacing: 18
        rowSpacing: 8

        IconImage {
            Layout.alignment: root.wide ? Qt.AlignTop : Qt.AlignHCenter
            Layout.topMargin: root.wide ? 4 : 0
            implicitSize: root.wide ? Math.min(110, root.height - 60) : Math.min(72, root.height * 0.3)
            source: Quickshell.iconPath(root.info.logo ?? SysStats.osRelease.LOGO ?? SysStats.osRelease.ID ?? "", "distributor-logo-archlinux")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            Text {
                Layout.alignment: root.wide ? Qt.AlignLeft : Qt.AlignHCenter
                text: "<font color='" + Theme.accent + "'>" + User.userName + "</font>@<font color='" + Theme.accent + "'>" + (root.info.host ?? "") + "</font>"
                textFormat: Text.StyledText
                color: Theme.text
                font.family: root.mono
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Bold
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Qt.alpha(Theme.text, 0.15)
                Layout.bottomMargin: 2
            }
            Repeater {
                model: root.rows.slice(0, root.fitRows)
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.preferredWidth: root.wide ? 78 : 66
                        text: modelData[0]
                        color: Theme.accent
                        font.family: root.mono
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: Font.Bold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData[1]
                        color: Theme.text
                        font.family: root.mono
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                    }
                }
            }
            Item { Layout.fillHeight: true }
            Row {
                visible: root.height > 200
                spacing: 4
                Repeater {
                    model: [Theme.red, Theme.yellow, Theme.green, Theme.accent, Theme.accent2, Theme.accent3, Theme.special, Theme.text]
                    Rectangle {
                        required property color modelData
                        width: 18
                        height: 10
                        radius: Theme.round(3, width, height)
                        color: modelData
                    }
                }
            }
        }
    }
}
