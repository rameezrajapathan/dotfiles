pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.bar

Singleton {
    id: root

    readonly property int barCount: 36
    readonly property bool active: Media.active?.isPlaying ?? false
    property var levels: []

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
