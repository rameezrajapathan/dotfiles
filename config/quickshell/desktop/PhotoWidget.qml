import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

DesktopWidgetContent {
    id: root

    property int index: -1
    property bool front: true

    FolderListModel {
        id: folder
        folder: "file://" + Desktop.photoFolder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP"]
        showDirs: false
        sortField: FolderListModel.Name
        onStatusChanged: if (status === FolderListModel.Ready) root.advance()
    }

    function advance() {
        if (folder.count === 0)
            return;
        let i = Math.floor(Math.random() * folder.count);
        if (folder.count > 1 && i === index)
            i = (i + 1) % folder.count;
        index = i;
        const url = "file://" + folder.get(i, "filePath");
        if (front)
            b.source = url;
        else
            a.source = url;
    }

    Timer {
        interval: Math.max(1, Settings.desktop.photoMinutes) * 60000
        repeat: true
        running: root.live && folder.count > 1
        onTriggered: root.advance()
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.round(26, width, height)
        color: "transparent"

        Image {
            id: a
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1024
            asynchronous: true
            opacity: root.front ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ms(900) } }
            onStatusChanged: if (status === Image.Ready && !root.front) root.front = true
        }
        Image {
            id: b
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 1024
            asynchronous: true
            opacity: root.front ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.ms(900) } }
            onStatusChanged: if (status === Image.Ready && root.front) root.front = false
        }
    }

    ColumnLayout {
        visible: folder.count === 0
        anchors.centerIn: parent
        width: parent.width - 32
        spacing: 6
        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "photo_library"
            size: 40
            color: Theme.overlay
        }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "No pictures in " + Desktop.photoFolder.replace(Quickshell.env("HOME"), "~")
            color: Theme.overlay
            wrapMode: Text.WordWrap
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: folder.count > 0
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                root.advance();
            else
                Qt.openUrlExternally(root.front ? a.source : b.source);
        }
    }
}
