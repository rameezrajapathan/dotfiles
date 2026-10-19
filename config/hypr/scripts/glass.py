#!/usr/bin/env python3
import json
import os
import sys

HOME = os.path.expanduser("~")
SETTINGS = os.path.join(HOME, ".config/pikadots/settings.json")
PRESETS = os.path.join(HOME, ".config/quickshell/services/glass-presets.json")
LUA = os.path.join(HOME, ".local/state/pikadots/glass.lua")


def load(path, fallback):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return fallback


def resolve():
    presets = load(PRESETS, {})
    glass = load(SETTINGS, {}).get("glass", {})
    name = glass.get("preset", "frosted")
    if name == "custom":
        custom = glass.get("custom", {}) or {}
        values = dict(presets.get(custom.get("base", "frosted"), {}))
        values.update({k: v for k, v in custom.items() if k != "base"})
    else:
        values = dict(presets.get(name, presets.get("frosted", {})))
    values["preset"] = name
    values["color"] = bool(glass.get("color", False))
    values["lightAngle"] = glass.get("lightAngle", -40)
    return values


def for_mode(values, mode):
    if mode != "light" or values["preset"] == "off":
        return values
    lift = lambda a: 1 - (1 - a) * 0.55
    values = dict(values)
    for key in ("window", "view", "popover", "terminal", "tint", "card"):
        if key in values:
            values[key] = lift(values[key])
    values["inactiveOpacity"] = 1 - (1 - values["inactiveOpacity"]) * 0.5
    values["brightness"] = max(values["brightness"], 1.0) + 0.08
    values["vibrancy_darkness"] = 0.0
    return values


def hexa(a):
    return f"{max(0, min(255, round(a * 255))):02x}"


def fmt(a):
    return f"{a:.2f}"


def matugen(values, mode):
    rim = values.get("rim", 0)
    light = mode == "light"
    rim_alpha = (0.55 if light else 0.22) * rim
    return {
        "glass": {
            "preset": values["preset"],
            "on": "true" if values["preset"] != "off" else "false",
            "window": fmt(values["window"]),
            "view": fmt(values["view"]),
            "popover": fmt(values["popover"]),
            "terminal": fmt(values["terminal"]),
            "tint": fmt(values["tint"]),
            "window_pct": f"{round(values['window'] * 100)}%",
            "popover_pct": f"{round(values['popover'] * 100)}%",
            "window_hex": hexa(values["window"]),
            "popover_hex": hexa(values["popover"]),
            "terminal_hex": hexa(values["terminal"]),
            "tint_hex": hexa(values["tint"]),
            "rim": fmt(rim),
            "rim_alpha": f"{rim_alpha:.3f}",
            "rim_soft": f"{rim_alpha * 0.5:.3f}",
            "button_radius": "999px" if values["preset"] != "off" else "6px",
            "card_radius": "18px" if values["preset"] != "off" else "12px",
        }
    }


def lua(values, mode):
    if values["preset"] == "off" or not values.get("hyprland", True):
        return "return { enabled = false }\n"
    rim = values.get("rim", 0)
    light = mode == "light"
    neutral = not values.get("color", False)
    rgba = lambda c, a: f'"rgba({c}{hexa(max(0.0, min(1.0, a)))})"'
    edge = "000000" if light else "ffffff"
    active = [rgba("ffffff", 0.55 + 0.4 * rim), rgba(edge, 0.10 if light else 0.08), rgba("ffffff", 0.25 + 0.3 * rim)]
    inactive = [rgba("ffffff", 0.3 + 0.35 * rim), rgba(edge, 0.06 if light else 0.04), rgba("ffffff", 0.12 + 0.15 * rim)]
    angle = int((values.get("lightAngle", -40) + 135) % 360)
    shadow = "rgba(00000030)" if light else "rgba(00000066)"
    glow_on = rgba("ffffff", (0.10 + 0.22 * rim) * (1.3 if light else 1))
    glow_off = rgba("ffffff", (0.05 + 0.1 * rim) * (1.3 if light else 1))
    return (
        "return {\n"
        "\tenabled = true,\n"
        f"\tneutral = {'true' if neutral else 'false'},\n"
        f"\tactive_border = {{ colors = {{ {', '.join(active)} }}, angle = {angle} }},\n"
        f"\tinactive_border = {{ colors = {{ {', '.join(inactive)} }}, angle = {angle} }},\n"
        f"\trim = {active[0]},\n"
        f"\tangle = {angle},\n"
        f"\tspecial_border = {rgba('ffffff', 0.95)},\n"
        "\tconfig = {\n"
        "\t\tdecoration = {\n"
        f"\t\t\tinactive_opacity = {values['inactiveOpacity']},\n"
        "\t\t\tblur = {\n"
        "\t\t\t\tenabled = true,\n"
        f"\t\t\t\tsize = {int(values['blurSize'])},\n"
        f"\t\t\t\tpasses = {int(values['blurPasses'])},\n"
        f"\t\t\t\tvibrancy = {values['vibrancy']},\n"
        f"\t\t\t\tvibrancy_darkness = {values.get('vibrancy_darkness', 0.2)},\n"
        f"\t\t\t\tnoise = {values['noise']},\n"
        f"\t\t\t\tcontrast = {values['contrast']},\n"
        f"\t\t\t\tbrightness = {values['brightness']},\n"
        "\t\t\t\tpopups = true,\n"
        "\t\t\t},\n"
        "\t\t\tshadow = {\n"
        f"\t\t\t\tenabled = {'true' if values['shadows'] else 'false'},\n"
        f"\t\t\t\trange = {int(values['shadowRange'])},\n"
        "\t\t\t\trender_power = 3,\n"
        f'\t\t\t\tcolor = "{shadow}",\n'
        "\t\t\t},\n"
        "\t\t\tglow = {\n"
        f"\t\t\t\tenabled = {'true' if rim > 0 else 'false'},\n"
        f"\t\t\t\trange = {int(8 + 8 * rim)},\n"
        "\t\t\t\trender_power = 3,\n"
        f"\t\t\t\tcolor = {glow_on},\n"
        f"\t\t\t\tcolor_inactive = {glow_off},\n"
        "\t\t\t},\n"
        "\t\t},\n"
        "\t},\n"
        "}\n"
    )


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "json"
    mode = sys.argv[2] if len(sys.argv) > 2 else "dark"
    values = for_mode(resolve(), mode)
    if command == "json":
        print(json.dumps(matugen(values, mode)))
    elif command == "lua":
        os.makedirs(os.path.dirname(LUA), exist_ok=True)
        tmp = LUA + ".tmp"
        with open(tmp, "w") as f:
            f.write(lua(values, mode))
        os.replace(tmp, LUA)
    elif command == "values":
        print(json.dumps(values))
    else:
        print("usage: glass.py json|lua|values [dark|light]", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
