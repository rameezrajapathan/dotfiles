pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Media players over MPRIS: Spotify, browsers (YouTube Music, etc.), mpv, VLC and so on.
// `active` is the one the bar and MediaPanel show: the player picked in the panel, unless another
// one is playing while it isn't; otherwise whatever is playing, otherwise the first player.
// `qs ipc call media toggle` opens the panel on the focused monitor's bar.
Singleton {
    id: root

    signal panelToggleRequested()

    IpcHandler {
        target: "media"
        function toggle(): void {
            root.panelToggleRequested();
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

    // 3:07 from seconds
    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}
