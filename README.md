# pikadots

A Hyprland desktop for Arch Linux and CachyOS that takes its colors from the wallpaper, with a
Quickshell bar and a `pikadots` command to install, check, repair and update it.

![Floating Neovim, btop, fastfetch, cava and peaclock under the bar's pill](docs/screenshots/desktop-v2.webp)

## One desktop, any wallpaper

| | |
|---|---|
| ![Dark theme from a colorful wallpaper](docs/screenshots/theme-dark-v2.webp) | ![Light theme from a bright wallpaper](docs/screenshots/theme-light-v2.webp) |
| ![Grey theme from a black and white forest photo](docs/screenshots/theme-mono-v2.webp) | ![Light grey theme from a black and white mountain photo](docs/screenshots/theme-mono-light-v2.webp) |

## Screenshots

| | |
|---|---|
| ![Control center](docs/screenshots/controlcenter-v2.webp) Control center (Super + S) | ![Launcher](docs/screenshots/launcher-v2.webp) Launcher (Super + A) |
| ![Power menu](docs/screenshots/power-v2.webp) Power menu | ![Keyboard shortcuts](docs/screenshots/cheatsheet-v2.webp) Shortcuts (Super + ?) |
| ![Lock screen](docs/screenshots/lock-v2.webp) Lock screen (Super + Alt + L) | ![Settings app](docs/screenshots/settings-effects.webp) Settings (Super + ,) |

## Features

- **Colors from the wallpaper**: the bar, terminal, Neovim, VS Code, GTK and Qt/KDE apps, lock
  screen and keyboard lights follow it. Bright wallpapers give a light theme, black and white ones a grey theme.
- **A bar your way**: by default one minimal pill with workspaces, the clock (a live spectrum while
  music plays) and your profile picture, which opens a control center: quick tiles,
  sliders, music, notifications and more at a glance, in one column, a three-column Bento or
  your own layout, with details for network (with a speed test), Bluetooth, sound, displays,
  battery and more a click away. Ten ready-made styles (Minimalist, Focus, Everyday, Developer,
  Islands, Floating, Classic, Maximalist…) or your own: one pill, islands or a full-width bar, with
  20 items (weather, window title, tray, status icons, CPU, now playing…) placed where you want.
- **A Settings app** (Super + ,): wallpaper, light/dark, palette, font themes, icon themes, bar
  styles, accessibility (zoom, text size, reduce motion), gaps, borders, blur, animations, window
  rules, input, notifications, lock screen, idle timers, night light schedule, drives, date & time
  and world clocks, default and startup apps, and updates for pikadots and the system, all applied
  live and searchable.
- **Launcher** with a calculator, commands, emoji, projects and clipboard history with pins.
- **Screenshots** to draw on (satty) or read text from (OCR), USB drives that mount with a
  notification, a privacy pill while the mic, camera or screen is in use, password prompts and game
  mode in the shell's own style.
- **Alt + Tab with live previews**, a workspace overview and a drop-down terminal.
- **Developer setup**: keyring and SSH agent, git with delta, GitHub notifications, per-project
  tool versions, encrypted daily backups.
- **Laptop care**: charge limit, GPU modes and keyboard lighting on ASUS ROG, power profiles,
  idle lock.

## Install

Needs Arch Linux or a derivative, and a login manager with a Hyprland session.

```sh
git clone https://github.com/rameezrajapathan/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

Log out, choose **Hyprland**, then:

1. Pick a wallpaper with **Super + Shift + W**. Seven [come with it](wallpapers/CREDITS.md); add
   your own to `~/Pictures/Wallpapers`.
2. Set resolution, refresh rate, scale and layout from the control center (the monitor button next to brightness).
3. Optional: `pikadots backup-init` for backups, `gh auth login` for GitHub notifications, or
   `pikadots import <file>` to bring your settings from another machine (`pikadots export` there).
4. Run `pikadots health` to check everything.

Existing configs are backed up first; `pikadots uninstall` restores them. Super + ? shows every
shortcut.

## Docs

- [The desktop](docs/desktop.md): bar, control center, launcher, overlays, lock screen
- [The Settings app](docs/settings.md)
- [Keybindings](docs/keybindings.md)
- [Colors from the wallpaper](docs/theming.md)
- [The pikadots command and backups](docs/pikadots.md)
- [Developer tools](docs/developer.md)
- [Laptop, power and apps](docs/laptop.md)
- [Troubleshooting](docs/troubleshooting.md)

## Credits

[Hyprland](https://hyprland.org), [Quickshell](https://quickshell.org),
[matugen](https://github.com/InioX/matugen), [Catppuccin](https://catppuccin.com),
[Material Symbols](https://fonts.google.com/icons),
[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme). Wallpapers are public domain
or CC0 ([credits](wallpapers/CREDITS.md)). The fastfetch pika is
cropped from ["Royle's Pika in it's home"](https://commons.wikimedia.org/wiki/File:Royle%27s_Pika_in_it%27s_home.jpg)
by Nikeet123, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
