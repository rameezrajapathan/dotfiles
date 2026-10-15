pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Live audio spectrum from cava, running only while a player is playing. One process feeds both
// the bar's pill (MusicBars) and the Music tab.
Singleton {
    id: root

    readonly property int barCount: 36
    readonly property bool active: Media.active?.isPlaying ?? false
    // barCount levels, 0..1; empty while stopped
    property var levels: []

    // `count` bars from the full spectrum, each the loudest of its group, so peaks survive
    function grouped(count) {
        if (levels.length === 0)
            return [];
        const out = [];
        for (let i = 0; i < count; i++) {
            const from = Math.floor(i * levels.length / count);
            const to = Math.max(from + 1, Math.floor((i + 1) * levels.length / count));
            out.push(Math.max(...levels.slice(from, to)));
        }
        return out;
    }

    // cava in raw mode: one line per frame of semicolon-separated 0..100 levels
    Process {
        running: root.active
        command: ["sh", "-c", `
            conf="\${XDG_RUNTIME_DIR:-/tmp}/quickshell-cava.conf"
            printf '%s\\n' '[general]' 'bars = ${root.barCount}' 'framerate = 45' 'sensitivity = 90' \
                '[output]' 'method = raw' 'raw_target = /dev/stdout' 'data_format = ascii' \
                'ascii_max_range = 100' 'channels = mono' \
                '[smoothing]' 'noise_reduction = 60' > "$conf"
            exec cava -p "$conf"`]
        stdout: SplitParser {
            onRead: data => root.levels = data.split(";").filter(s => s !== "").map(v => Number(v) / 100)
        }
        onRunningChanged: if (!running) root.levels = []
    }
}
