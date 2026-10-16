pragma Singleton

import Quickshell
import QtQuick

// How panels (Sheet.qml) come out of the bar and go back, picked in Settings > Effects. Each style
// has an opening curve and length, and a shape for a progress p (0 closed .. 1 open; Spring goes
// a little past 1): the body's width (w) and height (h) as fractions between the pill and full
// size, its slide (y, in sheet heights), opacity (body) and scale, and the content's opacity,
// scale and rise (cy, px). Closing is a quick ease-out in every style.
Singleton {
    id: root

    readonly property var styles: [
        { id: "slide", label: "Slide", icon: "south", ms: 340, easing: Easing.OutQuint,
            description: "Slides down from under the pill." },
        { id: "morph", label: "Morph", icon: "unfold_more", ms: 500, easing: Easing.OutExpo,
            description: "The pill stretches into the panel; the content fades in as it settles." },
        { id: "spring", label: "Spring", icon: "airwave", ms: 560, easing: Easing.OutBack, overshoot: 1.3,
            description: "Morph with a soft overshoot, like it has a little weight." },
        { id: "liquid", label: "Liquid", icon: "water_drop", ms: 560, easing: Easing.OutQuint,
            description: "Widens first, then pours down." },
        { id: "reveal", label: "Reveal", icon: "vertical_align_bottom", ms: 400, easing: Easing.OutQuint,
            description: "Stays in place and is uncovered from the top, its content rising in." },
        { id: "fade", label: "Fade", icon: "gradient", ms: 240, easing: Easing.OutCubic,
            description: "A quick fade with a slight grow. The calmest." }
    ]
    readonly property int closeMs: 240

    readonly property string style: Settings.appearance.panelAnimation
    // 0.5 .. 2, faster above 1
    readonly property real speed: Math.max(0.25, Settings.appearance.panelSpeed)

    function info(id) {
        return styles.find(s => s.id === id) ?? styles[0];
    }

    function openDuration(id) {
        return Theme.ms(Math.round(info(id).ms / speed));
    }

    function closeDuration() {
        return Theme.ms(Math.round(closeMs / speed));
    }

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function shape(id, p) {
        const c = clamp(p);
        switch (id) {
        case "morph":
        case "spring":
            return { w: p, h: p, y: 0, body: 1, bodyScale: 1, content: clamp((p - 0.45) / 0.55), scale: 0.97 + 0.03 * c, cy: 0, reveal: false };
        case "liquid":
            return { w: clamp(p / 0.6), h: clamp((p - 0.12) / 0.88), y: 0, body: 1, bodyScale: 1, content: clamp((p - 0.6) / 0.4), scale: 1, cy: 0, reveal: false };
        case "reveal":
            return { w: 1, h: c, y: 0, body: 1, bodyScale: 1, content: clamp(p * 1.6), scale: 1, cy: -12 * (1 - c), reveal: true };
        case "fade":
            return { w: 1, h: 1, y: 0, body: c, bodyScale: 0.94 + 0.06 * c, content: c, scale: 0.94 + 0.06 * c, cy: 0, reveal: false };
        }
        // slide
        return { w: 1, h: 1, y: c - 1, body: 1, bodyScale: 1, content: 1, scale: 1, cy: 0, reveal: false };
    }
}
