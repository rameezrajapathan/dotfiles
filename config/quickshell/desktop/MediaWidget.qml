import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.widgets

Item {
    id: root
    property string size: "small"
    property bool live: true

    readonly property var player: Media.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property bool hasLength: (player?.lengthSupported ?? false) && (player?.length ?? 0) > 0

    Timer {
        interval: 1000
        repeat: true
        running: root.live && root.playing && root.size !== "small"
        onTriggered: root.player.positionChanged()
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    ColumnLayout {
        visible: !root.player
        anchors.centerIn: parent
        spacing: 6
        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "music_off"
            size: 40
            color: Theme.overlay
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Nothing playing"
            color: Theme.overlay
        }
    }

    component Cover: ClippingRectangle {
        radius: Theme.round(16, width, height)
        color: Qt.alpha(Theme.surface, 0.6)
        Icon {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            name: "music_note"
            size: parent.width / 3
            color: Theme.overlay
        }
        Image {
            id: cover
            anchors.fill: parent
            source: root.art
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 512
            asynchronous: true
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
            Desktop.showing = false;
            Media.panelToggleRequested();
        }
        }
    }

    component Button: Rectangle {
        id: button
        property string icon
        property bool big: false
        signal clicked()
        implicitWidth: big ? 48 : 38
        implicitHeight: implicitWidth
        radius: width / 2
        color: big ? Theme.selectedFill : mouse.containsMouse ? Qt.alpha(Theme.surface, 0.8) : "transparent"
        Icon {
            anchors.centerIn: parent
            name: button.icon
            filled: true
            size: button.big ? 28 : 24
            color: button.big ? Theme.selectedText : Theme.text
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    component Controls: RowLayout {
        spacing: 6
        Button {
            icon: "skip_previous"
            visible: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }
        Button {
            big: true
            icon: root.playing ? "pause" : "play_arrow"
            onClicked: root.player.togglePlaying()
        }
        Button {
            icon: "skip_next"
            visible: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }

    component Titles: ColumnLayout {
        property bool centered: false
        spacing: 0
        Label {
            Layout.fillWidth: true
            horizontalAlignment: parent.centered ? Text.AlignHCenter : Text.AlignLeft
            text: root.player?.trackTitle || root.player?.identity || ""
            font.weight: Font.Bold
            font.pixelSize: Theme.fontSize + 1
            elide: Text.ElideRight
        }
        Label {
            Layout.fillWidth: true
            horizontalAlignment: parent.centered ? Text.AlignHCenter : Text.AlignLeft
            text: root.player?.trackArtist ?? ""
            color: Theme.subtext
            elide: Text.ElideRight
        }
    }

    component Progress: ColumnLayout {
        visible: root.hasLength
        spacing: 2
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Qt.alpha(Theme.text, 0.12)
            Rectangle {
                width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { text: root.fmt(root.player?.position ?? 0); color: Theme.overlay; font.pixelSize: Theme.fontSize - 3 }
            Item { Layout.fillWidth: true }
            Label { text: root.fmt(root.player?.length ?? 0); color: Theme.overlay; font.pixelSize: Theme.fontSize - 3 }
        }
    }

    Item {
        visible: root.player !== null && root.size === "small"
        anchors { fill: parent; margins: 14 }
        Cover {
            anchors.fill: parent
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 64
            radius: Theme.round(16, width, height)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.6) }
            }
        }
        RowLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
            spacing: 6
            Label {
                Layout.fillWidth: true
                text: root.player?.trackTitle ?? ""
                color: "white"
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            Button {
                big: true
                icon: root.playing ? "pause" : "play_arrow"
                onClicked: root.player.togglePlaying()
            }
        }
    }

    RowLayout {
        visible: root.player !== null && root.size === "medium"
        anchors { fill: parent; margins: 16 }
        spacing: 16
        Cover {
            Layout.preferredWidth: parent.height
            Layout.preferredHeight: parent.height
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            Titles { Layout.fillWidth: true }
            Item { Layout.fillHeight: true }
            Progress { Layout.fillWidth: true }
            Controls { Layout.alignment: Qt.AlignHCenter }
        }
    }

    ColumnLayout {
        visible: root.player !== null && root.size === "large"
        anchors { fill: parent; margins: 20 }
        spacing: 10
        Cover {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(parent.width, parent.height - 150)
            Layout.preferredHeight: Layout.preferredWidth
        }
        Titles {
            Layout.fillWidth: true
            centered: true
        }
        Progress { Layout.fillWidth: true }
        Controls { Layout.alignment: Qt.AlignHCenter }
    }
}
