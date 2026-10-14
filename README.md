# dotfiles

A minimal Hyprland desktop for CachyOS / Arch: Hyprland (Lua config), a small Quickshell bar,
and a handful of single-purpose tools. Colors follow the wallpaper (Material You colors from
**matugen**, with Catppuccin Mocha as the fallback), and everything uses **FiraCode Nerd Font**.

| Role | Tool |
|---|---|
| Compositor | Hyprland (Lua config, 0.56+) |
| Bar, panels, notifications | Quickshell |
| App launcher, power menu | Quickshell (`Launcher.qml`, `PowerMenu.qml`) |
| Clipboard picker, password prompts | fuzzel |
| Wallpaper | hyprpaper |
| Colors from the wallpaper | matugen |
| Idle / lock | hypridle + hyprlock |
| Polkit agent | hyprpolkitagent |
| Terminal / prompt | kitty + starship |
| Screenshots | grim + slurp |
| Screen recording | wf-recorder |
| Clipboard history | cliphist |
| Network + VPN | NetworkManager (+ networkmanager-openvpn) |

## Install

1. Install the packages:

   ```sh
   sudo pacman -S --needed hyprland quickshell hypridle hyprlock hyprpaper hyprpolkitagent \
       fuzzel kitty starship fastfetch stow matugen adw-gtk-theme ttf-material-symbols-variable \
       grim slurp wl-clipboard cliphist wf-recorder jq brightnessctl libnotify \
       networkmanager networkmanager-openvpn wireplumber pipewire-pulse upower \
       ttf-firacode-nerd papirus-icon-theme
   ```

2. Clone the repo to `~/dotfiles` and link it into `~/.config` with stow. Stow refuses to overwrite
   real files, so move any existing configs out of the way first:

   ```sh
   cd ~/dotfiles
   stow hypr quickshell fuzzel kitty starship fastfetch fontconfig matugen gtk
   ```

   Each top-level folder is a stow package that mirrors `$HOME`. For example,
   `hypr/.config/hypr` becomes `~/.config/hypr`.

3. Log into the **Hyprland** session. Everything starts from `hypr/autostart.lua`.

4. Generate the colors once (afterwards the wallpaper picker does it), and source the starship
   line from [Colors](#colors-from-the-wallpaper) in your shell rc:

   ```sh
   ~/.config/hypr/scripts/theme.sh
   ```

5. Machine-specific bits to check:
   - `hypr/monitors.lua`: output name, resolution, refresh rate and scale.
   - `hypr/hyprpaper.conf`: wallpaper path.
   - `hypr/scripts/vpn.sh`: default VPN connection name (`Office VPN`).

## Layout

```
hypr/.config/hypr/
  hyprland.lua        entry point, requires the files below
  monitors.lua        displays
  settings.lua        env vars, input, gaps/borders/rounding, animations, misc
  rules.lua           window rules
  keybinds.lua        all keybindings
  autostart.lua       programs started with Hyprland
  background.lua      apps that Super + Q hides instead of closing (Thunderbird, Chrome apps)
  hypridle.conf       idle timeouts
  hyprlock.conf       lock screen
  hyprpaper.conf      wallpaper
  scripts/
    screenshot.sh     region | full | active [save]
    record.sh         region | full; run again to stop
    clipboard.sh      cliphist history in fuzzel
    lock-status.sh    battery and now-playing lines on the lock screen
    vpn.sh            toggle a NetworkManager VPN, saving its password on first use
    tray-apps.sh      starts OneDriveGUI and Remmina's applet once the bar's tray is up
quickshell/.config/quickshell/
  shell.qml           one Bar per screen
  Bar.qml             bar layout
  Theme.qml           colors, font, sizes (singleton)
  Workspaces.qml  Clock.qml  Recording.qml  Network.qml  Volume.qml  Battery.qml
  Media.qml  MediaButton.qml  MediaPanel.qml   music (MPRIS: Spotify, browsers, any player)
  PowerButton.qml  Launcher.qml  PowerMenu.qml
  Icon.qml   Material Symbols Rounded icon by name (Icon { name: "wifi"; filled: true })
  NetworkPanel.qml    dropdown for wired / Wi-Fi / VPN
  AudioPanel.qml      dropdown for audio devices and volumes
  CalendarPanel.qml   month calendar under the clock
  BatteryPanel.qml    battery status and power mode
  Notification*.qml   notification daemon (Service), toasts (Popups, Card), bell (Button), list (Panel)
  WallpaperPicker.qml Super + Shift + W wallpaper strip (WallpaperButton.qml opens it from the bar)
  ActiveWindow.qml    icon and title of the focused window
  Tray.qml            tray icons of background apps
  BackgroundApps.qml  icons for running Thunderbird / Chrome-app windows (shown or hidden)
  Cheatsheet.qml      Super + ? keybinding overlay
  VpnService.qml      VPN state from nmcli (singleton)
  Label.qml  Pill.qml  Switch.qml  Slider.qml  PanelRow.qml  small shared widgets
fuzzel/  mako/  kitty/  matugen/  gtk/  starship/  fastfetch/  fontconfig/
```

## Keybindings

`Super` is the main modifier.

**Apps and session**

| Keys | Action |
|---|---|
| Super + T / Super + Return | Terminal (kitty) |
| Super + N | Notification list |
| Super + A | App launcher |
| Super + B | Browser (Zen) |
| Super + C | VS Code |
| Super + E | File manager (Thunar) |
| Super + V | Clipboard history |
| Super + Escape | Power menu |
| Play / Next / Prev keys | Control the player shown in the music panel |
| Super + Alt + L | Lock |
| Super + ? | Keybinding cheatsheet (type to filter, Esc to close) |
| Super + Shift + W | Wallpaper picker |

**Windows**

| Keys | Action |
|---|---|
| Super + Q | Close window |
| Super + F | Toggle floating |
| Super + Shift + M | Maximize |
| Super + M / Super + Ctrl + F | Fullscreen |
| Super + W | Toggle group |
| Super + Arrows | Move focus |
| Super + Shift + Arrows | Move window |
| Super + J | Toggle split direction |
| Super + [ / ] | Preselect left / right split |
| Super + - / = | Shrink / grow width (add Shift for height) |
| Super + left / right mouse drag, or Super + Z / X | Move / resize with the mouse |

**Workspaces and monitors**

| Keys | Action |
|---|---|
| Super + 1…9 | Go to workspace |
| Super + Shift + 1…9 | Move window to workspace |
| Super + Alt + 1…9 | Move window there without following it |
| Super + U / I, Page Down / Up, mouse wheel | Next / previous workspace |
| Super + Shift + U / I, or Super + Ctrl + Up / Down | Move window to next / previous workspace |
| Super + F1 / F2 | Toggle scratch workspaces (Shift moves the window there) |
| Super + Ctrl + Arrows or H/J/K/L | Focus another monitor |
| Super + Shift + Ctrl + Arrows or H/J/K/L | Move window to another monitor |
| 3-finger horizontal swipe | Switch workspace |

**Screenshots and recording**

| Keys | Action |
|---|---|
| Print | Region → clipboard |
| Ctrl + Print | Full screen → clipboard |
| Alt + Print | Active window → clipboard |
| Super + Shift + F | Region → clipboard and `~/Pictures/Screenshots` |
| Super + Shift + R | Start / stop recording a region |
| Super + Alt + R | Start / stop recording the full screen |

Recordings go to `~/Videos/Recordings` as H.264 MP4 with desktop audio. A red **rec** shows in
the bar while recording; clicking it stops the recording.

**Media keys**

Volume, mute, mic mute, and screen and keyboard brightness work on their usual keys. All except
keyboard brightness also work on the lock screen.

## The bar

Left to right: workspace dots (the focused one is a wide pill; click to switch), the focused
window's icon and title, clock (click for a calendar), then icons only: 󰑊 (only while recording;
click to stop), 󰸉 wallpaper picker, network, volume (click for the audio panel, right-click to mute, scroll to change)
battery (click for the battery panel) and 󰂚 notifications (with an unread count). The network icon gets a 󰖂 while a VPN is connected; set
`vpnMark` in `Network.qml` to `""` to hide it.

Background apps (OneDrive, Remmina, ...) get their own pill just left of the status icons; it's
hidden when no app has a tray icon. Left click opens the app, right click shows its menu, middle
click is the app's secondary action. OneDriveGUI and `remmina -i` start from
`hypr/scripts/tray-apps.sh`, which waits for the tray first: Qt apps that start before it exists
open a window instead, and closing that window quits them. With the tray up, closing the
OneDrive or Remmina window just hides it to the tray.

Thunderbird and Chrome apps (Teams, WhatsApp, ...) have no tray icon on Linux, so they're kept
running another way: **Super + Q hides them** in the `special:background` workspace instead of
closing them, and they keep sending notifications. Their icons show at the start of the same
pill, with a dot while the window is shown. Click to bring a hidden window to the current
workspace (or hide it if it's focused); right click quits the app. Thunderbird, Teams and
WhatsApp start hidden at login. Edit the class list in `hypr/background.lua` and the regex in
`BackgroundApps.qml` to change which apps behave this way. The app's own ✕ button still quits it.

### Wallpaper picker

Super + Shift + W or the 󰸉 icon slides down a strip of the images in `~/Pictures/Wallpapers` (scroll
to see more). Click one (or pick with the arrow keys and press Enter) to set it on every monitor
through hyprpaper; it's saved to `hyprpaper.conf`, so it stays after a restart. Esc or a click outside closes it.

### Notifications

Quickshell is the notification daemon (mako isn't started any more; its config is left in `mako/`).

- New notifications pop up in the top-right corner for 5 seconds (or the app's own timeout).
  Hovering pauses the timer. Critical ones have a red border and stay until dismissed.
- Click a notification to run the app's default action (for example, open the chat). Other actions
  show as buttons. ✕ dismisses it.
- Notifications stay in the list after their popup goes away. Click the bell to see them all; ✕
  dismisses one and **clear all** dismisses everything.

### Battery panel

Click the battery icon to see the charge and time left, and to switch the power-profiles-daemon
mode: Power saver, Balanced or Performance. The current mode is highlighted.

### Network panel

Click the network label to open the panel. Click anywhere outside it to close it.

- **Wired**: the Ethernet device and its link speed.
- **Wi-Fi**: an on/off switch and nearby networks, strongest first. The connected one is highlighted
  and 󰌾 marks secured networks.
  - Click a network to connect, or click the connected one to disconnect.
  - New secured networks ask for their password in a fuzzel prompt.
  - **forget** removes a saved network.
- **VPN**: every NetworkManager VPN or WireGuard connection, each with an on/off switch. It shows
  "connecting…" until NetworkManager reports the new state.
- **settings** opens `nmtui` in kitty for anything else (editing connections, hidden networks,
  static IPs).

### Audio panel

Click the volume label to open the panel. Click anywhere outside it to close it.

- **Output** and **Input**: a volume slider for the current device (click the icon to mute), then
  every device; click one to make it the default. The current one is highlighted.
- **Apps**: a slider for each app playing sound (only shown while something plays).
- **settings** opens `pavucontrol` for anything else (profiles, ports, per-app routing).

### VPN

VPN connections are plain NetworkManager connections. To import an OpenVPN config:

```sh
nmcli connection import type openvpn file client.ovpn
nmcli connection modify <name> connection.id "Office VPN" +vpn.data username=<user> +vpn.data password-flags=0
```

`password-flags=0` makes NetworkManager store the password in its root-only file under
`/etc/NetworkManager/system-connections/`. The first time you connect, `vpn.sh` asks for the
password and saves it. If a connection attempt fails, it clears the saved password so the next
attempt asks again. There is no keyring or secret-agent daemon.

## Idle and lock

From `hypr/hypridle.conf`:

| After | Action |
|---|---|
| 5 min | Dim the screen to 10% |
| 10 min | Lock (hyprlock) |
| 11 min | Turn the display off |
| 30 min | Suspend |

The screen also locks before suspend.

## Colors from the wallpaper

Picking a wallpaper (Super + Shift + W) runs `hypr/scripts/theme.sh <image>`. Run it without an
argument to regenerate from the current wallpaper. It:

1. sets the wallpaper on every monitor and saves it to `hyprpaper.conf`;
2. runs `matugen` (dark Material You scheme) with the templates in `matugen/templates/`, writing to
   `~/.local/state/theme/`, so the repo doesn't change on every switch;
3. reloads what's running.

| What | Gets its colors from | Updates |
|---|---|---|
| Bar, panels, cheatsheet, notifications | `Theme.qml` reads `quickshell.json` | live |
| kitty | `kitty.conf` includes `kitty.conf` | live (SIGUSR1) |
| Alacritty | `~/.config/alacritty/alacritty.toml` imports `alacritty.toml` | live |
| Hyprland borders | `settings.lua` loads `hyprland.lua` | live (`hyprctl reload`) |
| Lock screen (blurred wallpaper + colors) | `hyprlock.conf` sources `hyprlock.conf` | next lock |
| fuzzel (clipboard, passwords) | `fuzzel.ini` includes `fuzzel.ini` | next launch |
| Thunar and other GTK apps | `gtk/` (`gtk-3.0`/`gtk-4.0/gtk.css`) imports `gtk.css` | GTK3 live, GTK4 on restart |
| starship | `STARSHIP_CONFIG` → `starship.toml` (your config + generated palette) | next prompt |

The 16 terminal colors are Catppuccin's hues shifted toward the wallpaper (matugen
`custom_colors`), so red stays red. Every app falls back to Catppuccin Mocha if the generated
files are missing.

starship has no include, so `~/.zshrc` points it at the generated copy:

```sh
[[ -f ~/.local/state/theme/starship.toml ]] && export STARSHIP_CONFIG=~/.local/state/theme/starship.toml
```

Edit `starship/.config/starship.toml` as usual; the generated copy is rebuilt on the next theme
change (or run `theme.sh`).

## Customizing

- **Colors**: see [Colors from the wallpaper](#colors-from-the-wallpaper). Which color goes where is
  set in the templates in `matugen/templates/`.
- **Font**: `Theme.font` in Quickshell, `font=` in fuzzel and mako, and fontconfig defaults
  (sans → FiraCode Nerd Font Propo, monospace → FiraCode Nerd Font Mono).
- **Bar contents**: edit the `RowLayout` in `Bar.qml`. Each module is a short QML file.
- **Wallpaper**: Super + Shift + W, or `hypr/scripts/theme.sh <image>`.

## Reloading and troubleshooting

| What | Command |
|---|---|
| Reload Hyprland config | `hyprctl reload`, then check `hyprctl configerrors` |
| Restart the bar | `qs kill; hyprctl dispatch 'hl.dsp.exec_cmd("QS_ICON_THEME=Papirus-Dark qs")'` |
| Bar logs | `qs log` |
| Test notifications | `notify-send -A default=Open -A later=Later "Title" "Body"` |
| Log out | Power menu, or `hyprctl dispatch 'hl.dsp.exit()'` |

Notes:
- Programs start from `autostart.lua`, not from systemd user services, because
  `graphical-session.target` isn't started in this Hyprland session.
- Only one polkit agent can run. If hyprpolkitagent fails with "An authentication agent already
  exists", another agent is still running.
- `cliphist` only records what's copied after login. `wl-paste --watch` runs from autostart.
