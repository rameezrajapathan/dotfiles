pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    IpcHandler {
        target: "media"
        function toggle(): void {
            Panels.toggle("controlcenter", "music");
        }
        function playPause(): void {
            if (root.active?.canTogglePlaying)
                root.active.togglePlaying();
        }
        function next(): void {
            if (root.active?.canGoNext)
                root.active.next();
        }
        function previous(): void {
            if (root.active?.canGoPrevious)
                root.active.previous();
        }
    }

    readonly property var players: Mpris.players.values
    property var chosen: null

    readonly property var active: {
        const playing = players.find(p => p.isPlaying) ?? null;
        if (chosen && players.includes(chosen) && (chosen.isPlaying || !playing))
            return chosen;
        return playing ?? players[0] ?? null;
    }

    function iconFor(player) {
        const entry = DesktopEntries.byId(player?.desktopEntry ?? "")
            ?? DesktopEntries.heuristicLookup(player?.identity ?? "");
        const icon = entry?.icon ?? "";
        return Quickshell.iconPath(Quickshell.hasThemeIcon(icon) ? icon : "audio-x-generic");
    }
}
