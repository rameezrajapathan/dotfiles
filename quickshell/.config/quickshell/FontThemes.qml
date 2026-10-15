pragma Singleton

import Quickshell
import QtQuick

// Font pairings for Settings > Fonts: interface, display (titles, lock screen clock) and terminal.
// Only themes whose fonts are all installed are offered; picking another font afterwards makes
// it "Custom".
Singleton {
    id: root

    readonly property var all: [
        { id: "original", label: "Original", vibe: "Code-flavored, the pikadots look",
          font: "FiraCode Nerd Font Propo", displayFont: "Fira Sans", monoFont: "FiraCode Nerd Font Mono" },
        { id: "clean", label: "Clean", vibe: "Neutral and sharp, like a modern OS",
          font: "Inter", displayFont: "Inter", monoFont: "JetBrainsMono Nerd Font Mono" },
        { id: "modern", label: "Modern", vibe: "Crisp Swiss lines",
          font: "Geist", displayFont: "Geist", monoFont: "JetBrainsMono Nerd Font Mono" },
        { id: "google", label: "Material", vibe: "Soft, round and familiar",
          font: "Google Sans Flex", displayFont: "Google Sans Flex", monoFont: "MesloLGS Nerd Font Mono" },
        { id: "geometric", label: "Geometric", vibe: "Circles and straight lines",
          font: "Outfit", displayFont: "Sora", monoFont: "JetBrainsMono Nerd Font Mono" },
        { id: "friendly", label: "Friendly", vibe: "Rounded and warm",
          font: "Rubik", displayFont: "Rubik", monoFont: "FantasqueSansM Nerd Font Mono" },
        { id: "elegant", label: "Elegant", vibe: "Light, refined headings",
          font: "Manrope", displayFont: "Plus Jakarta Sans", monoFont: "Iosevka Nerd Font Mono" },
        { id: "playful", label: "Playful", vibe: "Bouncy and lively",
          font: "Figtree", displayFont: "Outfit", monoFont: "FantasqueSansM Nerd Font Mono" },
        { id: "readable", label: "Readable", vibe: "Made for easy reading",
          font: "Lexend", displayFont: "Lexend", monoFont: "Hack" },
        { id: "terminal", label: "Hacker", vibe: "Monospace everywhere",
          font: "JetBrainsMono Nerd Font Propo", displayFont: "JetBrainsMono Nerd Font Propo", monoFont: "JetBrainsMono Nerd Font Mono" },
        { id: "gnome", label: "GNOME", vibe: "The Adwaita system fonts",
          font: "Adwaita Sans", displayFont: "Cantarell", monoFont: "Adwaita Mono" }
    ]

    readonly property var installed: Qt.fontFamilies()
    readonly property var themes: all.filter(t => [t.font, t.displayFont, t.monoFont].every(f => installed.includes(f)))

    readonly property string current: {
        const a = Settings.appearance;
        return themes.find(t => t.font === a.font && t.displayFont === a.displayFont && t.monoFont === a.monoFont)?.id ?? "custom";
    }

    function apply(theme) {
        Settings.appearance.font = theme.font;
        Settings.appearance.displayFont = theme.displayFont;
        Settings.appearance.monoFont = theme.monoFont;
        Settings.applyFonts();
    }
}
