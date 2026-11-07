import json
import os
import re
import shutil
import subprocess
import sys
import time

STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "pikadots-vpn.json")
CERTS = os.path.expanduser("~/.local/share/networkmanagement/certificates/nm-openvpn")
MODERN = "AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305"


def nm(*args, stdin=None):
    return subprocess.run(["nmcli", *args], input=stdin, capture_output=True, text=True)


def fields(uuid, names, active=False):
    out = nm("-m", "multiline", "-t", "-f", ",".join(names), "connection", "show", uuid).stdout
    result = {}
    for line in out.splitlines():
        key, _, value = line.partition(":")
        value = value.replace("\\:", ":").replace("\\\\", "\\")
        key = re.sub(r"\[\d+\]$", "", key)
        if key in result and value:
            result[key] += ", " + value
        else:
            result[key] = value
    return result


def parse_data(text):
    data = {}
    if not text or text == "--":
        return data
    for part in re.split(r"(?<!\\), ", text):
        key, _, value = part.partition(" = ")
        data[key.strip()] = value.replace("\\,", ",").strip()
    return data


def vpn_list():
    out = nm("-t", "-f", "UUID,NAME,TYPE,ACTIVE", "connection", "show").stdout
    items = []
    for line in out.splitlines():
        parts = re.split(r"(?<!\\):", line)
        if len(parts) < 4:
            continue
        uuid, name, kind, active = parts[0], parts[1].replace("\\:", ":"), parts[2], parts[3] == "yes"
        if kind not in ("vpn", "wireguard"):
            continue
        items.append((uuid, name, kind, active))
    return items


def password_saved(uuid):
    secrets = nm("-s", "-g", "vpn.secrets", "connection", "show", uuid).stdout
    return bool(re.search(r"(^|, )password = \S", secrets))


def describe(uuid, name, kind, active):
    f = fields(uuid, ["connection.autoconnect", "vpn.service-type", "vpn.data", "ipv4.never-default",
                      "ipv4.dns", "ipv4.dns-search", "ipv4.ignore-auto-dns", "wireguard.peers"])
    data = parse_data(f.get("vpn.data", ""))
    service = f.get("vpn.service-type", "")
    item = {
        "uuid": uuid,
        "name": name,
        "kind": "wireguard" if kind == "wireguard" else service.rsplit(".", 1)[-1] or "vpn",
        "active": active,
        "autoconnect": f.get("connection.autoconnect") == "yes",
        "allTraffic": f.get("ipv4.never-default") != "yes",
        "dns": "" if f.get("ipv4.dns") in (None, "--") else f["ipv4.dns"].replace(",", " "),
        "search": "" if f.get("ipv4.dns-search") in (None, "--") else f["ipv4.dns-search"].replace(",", " "),
        "editable": kind == "vpn" and service.endswith("openvpn"),
    }
    if item["editable"]:
        flags = data.get("password-flags", "0")
        uses_password = data.get("connection-type", "") in ("password", "password-tls")
        item.update({
            "servers": [r.strip() for r in data.get("remote", "").split(",") if r.strip()],
            "username": data.get("username", ""),
            "usesPassword": uses_password,
            "askPassword": uses_password and flags == "2",
            "passwordSaved": uses_password and flags == "0" and password_saved(uuid),
            "compat": "SECLEVEL=0" in data.get("tls-cipher", ""),
            "cipher": data.get("cipher", ""),
            "ca": data.get("ca", ""),
            "cert": data.get("cert", ""),
            "key": data.get("key", ""),
            "connectionType": data.get("connection-type", ""),
        })
    if active:
        info = fields(uuid, ["IP4.ADDRESS", "GENERAL.STATE"])
        item["address"] = info.get("IP4.ADDRESS", "").split("/")[0]
        item["state"] = info.get("GENERAL.STATE", "")
    state = load_state().get(uuid, {})
    item["since"] = state.get("since", 0) if active else 0
    item["error"] = "" if active else state.get("error", "")
    item["hint"] = "" if active else state.get("hint", "")
    return item


def load_state():
    try:
        with open(STATE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_state(uuid, **values):
    state = load_state()
    state[uuid] = values
    tmp = STATE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, STATE)


def journal_since(since):
    out = subprocess.run(["journalctl", "--since", since, "--no-pager", "-o", "cat"],
                         capture_output=True, text=True).stdout
    keep = [l for l in out.splitlines()
            if re.search(r"openvpn|vpn\[|nm-openvpn", l, re.I) and not re.search(r"password|auth-token|secret", l, re.I)]
    return keep


def diagnose(lines, nmcli_error):
    lines = [l for l in lines if not re.match(r"(DEPRECATED|OpenVPN \d|WARNING: Compression)", l)]
    text = "\n".join(lines) + "\n" + nmcli_error
    rules = [
        (r"AUTH_FAILED|auth-failure|Authenticate/Decrypt", "The server didn't accept the username or password.", "auth"),
        (r"secrets were required|no secrets|Secrets were required", "No password was given.", "password"),
        (r"Connection refused|Network is unreachable|Connection timed out|connect-timeout|timed out|Timeout", "The server didn't answer. Check the server address, or try another network.", ""),
        (r"no shared cipher|Unsupported cipher|cipher \S+ not (supported|found|allowed)|NCP: (no|failed)|failed to negotiate cipher", "The server wants a cipher this computer doesn't offer. Turn on Compatibility with older servers.", "compat"),
        (r"RESOLVE|Cannot resolve host|Name or service not known", "Couldn't look up the server's name. Check the server address and your internet connection.", ""),
        (r"CA md too weak|ca key too small|ee key too small|VERIFY ERROR|certificate verify failed|unsupported certificate", "The server's certificate wasn't accepted. Turn on Compatibility with older servers, or check the CA certificate.", "compat"),
        (r"TLS key negotiation failed|TLS handshake failed|TLS Error", "The server didn't finish the secure handshake. The server address or port may be wrong, or a firewall is in the way.", ""),
        (r"Cannot load (private key|certificate|CA)|No such file", "A certificate file is missing. Pick it again under Certificates.", ""),
    ]
    for pattern, message, hint in rules:
        if re.search(pattern, text, re.I):
            return message, hint
    last = next((l for l in reversed(lines) if not l.startswith("<info>")), "")
    if nmcli_error.strip():
        return nmcli_error.strip().replace("Error: ", "").splitlines()[-1], ""
    return last or "The connection failed.", ""


def up(uuid, password=None, remember=False):
    since = time.strftime("%Y-%m-%d %H:%M:%S")
    item = next((v for v in vpn_list() if v[0] == uuid), None)
    if not item:
        return {"ok": False, "error": "That VPN no longer exists."}
    info = describe(*item)
    if info.get("usesPassword") and password is None and not info.get("passwordSaved"):
        return {"ok": False, "needsPassword": True, "name": info["name"], "remember": not info.get("askPassword")}
    if password is not None and remember:
        nm("connection", "modify", uuid, "+vpn.data", "password-flags=0")
        nm("connection", "modify", uuid, "vpn.secrets", "password=" + password)
        password_arg = None
    else:
        password_arg = password
    args = ["--wait", "60", "connection", "up", uuid]
    stdin = None
    if password_arg is not None:
        args += ["passwd-file", "/dev/stdin"]
        stdin = "vpn.secrets.password:" + password_arg + "\n"
    result = nm(*args, stdin=stdin)
    if result.returncode == 0:
        save_state(uuid, since=int(time.time()))
        return {"ok": True}
    time.sleep(1)
    message, hint = diagnose(journal_since(since), result.stderr)
    if hint == "auth" and info.get("passwordSaved"):
        nm("connection", "modify", uuid, "vpn.secrets", "")
    save_state(uuid, error=message, hint=hint, at=int(time.time()))
    return {"ok": False, "error": message, "hint": hint, "name": info["name"],
            "needsPassword": hint in ("auth", "password") and info.get("usesPassword", False)}


def down(uuid):
    result = nm("connection", "down", uuid)
    save_state(uuid)
    return {"ok": result.returncode == 0, "error": result.stderr.strip()}


def escape(value):
    return value.replace(",", "\\,")


def set_value(uuid, key, value):
    on = value in ("yes", "true", "1")
    if key == "name":
        r = nm("connection", "modify", uuid, "connection.id", value.strip())
    elif key == "servers":
        servers = [s.strip() for s in re.split(r"[\s,]+", value) if s.strip()]
        if not servers:
            return {"ok": False, "error": "Add at least one server."}
        r = nm("connection", "modify", uuid, "+vpn.data", "remote=" + escape(", ".join(servers)))
    elif key == "username":
        r = nm("connection", "modify", uuid, "+vpn.data", "username=" + value.strip())
    elif key == "askPassword":
        r = nm("connection", "modify", uuid, "+vpn.data", "password-flags=" + ("2" if on else "0"))
        if on:
            nm("connection", "modify", uuid, "vpn.secrets", "")
    elif key == "allTraffic":
        r = nm("connection", "modify", uuid, "ipv4.never-default", "no" if on else "yes", "ipv6.never-default", "no" if on else "yes")
    elif key == "autoconnect":
        r = nm("connection", "modify", uuid, "connection.autoconnect", "yes" if on else "no")
    elif key == "dns":
        servers = " ".join(value.replace(",", " ").split())
        r = nm("connection", "modify", uuid, "ipv4.dns", servers, "ipv4.ignore-auto-dns", "yes" if servers else "no")
    elif key == "search":
        r = nm("connection", "modify", uuid, "ipv4.dns-search", " ".join(value.replace(",", " ").split()))
    elif key == "compat":
        if on:
            r = nm("connection", "modify", uuid, "+vpn.data", "tls-cipher=DEFAULT:@SECLEVEL=0", "+vpn.data", "tls-version-min=1.0")
        else:
            r = nm("connection", "modify", uuid, "-vpn.data", "tls-cipher", "-vpn.data", "tls-version-min")
    elif key == "ciphers":
        data = parse_data(fields(uuid, ["vpn.data"]).get("vpn.data", ""))
        cipher = data.get("cipher", "")
        extra = ":" + cipher if cipher and cipher not in MODERN else ""
        args = ["+vpn.data", "data-ciphers=" + MODERN + extra]
        if extra:
            args += ["+vpn.data", "data-ciphers-fallback=" + cipher]
        r = nm("connection", "modify", uuid, *args)
    else:
        return {"ok": False, "error": "Unknown setting " + key}
    return {"ok": r.returncode == 0, "error": r.stderr.strip().replace("Error: ", "")}


def set_password(uuid, password):
    r = nm("connection", "modify", uuid, "+vpn.data", "password-flags=0")
    if r.returncode == 0:
        r = nm("connection", "modify", uuid, "vpn.secrets", "password=" + password)
    return {"ok": r.returncode == 0, "error": r.stderr.strip()}


def set_cert(uuid, which, path):
    if which not in ("ca", "cert", "key") or not os.path.isfile(path):
        return {"ok": False, "error": "Pick a certificate file."}
    name = fields(uuid, ["connection.id"]).get("connection.id", uuid)
    os.makedirs(CERTS, exist_ok=True)
    target = os.path.join(CERTS, re.sub(r"[^\w.-]", "_", name) + "-" + which + ".pem")
    shutil.copyfile(path, target)
    os.chmod(target, 0o600)
    r = nm("connection", "modify", uuid, "+vpn.data", which + "=" + target)
    return {"ok": r.returncode == 0, "error": r.stderr.strip()}


def log(uuid):
    name = fields(uuid, ["connection.id"]).get("connection.id", "")
    lines = journal_since("-2 days")
    keep, take = [], False
    for line in lines:
        if "starting openvpn" in line or "connection-activate" in line:
            take = name in line or uuid in line
        if take:
            keep.append(re.sub(r"^<\w+>\s+\[[\d.]+\]\s*", "", line))
    return {"ok": True, "lines": keep[-60:]}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    arg = sys.argv[2:]
    if cmd == "list":
        out = [describe(*v) for v in vpn_list()]
    elif cmd == "up":
        password = sys.stdin.readline().rstrip("\n") if "--password-stdin" in arg else None
        out = up(arg[0], password, "--remember" in arg)
    elif cmd == "down":
        out = down(arg[0])
    elif cmd == "toggle":
        match = next((v for v in vpn_list() if arg[0] in (v[0], v[1])), None)
        if not match:
            out = {"ok": False, "error": "No VPN called " + arg[0]}
        else:
            out = down(match[0]) if match[3] else up(match[0])
    elif cmd == "set":
        out = set_value(arg[0], arg[1], arg[2] if len(arg) > 2 else "")
    elif cmd == "password":
        out = set_password(arg[0], sys.stdin.readline().rstrip("\n"))
    elif cmd == "cert":
        out = set_cert(arg[0], arg[1], arg[2])
    elif cmd == "log":
        out = log(arg[0])
    else:
        out = {"ok": False, "error": "usage: vpn.py list|up|down|toggle|set|password|cert|log"}
    print(json.dumps(out))


main()
