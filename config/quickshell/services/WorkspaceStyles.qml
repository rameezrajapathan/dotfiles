pragma Singleton

import Quickshell
import QtQuick
import qs.bar

Singleton {
    readonly property var styles: [
        { id: "focus", label: "Focus", icon: "counter_1", labels: true,
            description: "Just the current workspace's number, rolling like the switch animation." },
        { id: "numbers", label: "Numbers", icon: "123", labels: true, glide: true,
            description: "Every workspace's number, the current one in an accent circle." },
        { id: "boxes", label: "Boxes", icon: "grid_view", labels: true,
            description: "Numbered tiles, the classic tiling-WM look." },
        { id: "underline", label: "Underline", icon: "format_underlined", labels: true, glide: true,
            description: "Numbers with a line under the current one." },
        { id: "dots", label: "Dots", icon: "more_horiz", glide: true,
            description: "A dot per workspace; the current one is bigger and in the accent color." },
        { id: "pills", label: "Pills", icon: "linear_scale",
            description: "Dots where the current one stretches into a pill." },
        { id: "vpills", label: "Vertical pills", icon: "view_column",
            description: "Thin upright pills; the current one stands tallest, empty ones shortest." },
        { id: "icons", label: "App icons", icon: "apps", glide: true,
            description: "The app last used on each workspace; empty ones show their number." }
    ]

    readonly property var labelStyles: [
        { value: "arabic", label: "1 2 3" },
        { value: "roman", label: "I II III" },
        { value: "kanji", label: "一 二 三" }
    ]

    function info(id) {
        return styles.find(s => s.id === id) ?? styles[0];
    }

    function label(n, style) {
        if (n <= 0)
            return "";
        if (style === "roman") {
            const table = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
                [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
            let out = "";
            for (const [v, s] of table)
                for (; n >= v; n -= v)
                    out += s;
            return out;
        }
        if (style === "kanji" && n < 100) {
            const digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"];
            const tens = Math.floor(n / 10);
            return (tens > 1 ? digits[tens] : "") + (tens > 0 ? "十" : "") + digits[n % 10];
        }
        return String(n);
    }
}
