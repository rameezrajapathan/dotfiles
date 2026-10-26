# Keybindings

[← README](../README.md)

Super + ? shows these on screen. Change them in Settings > Keybindings (click a shortcut, press new keys) or in `config/hypr/keybinds.lua`. Terminal, browser,
file manager and editor open your [default apps](desktop.md#default-apps).

## Apps and system

| Keys | Action |
|---|---|
| Super + A | App launcher |
| Super + D | Show or hide the dock |
| Super + P | Projects |
| Super + V | Clipboard history |
| Super + T | Terminal with fastfetch |
| Super + Return | Terminal |
| Super + \` | Drop-down terminal |
| Super + B | Browser |
| Super + C | Text editor |
| Super + E | File manager |
| Super + N | Notifications (the control center's Notifications page) |
| Super + Shift + N | Do Not Disturb |
| Super + S | Control center; on a details page Esc, Backspace or Alt + Left goes back, Esc again closes |
| Super + , | [Settings app](settings.md); Ctrl + F searches, Ctrl + Tab / Ctrl + Shift + Tab change page, Esc closes the page list (narrow window), clears the search, then closes |
| Super + Ctrl + W | Weather |
| Super + Shift + M | Music player (control center's Music tab) |
| Super + Shift + C | Color picker (copies hex) |
| Super + Shift + W | Wallpaper picker |
| Super + ? | Cheatsheet |
| Super + Escape | Power menu |
| Super + L | Lock |

## Windows

| Keys | Action |
|---|---|
| Alt + Tab | Switch windows (hold Alt; Shift goes back) |
| Super + Tab | Overview: hold Super, Tab / Shift + Tab or Left / Right move, release Super or Enter switches, 1–9 jumps there, Esc cancels |
| Super + Q | Close (Thunderbird and Chrome apps hide instead) |
| Super + F | Floating |
| Super + Ctrl + M | Maximize |
| Super + M | Fullscreen |
| Super + W | Group windows into tabs (in your accent color and UI font; middle-click a tab to close it) |
| Super + Alt + Left / Right | Previous / next window in the group |
| Super + Arrows | Move focus |
| Super + Shift + Arrows | Move the window |
| Super + J | Change split direction (dwindle layout only) |
| Super + [ / ] | Open the next window on the left / right of this one (dwindle layout only) |
| Super + - / = | Narrower / wider (Shift: shorter / taller) |
| Super + left / right drag | Move / resize (or hold Super + Z / X) |

The layout (dwindle, master or scrolling) is set in Settings > Windows.

Worth knowing:

- **Split keys are dwindle-only.** Super + J and Super + [ / ] do nothing in the master or
  scrolling layout.
- **Super + Z / X work without a mouse button.** Hold one and move the pointer (handy on a
  touchpad) to move or resize the window under it.
- **The ROG key is ASUS-only.** Ctrl / Alt + ROG key take screenshots on ASUS ROG laptops; on other
  laptops use Print.
- **Some shell actions have no key yet.** Game mode, keep awake, night light, the glass preset, the
  bar position and the calendar are in the control center and Settings. To bind one, add an
  `hl.bind` to `keybinds.lua` that runs `qs ipc call quicksettings gameMode`
  (`keepAwake`, `nightLight`), `qs ipc call glass cycle`, `qs ipc call bar cycle`,
  `qs ipc call calendar toggle`.

## Workspaces and monitors

| Keys | Action |
|---|---|
| Super + 1…9 | Go to workspace |
| Super + Shift + 1…9 | Move the window there |
| Super + Alt + 1…9 | Move it there without following |
| Super + U / I, Page Down / Page Up or scroll | Next / previous workspace |
| Super + Shift + U / I, Page Down / Page Up or Super + Ctrl + scroll | Move the window to the next / previous workspace |
| Super + F1 / F2 | Scratch workspaces (Shift: move the window there; Alt: without following). While one is open over a workspace, the bar shows its name in a pink chip (click to hide), a toast names it as it opens, and its windows get a border in that color |
| Super + Ctrl + Arrows or H J K L | Focus another monitor |
| Super + Shift + Ctrl + Arrows or H J K L | Move the window to another monitor |
| Three-finger swipe | Switch workspace |

## Zoom

| Keys | Action |
|---|---|
| Super + Alt + = | Zoom in around the pointer |
| Super + Alt + − | Zoom out |
| Super + Alt + 0 | Reset zoom |

## Screenshots and recording

| Keys | Action |
|---|---|
| Print | Region → clipboard |
| Ctrl + Print | Screen → clipboard |
| Alt + Print | Window → clipboard |
| Ctrl / Alt + ROG key | Screen / window → clipboard (ASUS ROG laptops) |
| Super + Shift + F | Region → clipboard and `~/Pictures/Screenshots` |
| Shift + Print | Region → draw on it in satty (Ctrl + C copies, Ctrl + S saves) |
| Super + Shift + T | Text in a region → clipboard (tesseract) |
| Super + Shift + R | Record a region (again to stop) |
| Super + Alt + R | Record the screen (again to stop) |

Recordings include the desktop audio (the default output) and go to `~/Videos/Recordings`.

## Media and hardware keys

| Keys | Action |
|---|---|
| Volume up / down, mute | Output volume in 3% steps, with the on-screen indicator |
| Mic mute, Super + Alt + M | Microphone on / off, with the on-screen indicator |
| Play / pause, next, previous | The current player |
| Brightness up / down | Screen brightness in 5% steps |
| Keyboard backlight up / down | Keyboard brightness |
| Closing the lid | Turns the laptop screen off when an external monitor is on; opening it brings it back |

All of these except the keyboard backlight also work on the lock screen.

## Terminal (kitty)

| Keys | Action |
|---|---|
| Ctrl + T | New tab |
| Ctrl + Shift + N | New window |
| Ctrl + + / − / 0 | Bigger / smaller / reset text |
| Ctrl + F2 | Move the tab's window into a window of its own |

Selecting text copies it.
