pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string result: ""
    property string expression: ""

    function evaluate(text) {
        expression = text;
        debounce.restart();
    }

    Timer {
        id: debounce
        interval: 120
        onTriggered: {
            qalc.command = ["qalc", "-t", "--", root.expression];
            qalc.running = true;
        }
    }

    Process {
        id: qalc
        stdout: StdioCollector {
            onStreamFinished: root.result = text.trim()
        }
    }
}
