import Quickshell
import Quickshell.Io
import QtQuick

Process {
    id: root

    property int interval: 0
    signal loaded(var json)
    signal failed(string error)

    function poll() {
        if (!running)
            running = true;
    }

    stdout: StdioCollector {
        onStreamFinished: {
            let json;
            try {
                json = JSON.parse(text);
            } catch (e) {
                root.failed(String(e));
                return;
            }
            root.loaded(json);
        }
    }

    readonly property Timer ticker: Timer {
        interval: Math.max(1, root.interval)
        running: root.interval > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
