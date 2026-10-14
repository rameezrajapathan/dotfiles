# Colors from the wallpaper

[← README](../README.md)

Picking a wallpaper (Super + Shift + W) runs `hypr/scripts/theme.sh <image>`. It sets the
wallpaper, generates colors with [matugen](https://github.com/InioX/matugen) from the templates in
`matugen/.config/matugen/templates/`, and reloads what's running. Run it without an argument to
regenerate from the current wallpaper. Generated files go to `~/.local/state/theme/`, outside the
repo.

## Light, dark and how colorful

`hypr/scripts/theme-palette.py` looks at the wallpaper first:

- **Bright wallpapers give a light theme**, others a dark one. GTK, icons, websites
  (`color-scheme`) and Neovim switch with it.
- **The scheme follows how colorful it is**: black and white wallpapers give pure greys, muted ones
  a neutral theme, colorful ones a theme built from the wallpaper's own colors.
- **Terminal colors** keep their meaning (red is still red) but take the mode's lightness and the
  wallpaper's colorfulness, so they turn greyish on a grey wallpaper.

The thresholds are at the top of `main()` in that script.

| Colorful → dark | Bright → light | Black and white → grey |
|---|---|---|
| ![](screenshots/theme-dark.webp) | ![](screenshots/theme-light.webp) | ![](screenshots/theme-mono.webp) |

## What gets recolored

| App | Updates |
|---|---|
| Bar, panels, launcher, notifications | Live |
| Hyprland borders | Live |
| kitty (and fastfetch, delta, lazygit) | Live |
| Neovim | Live |
| GTK apps (translucent, like kitty) | GTK3 live, GTK4 on restart |
| cava | Live |
| Keyboard lighting (ASUS) | Live |
| starship | Next prompt |
| fuzzel, peaclock | Next launch |
| Lock screen | Next lock |

Without generated files everything falls back to Catppuccin Mocha. To change which color goes
where, edit the template for that app.
