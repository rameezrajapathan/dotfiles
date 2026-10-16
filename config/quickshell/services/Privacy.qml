pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    readonly property var captures: nodes.filter(n => n.isStream && !n.isSink)
    PwObjectTracker { objects: root.captures }

    function prop(node, key) {
        return String(node.properties?.[key] ?? "");
    }

    function appName(node) {
        return prop(node, "application.name") || prop(node, "application.process.binary") || node.description || node.name;
    }

    function unique(list) {
        return list.filter((v, i) => v && list.indexOf(v) === i);
    }

    readonly property var micApps: unique(captures
        .filter(n => prop(n, "media.class") === "Stream/Input/Audio" && prop(n, "stream.capture.sink") !== "true"
            && !prop(n, "target.object").endsWith(".monitor"))
        .map(appName))

    readonly property var screenNodes: nodes.filter(n => n.name.startsWith("xdph-streaming"))
    readonly property bool screenShared: screenNodes.length > 0
    readonly property var videoStreams: captures.filter(n => prop(n, "media.class") === "Stream/Input/Video")
    readonly property var screenApps: screenShared ? unique(videoStreams.map(appName)) : []

    property var directCameraApps: []
    readonly property var cameraApps: unique((screenShared ? [] : videoStreams.map(appName)).concat(directCameraApps))

    readonly property bool mic: micApps.length > 0
    readonly property bool camera: cameraApps.length > 0
    readonly property bool active: mic || camera || screenShared

    readonly property string summary: [
        mic ? "Microphone: " + micApps.join(", ") : "",
        camera ? "Camera: " + cameraApps.join(", ") : "",
        screenShared ? "Screen: " + (screenApps.join(", ") || "shared") : ""
    ].filter(s => s).join("  ·  ")

    Process {
        id: cameraCheck
        command: ["sh", "-c", `ls /dev/video* >/dev/null 2>&1 || exit 0
            for p in $(fuser /dev/video* 2>/dev/null | tr -cs '0-9' ' '); do
                cat "/proc/$p/comm" 2>/dev/null
            done | sort -u | grep -vxE 'pipewire|wireplumber'`]
        stdout: StdioCollector {
            onStreamFinished: {
                const apps = text.split("\n").filter(s => s !== "");
                if (JSON.stringify(apps) !== JSON.stringify(root.directCameraApps))
                    root.directCameraApps = apps;
            }
        }
    }
    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!cameraCheck.running) cameraCheck.running = true
    }
}
