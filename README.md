# pikadots

A Hyprland desktop for Arch Linux and CachyOS that takes its colors from the wallpaper, with a
Quickshell bar and a `pikadots` command to install, check, repair and update it.

![Desktop with fastfetch, Neovim and peaclock](docs/screenshots/desktop.webp)

## One desktop, any wallpaper

The colors come from the wallpaper. Bright pictures give a light theme, black and white ones a
grey theme.

| | |
|---|---|
| ![Dark theme from a colorful wallpaper](docs/screenshots/theme-dark.webp) | ![Light theme from a bright wallpaper](docs/screenshots/theme-light.webp) |
| ![Grey theme from a black and white photo](docs/screenshots/theme-mono.webp) | ![Light grey theme from a black and white painting](docs/screenshots/theme-mono-light.webp) |

## Screenshots

| | |
|---|---|
| ![Launcher](docs/screenshots/launcher.webp) Launcher | ![Power menu](docs/screenshots/power.webp) Power menu |
| ![Keyboard shortcuts](docs/screenshots/cheatsheet.webp) Shortcuts (Super + ?) | ![Lock screen](docs/screenshots/lock.webp) Lock screen |

## Features

- **Colors from the wallpaper**: the bar, terminal, Neovim, GTK apps, lock screen and keyboard
  lights follow it. Bright wallpapers give a light theme, black and white ones a grey theme.
- **One bar**: workspaces, music, clock and next meeting, tray, network, Bluetooth, audio, system
  monitor, battery, GitHub, notifications and quick settings, each with a panel.
- **Launcher** with a calculator, commands, emoji, projects and clipboard history.
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

1. Put wallpapers in `~/Pictures/Wallpapers` and pick one with **Super + Shift + W**.
2. Set your monitor in `hypr/.config/hypr/monitors.lua`.
3. Optional: `pikadots backup-init` for backups, `gh auth login` for GitHub in the bar.
4. Run `pikadots health` to check everything.

Existing configs are backed up first; `pikadots uninstall` restores them.

## Keys

| Keys | |
|---|---|
| Super + A | Launcher |
| Super + Return / T | Terminal / with fastfetch |
| Super + Shift + W | Wallpaper |
| Super + Tab / Alt + Tab | Overview / switch windows |
| Super + Q | Close |
| Super + 1…9 | Workspaces |
| Super + Escape | Power menu |
| Super + ? | All shortcuts |

## pikadots

```
pikadots health       check everything
pikadots repair       fix what health finds
pikadots update       pull and apply the latest version
pikadots uninstall    undo install, optionally remove packages
pikadots backup       back up now
```

## Docs

- [The desktop](docs/desktop.md): bar, panels, launcher, overlays
- [Keybindings](docs/keybindings.md)
- [Colors from the wallpaper](docs/theming.md)
- [pikadots and backups](docs/pikadots.md)
- [Developer tools](docs/developer.md)
- [Laptop, power and apps](docs/laptop.md)
- [Troubleshooting](docs/troubleshooting.md)

## Credits

[Hyprland](https://hyprland.org), [Quickshell](https://quickshell.org),
[matugen](https://github.com/InioX/matugen), [Catppuccin](https://catppuccin.com),
[Material Symbols](https://fonts.google.com/icons),
[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme). The fastfetch pika is
cropped from ["Royle's Pika in it's home"](https://commons.wikimedia.org/wiki/File:Royle%27s_Pika_in_it%27s_home.jpg)
by Nikeet123, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
