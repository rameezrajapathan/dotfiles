#!/usr/bin/env python3
import colorsys
import json
import math
import os
import subprocess
import sys

SIZE = 64

HUES = {
    "red": "#f38ba8",
    "green": "#a6e3a1",
    "yellow": "#f9e2af",
    "blue": "#89b4fa",
    "magenta": "#f5c2e7",
    "cyan": "#94e2d5",
    "peach": "#fab387",
    "maroon": "#eba0ac",
    "mauve": "#cba6f7",
    "sky": "#89dceb",
    "sapphire": "#74c7ec",
    "lavender": "#b4befe",
    "rosewater": "#f5e0dc",
    "flamingo": "#f2cdcd",
}

def to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def from_linear(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

def oklab(r, g, b):
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )

def linear_rgb(L, a, b):
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )

def hex_to_lch(color):
    r, g, b = (to_linear(int(color[i : i + 2], 16) / 255) for i in (1, 3, 5))
    L, a, b = oklab(r, g, b)
    return L, math.hypot(a, b), math.atan2(b, a)

def lch_to_hex(L, C, h):
    while True:
        rgb = linear_rgb(L, C * math.cos(h), C * math.sin(h))
        if all(-1e-4 <= c <= 1 + 1e-4 for c in rgb) or C < 1e-4:
            break
        C *= 0.95
    return "#" + "".join(f"{round(min(1, max(0, from_linear(min(1, max(0, c))))) * 255):02x}" for c in rgb)

def analyze(path):
    raw = subprocess.run(
        ["magick", path + "[0]", "-resize", f"{SIZE}x{SIZE}!", "-depth", "8", "rgb:-"],
        capture_output=True,
        check=True,
    ).stdout
    lightness, chroma, saturation = [], [], []
    sum_a = sum_b = 0.0
    for i in range(0, len(raw) - 2, 3):
        L, a, b = oklab(*(to_linear(c / 255) for c in raw[i : i + 3]))
        lightness.append(L)
        chroma.append(math.hypot(a, b))
        saturation.append(chroma[-1] / max(L, 0.15))
        sum_a += a
        sum_b += b
    n = len(lightness)
    return {
        "lightness": sum(lightness) / n,
        "colorfulness": sum(saturation) / n,
        "accent": sum(c > 0.08 for c in chroma) / n,
        "hue": math.atan2(sum_b, sum_a),
        "hue_strength": math.hypot(sum_a, sum_b) / n,
    }

def hue_gap(a, b):
    return abs(math.atan2(math.sin(a - b), math.cos(a - b)))

def wallpaper_colors(path, mode):
    found = []
    for index in range(6):
        result = subprocess.run(
            ["matugen", "image", path, "--type", "scheme-content", "--mode", mode,
             "--source-color-index", str(index), "--dry-run", "--json", "hex"],
            capture_output=True,
        )
        if result.returncode != 0:
            break
        try:
            color = json.loads(result.stdout)["colors"]["primary"]["default"]["color"]
        except (ValueError, KeyError):
            break
        if color not in found and (not found or hex_to_lch(color)[1] > 0.04):
            found.append(color)
    return found

def multi_colors(path, mode):
    found = wallpaper_colors(path, mode)
    if not found:
        return []
    L, C, h = hex_to_lch(found[0])
    picked = []
    for _ in range(2):
        taken = [hex_to_lch(found[0])[2]] + [hex_to_lch(c)[2] for c in picked]
        best = max(found[1:], key=lambda c: min(hue_gap(hex_to_lch(c)[2], t) for t in taken), default=None)
        if best and best not in picked and min(hue_gap(hex_to_lch(best)[2], t) for t in taken) > math.radians(28):
            picked.append(best)
    rotations = [math.radians(-65), math.radians(70)]
    while len(picked) < 2:
        picked.append(lch_to_hex(L, max(C, 0.08), h + rotations[len(picked)]))
    return picked

def shade(color):
    r, g, b = (int(color[i : i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = max(0, l - (0.15 if l > 0.5 else 0.1))
    s = min(1, s * 1.1)
    return "#" + "".join(f"{round(c * 255):02x}" for c in colorsys.hls_to_rgb(h, l, s))

def primary(path, scheme, mode):
    result = subprocess.run(
        ["matugen", "image", path, "--type", scheme, "--mode", mode,
         "--source-color-index", "0", "--dry-run", "--json", "hex"],
        capture_output=True,
    )
    try:
        return json.loads(result.stdout)["colors"]["primary"]["default"]["color"]
    except (ValueError, KeyError):
        return ""

def main():
    stats = analyze(sys.argv[1])
    colorful = stats["colorfulness"]

    mode = "light" if stats["lightness"] > 0.6 else "dark"
    if colorful < 0.045:
        scheme = "scheme-neutral" if stats["accent"] > 0.005 else "scheme-monochrome"
    elif colorful < 0.09:
        scheme = "scheme-neutral"
    elif colorful < 0.17:
        scheme = "scheme-tonal-spot"
    else:
        scheme = "scheme-content"
    if os.environ.get("THEME_MODE") in ("light", "dark"):
        mode = os.environ["THEME_MODE"]
    if os.environ.get("THEME_SCHEME", "auto") != "auto":
        scheme = "scheme-" + os.environ["THEME_SCHEME"]
    multi = []
    if scheme == "scheme-multi":
        scheme = "scheme-content"
        multi = multi_colors(sys.argv[1], mode)

    if multi:
        end = multi[0]
    else:
        base = primary(sys.argv[1], scheme, mode)
        end = shade(base) if base else ""

    strength = min(1.15, max(0.15, (colorful - 0.01) / 0.13))
    target_l = {"light": 0.52, "dark": 0.8}[mode]
    ansi = {}
    for name, color in HUES.items():
        L, C, h = hex_to_lch(color)
        if stats["hue_strength"] > 0.01:
            diff = math.atan2(math.sin(stats["hue"] - h), math.cos(stats["hue"] - h))
            h += math.copysign(min(abs(diff) * 0.3, math.radians(8)), diff)
        ansi[name] = lch_to_hex(target_l + (L - 0.8) * 0.5, C * strength * (1.25 if mode == "light" else 1), h)

    json.dump(
        {
            "theme": {"mode": mode, "scheme": scheme, **{k: round(v, 4) for k, v in stats.items()}},
            "ansi": ansi,
            "multi": {"accent2": multi[0] if multi else "", "accent3": multi[1] if multi else "", "end": end.lstrip("#")},
        },
        sys.stdout,
    )

main()
