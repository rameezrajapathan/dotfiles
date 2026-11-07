pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/vpn.py"
    property var connections: []
    property var details: []
    readonly property bool anyActive: connections.some(c => c.active)
    property var pending: ({})
    property var errors: ({})
    property var request: null
    property string requestError: ""
    property bool requestBusy: false
    property var logLines: []
    property string logFor: ""
    property bool loading: false

    function detail(uuid) {
        return details.find(d => d.uuid === uuid) ?? null;
    }

    function byName(name) {
        return connections.find(c => c.name === name || c.uuid === name) ?? null;
    }

    function refresh() {
        poll.running = true;
        loadDetails();
    }

    function loadDetails() {
        if (lister.running) {
            listAgain = true;
            return;
        }
        loading = true;
        lister.running = true;
    }
    property bool listAgain: false

    function run(args, input, done) {
        const proc = runner.createObject(root, { args: args, input: input ?? "", done: done ?? null });
        proc.running = true;
    }

    function setPending(uuid, on) {
        const p = Object.assign({}, pending);
        if (on === undefined)
            delete p[uuid];
        else
            p[uuid] = on;
        pending = p;
    }

    function setError(uuid, text) {
        const e = Object.assign({}, errors);
        if (text)
            e[uuid] = text;
        else
            delete e[uuid];
        errors = e;
    }

    function handle(uuid, name, result) {
        setPending(uuid);
        if (result.ok) {
            setError(uuid, "");
            if (request && request.uuid === uuid)
                request = null;
        } else if (result.needsPassword) {
            requestError = result.error && result.hint === "auth" ? result.error : "";
            requestBusy = false;
            request = { uuid: uuid, name: name, remember: result.remember ?? true, username: detail(uuid)?.username ?? "" };
        } else {
            setError(uuid, result.error ?? "The connection failed.");
            if (request && request.uuid === uuid) {
                requestError = result.error ?? "";
                requestBusy = false;
            } else {
                Quickshell.execDetached(["notify-send", "-a", "VPN", "-u", "critical", "-i", "network-vpn", "Couldn't connect to " + name, result.error ?? ""]);
            }
        }
        refresh();
    }

    function toggle(name) {
        const conn = byName(name);
        if (!conn || conn.uuid in pending)
            return;
        if (conn.active)
            disconnect(conn.uuid);
        else
            connect(conn.uuid);
    }

    function connect(uuid, password, remember) {
        const conn = connections.find(c => c.uuid === uuid);
        const name = conn?.name ?? uuid;
        setPending(uuid, true);
        setError(uuid, "");
        if (password !== undefined) {
            requestBusy = true;
            requestError = "";
            run(["up", uuid, "--password-stdin"].concat(remember ? ["--remember"] : []), password + "\n", r => handle(uuid, name, r));
        } else {
            run(["up", uuid], "", r => handle(uuid, name, r));
        }
    }

    function disconnect(uuid) {
        const conn = connections.find(c => c.uuid === uuid);
        setPending(uuid, false);
        run(["down", uuid], "", r => handle(uuid, conn?.name ?? uuid, r));
    }

    function cancelRequest() {
        if (request)
            setPending(request.uuid);
        request = null;
        requestBusy = false;
        requestError = "";
    }

    function set(uuid, key, value, done) {
        run(["set", uuid, key, String(value)], "", r => {
            if (!r.ok)
                Quickshell.execDetached(["notify-send", "-a", "VPN", "-u", "critical", "Couldn't change the VPN", r.error ?? ""]);
            loadDetails();
            if (done)
                done(r);
        });
    }

    function setPassword(uuid, password) {
        run(["password", uuid], password + "\n", r => loadDetails());
    }

    function pickCert(uuid, which) {
        const proc = picker.createObject(root, { uuid: uuid, which: which });
        proc.running = true;
    }

    function showLog(uuid) {
        logFor = uuid;
        logLines = [];
        run(["log", uuid], "", r => logLines = r.lines ?? []);
    }

    function remove(uuid) {
        Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", uuid]);
        removeSoon.restart();
    }

    function editAll(uuid) {
        Quickshell.execDetached(["nm-connection-editor", "--edit", uuid]);
    }

    function add(mode) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/vpn-add.sh", mode]);
        removeSoon.restart();
    }

    Component {
        id: runner
        Process {
            id: proc
            property var args: []
            property string input: ""
            property var done: null
            command: ["python3", "-I", root.script].concat(args)
            stdinEnabled: input !== ""
            onStarted: if (input !== "") {
                write(input);
                stdinEnabled = false;
            }
            stdout: StdioCollector {
                onStreamFinished: {
                    let result = { ok: false, error: "No answer from vpn.py" };
                    try {
                        result = JSON.parse(text);
                    } catch (e) {}
                    if (proc.done)
                        proc.done(result);
                    proc.destroy();
                }
            }
        }
    }

    Component {
        id: picker
        Process {
            id: pick
            property string uuid
            property string which
            command: ["zenity", "--file-selection", "--title", which === "ca" ? "Pick the CA certificate" : which === "cert" ? "Pick your certificate" : "Pick your private key",
                "--filename", Quickshell.env("HOME") + "/Downloads/", "--file-filter", "Certificates | *.pem *.crt *.cer *.key *.p12", "--file-filter", "All files | *"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const path = text.trim();
                    if (path)
                        root.run(["cert", pick.uuid, pick.which, path], "", r => root.loadDetails());
                    pick.destroy();
                }
            }
        }
    }

    Process {
        id: lister
        command: ["python3", "-I", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.details = JSON.parse(text);
                } catch (e) {}
                root.loading = false;
                if (root.listAgain) {
                    root.listAgain = false;
                    root.loadDetails();
                }
            }
        }
    }

    Process {
        id: poll
        command: ["nmcli", "-t", "-f", "UUID,NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                for (const line of text.trim().split("\n")) {
                    const fields = line.replace(/\\\\/g, "\u0001").replace(/\\:/g, "\u0002").split(":").map(f => f.replace(/\u0002/g, ":").replace(/\u0001/g, "\\"));
                    if (fields.length < 4)
                        continue;
                    const type = fields[2];
                    if (type === "vpn" || type === "wireguard")
                        result.push({ uuid: fields[0], name: fields[1], active: fields[3] === "yes" });
                }
                const changed = JSON.stringify(result) !== JSON.stringify(root.connections);
                root.connections = result;
                if (changed)
                    root.loadDetails();
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    Timer {
        id: removeSoon
        interval: 1500
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "vpn"
        function toggle(name: string): void {
            root.toggle(name);
        }
        function connect(name: string): void {
            const c = root.byName(name);
            if (c && !c.active)
                root.connect(c.uuid);
        }
        function cancel(): void {
            root.cancelRequest();
        }
        function disconnect(name: string): void {
            const c = root.byName(name);
            if (c && c.active)
                root.disconnect(c.uuid);
        }
    }
}
