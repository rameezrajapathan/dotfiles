import Quickshell
import Quickshell.Io
import QtQuick

// The running distro's logo, found from /etc/os-release so it works on any distro. Tries the
// LOGO icon name, Papirus' distributor-logo-<ID>, logo files in /usr/share, then the parent
// distro (ID_LIKE), then a generic logo. Click opens the app launcher.
Image {
    id: root

    property var release: ({})
    property int attempt: 0

    readonly property var candidates: {
        const names = [release.LOGO, "distributor-logo-" + release.ID]
            .concat((release.ID_LIKE ?? "").split(" ").filter(s => s).map(s => "distributor-logo-" + s));
        const list = [];
        for (const n of names.filter(n => n && !n.endsWith("-undefined"))) {
            if (Quickshell.hasThemeIcon(n))
                list.push(Quickshell.iconPath(n));
        }
        if (release.LOGO) {
            for (const dir of ["/usr/share/icons/", "/usr/share/pixmaps/"])
                list.push("file://" + dir + release.LOGO + ".svg", "file://" + dir + release.LOGO + ".png");
        }
        list.push(Quickshell.iconPath("distributor-logo", "start-here"));
        return list;
    }

    source: candidates[Math.min(attempt, candidates.length - 1)]
    sourceSize.width: 20
    sourceSize.height: 20
    onCandidatesChanged: attempt = 0
    onStatusChanged: if (status === Image.Error && attempt < candidates.length - 1) attempt++

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const fields = {};
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+)=["']?(.*?)["']?$/);
                if (m)
                    fields[m[1]] = m[2];
            }
            root.release = fields;
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
    }
}
