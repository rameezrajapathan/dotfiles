# The desktop

[← README](../README.md)

## The bar

Left: distro logo, workspaces, music. Center: clock, next meeting, window title. Right: tray, then
the status icons below, in order. Most of them open a panel; click outside it to close.

| Item | Click | Right click / scroll |
|---|---|---|
| Distro logo | Launcher | |
| Music | Art, seek bar, controls, shuffle, repeat, volume, player switcher | Play/pause; scroll skips |
| Clock | Calendar (scroll changes the month) | |
| Next meeting | Joins the call; only when a [calendar](developer.md#next-meeting) is set | |
| Tray | Opens the app | Its menu |
| Capture | Screenshot or record a region, window or screen; shows a timer while recording | Region screenshot |
| Palette | Wallpaper picker (Super + Shift + W); type to search by name | |
| Monitor | [Displays](#displays); filled while an external monitor is on | |
| Network | Wired, Wi-Fi (asks for passwords), VPN switches, import or add a VPN | |
| Bluetooth | Paired devices (connect, battery, forget), nearby devices to pair | Power on/off |
| Volume | Output and input devices, per-app volume | Mute; scroll changes volume |
| System | CPU, memory, GPU and disk with temperatures, busiest processes, last backup | |
| Battery | Time left, charge limit, power mode, GPU mode on ROG laptops | |
| GitHub | Notifications; only after `gh auth login` | |
| Bell | Notifications not yet dismissed | Do Not Disturb |
| Coffee | Shown while keep awake is on; click turns it off | |
| Quick settings | Do Not Disturb, keep awake, night light, color picker | |
| Power | Power menu | |

## Displays

The monitor icon opens a card per screen: on/off, resolution, refresh rate and scale, and with two
screens, which side of the other it sits on, or mirroring. Changes apply at once and are remembered
per monitor, so it comes back the same when plugged in again. The **reset** button (circular arrow) returns it to the defaults.

The panel saves to `~/.local/state/pikadots/monitors.lua`, which `hypr/.config/hypr/monitors.lua`
loads after its own rules. Edit `monitors.lua` only to change those defaults.

## Launcher (Super + A)

Apps, most used first. A first character switches mode:

| Prefix | Mode | Enter | Shift + Enter |
|---|---|---|---|
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
- **Volume and brightness indicator** when those keys are used.

## Notifications

Popups at the top right; hovering pauses the timeout. Critical ones stay until dismissed and get
through Do Not Disturb (Super + Shift + N).

## Lock screen

hyprlock with the blurred wallpaper, now playing and battery. Locks after 10 minutes idle, before
suspend, or with Super + Alt + L.

## Terminal

kitty with starship, eza and zoxide. Super + T opens it with fastfetch.
