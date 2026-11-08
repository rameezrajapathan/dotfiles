pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/clipboard.sh"
    readonly property string thumbDir: Quickshell.env("XDG_RUNTIME_DIR") + "/quickshell-clipboard"
    property var clips: []
    property var pins: []
    property int thumbRevision: 0

    function refresh() {
        clipReader.running = true;
        pinReader.running = true;
    }

    function thumb(clip) {
        return clip.image ? "file://" + thumbDir + "/" + clip.id + ".png?" + thumbRevision : "";
    }

    function copy(text) {
        if (text)
            Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function copyClip(clip) {
        Quickshell.execDetached(["sh", "-c", "cliphist list | grep -m1 \"^" + clip.id + "\t\" | cliphist decode | wl-copy"]);
    }

    function copyPin(pin) {
        Quickshell.execDetached([script, "copy-pin", pin.file]);
    }

    function run(command) {
        changer.command = command;
        changer.running = true;
    }

    function remove(clip) {
        run(["sh", "-c", "cliphist list | grep -m1 \"^" + clip.id + "\t\" | cliphist delete"]);
    }

    function pin(clip) {
        run([script, "pin", clip.id]);
    }

    function unpin(pin) {
        run([script, "unpin", pin.file]);
    }

    function clear() {
        run([script, "wipe"]);
    }

    Process {
        id: pinReader
        command: [root.script, "pins"]
        stdout: StdioCollector {
            onStreamFinished: root.pins = text.split("\n").filter(l => l.includes("\t")).map(l => {
                const [file, body] = [l.slice(0, l.indexOf("\t")), l.slice(l.indexOf("\t") + 1)];
                return { file: file, text: body === "[[ image ]]" ? "image" : body, image: body === "[[ image ]]" };
            })
        }
    }

    Process {
        id: clipReader
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const body = line.slice(tab + 1);
                    const bin = body.match(/^\[\[ binary data (.+) ]]$/);
                    list.push({ id: line.slice(0, tab), text: bin ? "image " + bin[1] : body, image: bin ? bin[1] : "" });
                }
                root.clips = list;
                const ids = list.filter(c => c.image).slice(0, 40).map(c => c.id);
                if (ids.length > 0) {
                    thumbWriter.command = ["sh", "-c", `mkdir -p "$0" && for id in "$@"; do
                        [ -s "$0/$id.png" ] || cliphist list | grep -m1 "^$id	" | cliphist decode > "$0/$id.png"
                    done`, root.thumbDir].concat(ids);
                    thumbWriter.running = true;
                }
            }
        }
    }

    Process {
        id: thumbWriter
        onExited: root.thumbRevision++
    }

    Process {
        id: changer
        onExited: root.refresh()
    }
}
