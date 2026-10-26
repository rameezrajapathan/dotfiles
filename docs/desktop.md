# The desktop

[← README](../README.md)

## The bar

By default (the **Minimalist** style) one pill in the middle: the current workspace number in a
circle (click for the overview, scroll to go through workspaces; a red ring means another workspace
wants attention), the clock (click for the calendar; `qs ipc call calendar toggle` opens it too) and
your profile picture, which opens the control center. A dot on the picture means there are
notifications; upload a picture from the Account tab. While music plays, a small spectrum takes the
clock's place; clicking it opens the Music tab. The recording timer shows while recording (click to
stop), and the [next meeting](developer.md#next-meeting) shows once a calendar is set.

A yellow pill with a mic, camera or screen icon shows while an app uses one; hover for which apps,
click for the Sound tab (`quickshell/services/Privacy.qml`). The mic counts PipeWire recording streams, but
not ones that only listen to the speakers, like cava. The screen counts xdg-desktop-portal-hyprland's
share. The camera counts PipeWire video capture and any process holding `/dev/video*` open.

Settings > Bar has nine more styles and a custom setup: one pill, a pill per section (islands) or
one bar across the screen; height, spacing and an outline; and which items go left, in
the middle and right. Besides the ones above there are the weather (click for the forecast), the
date, the apps button (distro logo, opens the launcher), the focused window's title, now playing
(right click plays or pauses, scroll skips), the tray, CPU and memory, network, Bluetooth (right
click turns it on or off), sound (scroll for volume, right click mutes), battery, notifications
(right click for Do Not Disturb), a capture button (right click takes a region screenshot), power
and dividers. Status icons open their control center page. Some items only show when they have
something to show (now playing, the tray, battery on a laptop...). See
[settings.md](settings.md#bar).

The bar can sit on any edge of the screen, and can be attached to it (it grows out of the edge
with curved corners). The workspaces item has eight styles, from a single rolling number to dots,
pills or app icons ([settings.md](settings.md#workspaces)).

While a special workspace is open over a workspace (the scratchpads on Super + F1 / F2, the
drop-down terminal, hidden background apps), the workspaces item shows its name in a chip in the
special color (click to hide it), and a short toast names it as it opens with the key that hides
it (`bar/SpecialChip.qml`, `overlays/SpecialToast.qml`). Its windows get a border in that color.

The ten ready-made styles (shown with music paused; while something plays, the clock turns into a
live spectrum and Now playing shows the track):

| Style | |
|---|---|
| **Minimalist**<br>one pill | ![Minimalist bar: One pill in the middle. The original.](screenshots/bar-minimalist-v4.webp) |
| **Focus**<br>one pill | ![Focus bar: Only the time. Nothing to pull you away.](screenshots/bar-focus-v4.webp) |
| **Everyday**<br>islands | ![Everyday bar: Friendly and familiar: apps, date, battery, sound. No tech clutter.](screenshots/bar-everyday-v4.webp) |
| **On the go**<br>one pill | ![On the go bar: A small pill for laptops: Wi-Fi, battery and time.](screenshots/bar-onthego-v4.webp) |
| **Music lover**<br>islands | ![Music lover bar: What's playing up front, sound and Bluetooth close at hand.](screenshots/bar-music-v4.webp) |
| **Developer**<br>full width | ![Developer bar: Window title, CPU and memory, tray and meetings.](screenshots/bar-developer-v4.webp) |
| **Islands**<br>islands | ![Islands bar: A pill on each side and one in the middle.](screenshots/bar-islands-v4.webp) |
| **Floating**<br>full width | ![Floating bar: A full bar with space around it.](screenshots/bar-floating-v4.webp) |
| **Classic**<br>full width | ![Classic bar: Edge to edge and square, like a traditional desktop.](screenshots/bar-classic-v4.webp) |
| **Maximalist**<br>full width | ![Maximalist bar: Everything, all at once.](screenshots/bar-maximalist-v4.webp) |

## Dock (Super + D)

A strip of app icons on its own screen edge (bottom by default; left or right, never the bar's
edge). Pinned apps come first in your order, then a divider and the apps you have open that
aren't pinned, in the order you opened them. One icon per app, however many windows it has;
apps on special workspaces (scratchpads, the drop-down terminal, background apps) count too and
get a badge when every window is there.

- **Click** an app that isn't open to start it (the icon pulses until its window shows up). Click
  an open app to focus its last window, opening its workspace or special workspace if needed;
  click again to cycle through its windows. **Middle-click** opens a new window.
- **Hover** for live window previews. Click one to go to that window, ✕ or middle-click closes it.
- **Right-click** for New window (with its keybinding, if it has one), the app's own actions
  (such as New Private Window), Keep in Dock / Remove from Dock, Close and Dock settings.
- **Drag** icons to reorder pins, drag an open app among them to pin it, or drag a pin off the
  dock to remove it.
- **Super + D** hides it or brings it back. With auto-hide or intellihide, rest the pointer on
  the edge to show it. It always hides for a fullscreen window.

Everything else is in Settings > Dock. From a script: `qs ipc call dock toggle|show|hide`,
`dock mode always|autohide|intellihide`, `dock edge bottom|left|right`, `dock pin|unpin <app id>`.

## Calendar

Click the clock (or the date). The time, the month (arrows or scroll change it, the month name
returns to today) and, if you add them in Settings > Date & time, week numbers and world clocks
with the time difference from yours. The week starts on Monday, Sunday or Saturday as you choose.

## Weather (Super + Ctrl + W)

Comes out of the bar from the weather item (add it in Settings > Bar or Settings > Weather; Super +
Ctrl + W opens it either way), in the same plain style as the other panels: the temperature, conditions, feels like and today's high and low; the next 24 hours as a
thin line (scroll sideways) with the chance of rain; 7 days with each day's range against the
week's; and humidity, wind, UV, air quality, the next sunrise or sunset, and pressure.

Data comes from [Open-Meteo](https://open-meteo.com) (no account or key) and refreshes every 15
minutes. The place is found from your connection (ipinfo.io); click it to search for a city, or
pick "Use my location" to go back. °C / °F switches the units (wind follows: km/h or mph). Both
are saved in `~/.local/state/quickshell/weather.json`. `qs ipc call weather toggle` opens it,
`qs ipc call weather refresh` reloads it.

## Control center

![Control center in a three-column Custom layout](screenshots/controlcenter-v4.webp)

The profile picture opens one window, attached to the bar, holding everything else as
widgets. Pick its layout on [Settings > Control center](settings.md#control-center):

- **One glance** (the default): one column with your profile, lock/settings/power, quick tiles,
  volume and brightness, what's playing, the latest notifications, status chips (CPU, memory,
  drives, updates, GitHub, recording) and the tray.
- **Bento**: three columns: profile & power, small quick tiles, sliders, shortcuts (capture,
  wallpaper, settings) and the tray; large music, calendar and weather; updates, notifications
  and system usage.
- **Custom**: any of the widgets in one to three columns, in your order.

The quick tiles (the same set for every layout, picked on the settings page) toggle on click; the
arrow on a tile (or a right click) opens its details in place, and so do the chips, cards and
the buttons next to the sliders. A back arrow, Esc, Backspace or Alt + Left returns to the
widgets; Esc again or a click outside closes. Super + S opens it; `qs ipc call controlcenter
toggle <page>` opens a details page directly: `account`, `music`, `notifications`, `network`,
`bluetooth`, `audio`, `display`, `drives`, `battery`, `system`, `capture` or `github` (`""` for
the widgets).

The details pages:

| Page | What's in it |
|---|---|
| Account | Profile picture (click it to upload one; saved square-cropped as `~/.face` and sent to AccountsService for the login screen), name, quick settings (Do Not Disturb, keep awake, night light, [game mode](#game-mode), color picker), lock, log out, power menu |
| Music | Album art in a slowly turning scalloped frame with the live spectrum around it, title, artist and album, a wavy seek bar, round controls around a wide play button, the players (when there are several), open the app, volume |
| Notifications | Notifications not yet dismissed |
| Network | Live download/upload speed with a one-minute graph, speed test (ping, download and upload against Cloudflare with curl; the gauge button next to settings), wired, Wi-Fi (asks for passwords), VPN switches, import or add a VPN |
| Bluetooth | Paired devices (connect, battery, forget), nearby devices to pair |
| Sound | Output and input devices, per-app volume |
| Displays | [Displays](#displays) |
| Drives | USB drives, SD cards and disk images (only while one is attached): click opens it in the file manager (mounting it, or asking for the passphrase of an encrypted drive), eject unmounts and powers it off, a bar shows how full it is |
| Battery | Time left, charge limit, power mode, GPU mode on ROG laptops |
| System | CPU, memory, GPU and disk with temperatures, busiest processes, last backup, and with snapper the system snapshots ("Snapshot 40 min ago · 50 in the boot menu", yellow after 7 days; [more](pikadots.md#snapshots)) |
| Capture | Screenshot or record a region, window or screen; annotate a region (satty) or copy the text in it (tesseract). Screenshot notifications have an Edit button that opens satty |
| GitHub | Notifications; only after `gh auth login` |

The Tray widget has the tray and hidden background apps (click opens the app, right click shows
its menu). The wallpaper picker is Super + Shift + W (or the Shortcuts widget) and the launcher
Super + A.

## Motion

Panels that come out of the bar (control center, calendar, weather, launcher, wallpaper picker,
power menu, overview, Alt + Tab) share one animation, picked on Settings › Effects: **Slide**
(out from under the item, the default), **Morph** (the bar's pill stretches into the panel),
**Spring** (Morph with a soft overshoot), **Liquid** (widens, then pours out), **Reveal**
(uncovered from the bar's side) or **Fade**, at 50–200% speed. Closing is a quick ease-out in every style. `PanelMotion.qml`
holds the curves and shapes; `Sheet.qml` applies them.

Selection highlights (launcher, Alt + Tab,
workspace pill) glide instead of jumping. The control center, calendar, weather, launcher, wallpaper picker,
power menu, overview (one row of workspaces) and Alt + Tab switcher come out of whichever edge
the bar is on, next to the item they belong to (on a pill, its side facing the panel squares off
and the panel grows out of it). Only one is open at a time: opening
another (or the cheatsheet) closes it. When the keyboard moves focus to another window (arrows, Alt
+ Tab), the mouse pointer glides there instead of jumping (Hyprland's own warps are off:
`cursor.no_warps` in `settings.lua`, done by `CursorGlide.qml`); it stays put when the mouse did the
focusing (the pointer is in or right next to the window, or still moving), for new windows and on
workspace switches.

Settings > Accessibility > "Reduce motion" makes all of this instant and turns off Hyprland's, GTK's
and KDE's animations; loading spinners and the recording dot keep moving. New shell animations take
their duration through `Theme.ms()` so they follow it.

## Game mode

The Account tab's Game mode tile turns off animations, blur, shadows, rounding and gaps, switches
to the performance power profile and turns on Do Not Disturb. Turning it off puts the power profile
and Do Not Disturb back as they were. It lasts until turned off or a restart: `hypr/settings.lua`
applies it whenever `$XDG_RUNTIME_DIR/pikadots-gamemode` exists, so a Hyprland reload keeps it.
`qs ipc call quicksettings gameMode` toggles it.

## Drives

`quickshell/services/Drives.qml` lists removable disks from `lsblk` and refreshes whenever `udisksctl
monitor` reports a change. Mounting, unlocking (a zenity passphrase prompt) and ejecting go through
`hypr/scripts/drives.sh` and udisks, so no password is needed. A drive plugged in while the shell
runs is mounted under `/run/media/$USER`, and a notification offers Open and Eject. With Settings >
Drives "Open it right away" off, the notification asks first. Disk images (`udisksctl loop-setup -f
file.iso`) are listed but never opened on their own. Phones (MTP) aren't block devices: install
`gvfs-mtp` and they show in Thunar.

## Displays

The Displays tab has a card per screen: on/off, resolution, refresh rate and scale, and with two
screens, which side of the other it sits on, or mirroring. Changes apply at once and are remembered
per monitor, so it comes back the same when plugged in again. The **reset** button (circular arrow) returns it to the defaults.

The tab saves to `~/.local/state/pikadots/monitors.lua`, which `config/hypr/monitors.lua`
loads after its own rules. Edit `monitors.lua` only to change those defaults.

## Launcher (Super + A)

![Launcher](screenshots/launcher-v4.webp)

Apps, most used first. Five styles, set in Settings > Launcher (or `qs ipc call launcher style
bar|dock|center|fullscreen|spotlight`):

- **Attached to bar** (default): grows out of the bar.
- **Attached to dock**: the dock comes in first, then the launcher grows out of it. It opens
  centered when the dock is off or a fullscreen window hides it.
- **Centered**: a card in the middle of the screen.
- **Fullscreen**: big icons over a frosted screen, with category chips (Internet, Development,
  Graphics…). Click an empty spot or press Esc to close it.
- **Spotlight**: only a search field. Results appear as a list as you type.

A first character switches mode:

| Prefix | Mode | Enter | Shift + Enter |
|---|---|---|---|
| `=` | Calculator (`=5 GiB to MB`) | Copy result | |
| `>` | Command | Run | Run in a terminal |
| `:` | Emoji | Copy | |
| `~` | Projects (code folders you visit, [more](developer.md)) | Default editor | Terminal there |
| `+` | Clipboard history | Copy | |

In clipboard mode Ctrl + P pins a clip (or unpins it), Shift + Delete removes one and Ctrl + Shift +
Delete clears the history. Pins are files in `~/.local/share/pikadots/clipboard-pins`, listed first,
and kept when the history is cleared. Settings > Launcher sets the history size and "Keep copied
text when the app closes" (`wl-clip-persist`). `hypr/scripts/clipboard.sh watch` starts both at
login.

## Tooltips

Hovering any button that shows only an icon names it after half a second, with its keybinding
when it has one (for example *Open control center · Super + S*). Tray icons show the app's own
text. Settings > Accessibility turns tooltips off or changes the delay.

## Overlays

| | |
|---|---|
| ![Power menu](screenshots/power-v4.webp) | ![Wallpaper picker](screenshots/wallpaper-v4.webp) |

- **Power menu** (Super + Escape): lock, log out, suspend, restart, shut down (L / E / S / R / P).
- **Password prompts** for system changes (pkexec, the Date & time page, updates) are the shell's own
  polkit agent (`quickshell/overlays/PolkitDialog.qml`): Enter authenticates, Esc cancels. If another agent
  already holds the session, it retries a few times, then starts hyprpolkitagent instead.
- **Alt + Tab**: live window previews; release Alt to switch.
- **Overview** (Super + Tab): every workspace in a row with live previews. Like Alt + Tab: hold
  Super, Tab / Shift + Tab or Left / Right moves, releasing Super or Enter switches, 1–9 jumps
  straight to that workspace, Esc cancels. Clicking the current workspace in the bar opens it too.
- **Drop-down terminal** (Super + \`): stays running while hidden.
- **Wallpaper picker** (Super + Shift + W): a strip of `~/Pictures/Wallpapers`; picking one
  recolors everything ([theming.md](theming.md)).
- **Cheatsheet** (Super + ?): every shortcut, read live from Hyprland.
- **On-screen indicator** for volume, microphone mute, screen brightness and keyboard backlight
  when those keys are used.

![Cheatsheet](screenshots/cheatsheet-v4.webp)

## Notifications

Popups at the top right by default; Settings > Notifications puts them top left, top, top right,
bottom left or bottom right and sets how long they stay, how many show at once and their width.
With *Let apps choose how long* on, an app's own timeout wins. Hovering pauses the timeout.
Critical ones stay until dismissed and get through Do Not Disturb (Super + Shift + N). Super + N
opens the list (the control center's Notifications page).

## Lock screen

Part of the shell (`quickshell/lock/Lock.qml`), split in two over the blurred wallpaper. The left half
has the date and a big clock, now playing (controls and a live spectrum) and suspend, restart and
power off (restart and power off ask for a second click). The right half has your profile picture
and the password pill: dots pop in, it shakes on a wrong password, and Caps Lock warns. Between them
runs a fading line with a glowing accent diamond and a light travelling down it. After 15 seconds
without input it rests: the blur softens and the right half dims to "Press any key". Any key or
mouse movement wakes it; Esc clears the pill.

Locks after 10 minutes idle (Settings > Power), before suspend, or with Super + L. Settings >
Lock screen sets the blur, rest delay and what it shows, shows the idle lock time (*Change* opens
Settings > Power) and has a *Lock now* button. `hypr/scripts/lock.sh` falls
back to hyprlock if the shell isn't running, and a restarted shell locks again if it crashed while
locked.

## Default apps

The easiest way to change these is the Settings app's Default apps page
([settings.md](settings.md)); the commands below do the same.

Keybinds, the bar and the launcher never name an app: they open the system's default terminal,
browser, file manager and editor through `hypr/scripts/app.sh`. Change them with:

| App | Change with | pikadots sets (if unset) |
|---|---|---|
| Terminal (Super + Return, Super + T, Super + \`) | first line of `~/.config/xdg-terminals.list`, e.g. `foot.desktop` | kitty |
| Browser (Super + B) | `xdg-settings set default-web-browser firefox.desktop` | — (your choice) |
| File manager (Super + E) | `xdg-mime default superfile.desktop inode/directory` | superfile (spf, in the terminal; Thunar without it) |
| Editor (Super + C, launcher projects) | `xdg-mime default code-oss.desktop text/plain` | Neovim |

Terminal editors open in the default terminal. The terminal list is read by
[xdg-terminal-exec](https://gitlab.freedesktop.org/terminal-wg/specifications), which apps that
open a terminal also use; `pikadots install` writes it with kitty if it's missing.

## Terminal

kitty with starship, eza and zoxide. Super + T opens it with fastfetch. In zsh, `ls`, `ll`
(long, with git status), `la` (hidden files too) and `lt` (a tree) are eza, and `cd` is zoxide, so
`cd proj` jumps to a folder you've visited. kitty's shortcuts are in
[keybindings.md](keybindings.md#terminal-kitty). Its font is set in
Settings > Fonts & icons (a font theme or the terminal font). The cursor glides to
where it jumps, with a short trail (`cursor_trail` in `config/kitty/kitty.conf`), and its
blink fades.

Terminal apps follow the wallpaper too: btop (`config/btop/btop.conf` picks the generated
`wallpaper` theme with a transparent background), cava, peaclock, superfile, lazygit, eza's
listings and Neovim (with the [`pikadots` colorscheme](theming.md#neovim)). To open one floating
in a fixed spot, add it as a terminal app in [Settings > Window rules](settings.md#window-rules).
