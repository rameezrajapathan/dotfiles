# The desktop

[← README](../README.md)

## The bar

Rounded pills across the top with the desktop blurred behind them. Most items open a panel when
clicked.

| Where | Item | Click | Also |
|---|---|---|---|
| Left | Distro logo | App launcher | |
| Left | Workspaces | Switch workspace | |
| Left | Music | Music panel | Right click play/pause, scroll skips |
| Center | Clock | Calendar | |
| Center | Next meeting | Join the call | Only when a [calendar](developer.md#next-meeting) is set |
| Center | Window title | | |
| Right | Tray | Open the app | Right click for its menu |
| Right | Capture | Capture menu | Right click: region screenshot; shows a timer while recording |
| Right | Palette | Wallpaper picker | |
| Right | Network | Network panel | |
| Right | Bluetooth | Bluetooth panel | Right click turns it on or off |
| Right | Volume | Audio panel | Right click mutes, scroll changes volume |
| Right | System | System panel | |
| Right | Battery | Battery panel | |
| Right | GitHub | GitHub panel | Only after `gh auth login` |
| Right | Bell | Notifications | Right click toggles Do Not Disturb |
| Right | Quick settings | Quick settings panel | |
| Right | Power | Power menu | |

## Panels

Click outside a panel to close it.

- **Music**: art, seek bar, controls, shuffle, repeat, volume, and a switcher when several apps
  play. Works with any MPRIS player (Spotify, browsers, VLC, mpv).
- **Calendar**: month view; scroll to change the month.
- **Network**: wired status, Wi-Fi networks (secured ones ask for the password), VPN switches.
- **Bluetooth**: paired devices (connect, battery, forget) and nearby devices to pair.
- **Audio**: output and input devices, per-app volume.
- **System**: CPU, memory, GPU and disk with temperatures, busiest processes, last backup.
- **Battery**: time left, charge limit, power mode, GPU mode on ROG laptops.
- **GitHub**: notifications; click to open, or mark all read.
- **Notifications**: everything not yet dismissed.
- **Capture**: screenshot or record a region, window or screen.
- **Quick settings**: Do Not Disturb, keep awake, night light, color picker.

## Launcher (Super + A)

Apps, most used first. Type to search; a first character switches mode:

| Prefix | Mode | Enter | Shift + Enter |
|---|---|---|---|
| | Apps | Open | |
| `=` | Calculator (`=5 GiB to MB`) | Copy result | |
| `>` | Command | Run | Run in a terminal |
| `:` | Emoji | Copy | |
| `~` | Projects (git repos you visit) | VS Code | Neovim |
| `+` | Clipboard history | Copy | |

## Overlays

- **Power menu** (Super + Escape): lock, log out, suspend, restart, shut down (L / E / S / R / P).
- **Alt + Tab**: live window previews; release Alt to switch.
- **Overview** (Super + Tab): every workspace with live previews.
- **Drop-down terminal** (Super + \`): stays running while hidden.
- **Cheatsheet** (Super + ?): every shortcut, read live from Hyprland.
- **Wallpaper picker** (Super + Shift + W): picking one recolors everything.
- **Volume and brightness indicator** when those keys are used.

## Notifications

Quickshell shows notifications: popups at the top right with actions and a timeout line
(hover pauses it). Critical ones stay until dismissed. Do Not Disturb (Super + Shift + N) holds
back everything but critical ones.

## Lock screen

hyprlock with the blurred wallpaper, a large clock, and now playing and battery in the corners.
Locks after 10 minutes idle, before suspend, or with Super + Alt + L.

## Terminal

kitty, translucent and blurred, with starship, eza and zoxide. Super + T opens it with fastfetch;
Super + Return opens a plain one.
