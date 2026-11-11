import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.services
import qs.widgets

Item {
    id: root
    property var item: null
    property real size: 48
    property bool badge: true
    property bool warning: false

    readonly property string type: item?.type ?? ""
    readonly property var entry: Shortcuts.entryOf(item)
    readonly property string favicon: type === "web" ? Shortcuts.favicon(item.target) : ""
    readonly property var browser: type === "web" && item?.browser ? Shortcuts.browserOf(item.browser) : null
    readonly property var profile: browser && item?.profile ? Shortcuts.profileOf(item.browser, item.profile) : null
    readonly property string letter: (Shortcuts.labelOf(item) || "?").charAt(0).toUpperCase()
    readonly property color tint: Qt.hsla(Shortcuts.hashHue(Shortcuts.hostOf(item?.target) || (item?.target ?? "")), 0.5, 0.55, 1)

    readonly property string themeIcon: {
        if (type === "local") {
            if (item.folder)
                return Shortcuts.expand(item.target) === Quickshell.env("HOME") ? "user-home" : "folder";
            const ext = (item.target.split(".").pop() ?? "").toLowerCase();
            if (["png", "jpg", "jpeg", "webp", "gif", "svg", "avif"].includes(ext)) return "image-x-generic";
            if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "video-x-generic";
            if (["mp3", "flac", "ogg", "wav", "opus", "m4a"].includes(ext)) return "audio-x-generic";
            if (ext === "pdf") return "application-pdf";
            if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].includes(ext)) return "package-x-generic";
            if (["doc", "docx", "odt"].includes(ext)) return "x-office-document";
            if (["xls", "xlsx", "ods", "csv"].includes(ext)) return "x-office-spreadsheet";
            if (["sh", "py", "js", "ts", "qml", "lua", "c", "rs", "go"].includes(ext)) return "text-x-script";
            return "text-x-generic";
        }
        if (type === "uri") {
            const scheme = (item.target.split(":")[0] ?? "").toLowerCase();
            if (scheme === "mailto") return "internet-mail";
            if (scheme === "tel" || scheme === "callto") return "call-start";
            if (Quickshell.hasThemeIcon(scheme)) return scheme;
            return "";
        }
        return "";
    }

    implicitWidth: size
    implicitHeight: size

    Icon {
        anchors.centerIn: parent
        visible: (root.item?.icon ?? "") !== ""
        name: root.item?.icon ?? ""
        size: root.size * 0.78
        filled: true
        color: Theme.text
    }

    AppIcon {
        anchors.fill: parent
        visible: !root.item?.icon && root.type === "app"
        icon: root.entry?.icon ?? ""
        implicitSize: root.size
    }

    IconImage {
        anchors.fill: parent
        visible: !root.item?.icon && root.themeIcon !== ""
        source: root.themeIcon ? Quickshell.iconPath(root.themeIcon, "text-x-generic") : ""
        implicitSize: root.size
        asynchronous: true
    }

    Rectangle {
        id: plate
        anchors.fill: parent
        visible: !root.item?.icon && (root.type === "web" || (root.type === "uri" && root.themeIcon === "") || root.type === "")
        radius: Theme.round(root.size * 0.26, width, height)
        color: root.favicon && fav.status === Image.Ready ? Qt.alpha("white", 0.92) : root.tint

        Image {
            id: fav
            anchors.centerIn: parent
            width: parent.width * 0.68
            height: width
            visible: status === Image.Ready
            source: root.favicon
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
        }

        Text {
            anchors.centerIn: parent
            visible: !fav.visible
            text: root.type === "uri" ? "" : root.letter
            color: "white"
            font.family: Theme.displayFont
            font.weight: Font.Bold
            font.pixelSize: root.size * 0.5
        }

        Icon {
            anchors.centerIn: parent
            visible: !fav.visible && root.type === "uri"
            name: "link"
            size: root.size * 0.55
            color: "white"
        }
    }

    Rectangle {
        id: corner
        readonly property real d: Math.max(14, root.size * 0.42)
        visible: root.badge && root.browser !== null
        x: root.width - d * 0.8
        y: root.height - d * 0.8
        width: d
        height: d
        radius: d / 2
        color: root.profile ? Shortcuts.profileColor(root.item.browser, root.profile) : Theme.base
        border.width: Math.max(1.5, d * 0.09)
        border.color: Theme.base

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: parent.border.width
            radius: width / 2
            color: "transparent"
            visible: root.profile?.picture ? true : false
            Image {
                anchors.fill: parent
                source: root.profile?.picture ? "file://" + root.profile.picture : ""
                sourceSize: Qt.size(64, 64)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        AppIcon {
            anchors.centerIn: parent
            visible: !(root.profile?.picture)
            icon: root.browser?.icon ?? ""
            implicitSize: parent.d * (root.profile ? 0.62 : 0.8)
        }
    }

    Rectangle {
        visible: root.warning
        x: -width * 0.25
        y: -height * 0.25
        width: Math.max(16, root.size * 0.36)
        height: width
        radius: width / 2
        color: Theme.yellow
        Icon {
            anchors.centerIn: parent
            name: "priority_high"
            size: parent.width * 0.75
            color: Theme.base
        }
    }
}
