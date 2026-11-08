import Quickshell
import QtQuick
import qs.services

Image {
    id: root

    readonly property var release: SysStats.osRelease
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
}
