# dotfiles

A minimal Hyprland desktop for CachyOS / Arch: Hyprland (Lua config), a small Quickshell bar,
and a handful of single-purpose tools. Everything uses one fixed palette, **Catppuccin Mocha**,
and **FiraCode Nerd Font**.

| Role | Tool |
|---|---|
| Compositor | Hyprland (Lua config, 0.56+) |
| Bar + network panel | Quickshell |
| App launcher, clipboard picker, power menu, password prompts | fuzzel |
| Notifications | mako |
| Wallpaper | hyprpaper |
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
       fuzzel mako kitty starship fastfetch stow \
       grim slurp wl-clipboard cliphist wf-recorder jq brightnessctl libnotify \
       networkmanager networkmanager-openvpn wireplumber pipewire-pulse upower \
       ttf-firacode-nerd papirus-icon-theme
   ```

2. Clone the repo to `~/dotfiles` and link it into `~/.config` with stow. Stow refuses to overwrite
   real files, so move any existing configs out of the way first:

   ```sh
   cd ~/dotfiles
   stow hypr quickshell fuzzel mako kitty starship fastfetch fontconfig
   ```

   Each top-level folder is a stow package that mirrors `$HOME`. For example,
   `hypr/.config/hypr` becomes `~/.config/hypr`.

3. Log into the **Hyprland** session. Everything starts from `hypr/autostart.lua`.

4. Machine-specific bits to check:
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
  hypridle.conf       idle timeouts
  hyprlock.conf       lock screen
  hyprpaper.conf      wallpaper
  scripts/
    screenshot.sh     region | full | active [save]
    record.sh         region | full; run again to stop
    clipboard.sh      cliphist history in fuzzel
    powermenu.sh      lock / logout / suspend / reboot / shutdown in fuzzel
    vpn.sh            toggle a NetworkManager VPN, saving its password on first use
quickshell/.config/quickshell/
  shell.qml           one Bar per screen
  Bar.qml             bar layout
  Theme.qml           colors, font, sizes (singleton)
  Workspaces.qml  Clock.qml  Recording.qml  Vpn.qml  Network.qml  Volume.qml  Battery.qml
  NetworkPanel.qml    dropdown for wired / Wi-Fi / VPN
  VpnService.qml      VPN state from nmcli (singleton)
  Label.qml  Pill.qml  PanelRow.qml   small shared widgets
fuzzel/  mako/  kitty/  starship/  fastfetch/  fontconfig/
```

## Keybindings

`Super` is the main modifier.

**Apps and session**

| Keys | Action |
|---|---|
| Super + Return | Terminal (kitty) |
| Super + A | App launcher (fuzzel) |
| Super + B | Browser (Zen) |
| Super + C | VS Code |
| Super + E | File manager (Thunar) |
| Super + V | Clipboard history |
| Super + Escape | Power menu |
| Super + Alt + L | Lock |

**Windows**

| Keys | Action |
|---|---|
| Super + Q | Close window |
| Super + F | Maximize |
| Super + M / Super + Ctrl + F | Fullscreen |
| Super + T | Toggle floating |
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

Left to right: workspaces (click to switch), clock, then **rec** (only while recording),
**vpn**, network, volume (click to mute, scroll to change) and battery.

### Network panel

Click **vpn** or the network label to open the panel. Click anywhere else to close it.

- **Wired**: the Ethernet device and its link speed.
- **Wi-Fi**: on/off switch and nearby networks, strongest first. The connected one is highlighted
  and 󰌾 marks secured networks.
  - Click a network to connect, or click the connected one to disconnect.
  - New secured networks ask for their password in a fuzzel prompt.
  - **forget** removes a saved network.
- **VPN**: every NetworkManager VPN or WireGuard connection. Click one to connect or disconnect.
- **settings** opens `nmtui` in kitty for anything else (editing connections, hidden networks,
  static IPs).

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

## Customizing

- **Colors**: Catppuccin Mocha is set in `quickshell/Theme.qml`, `hypr/settings.lua` (borders),
  `hypr/hyprlock.conf`, `fuzzel/fuzzel.ini`, `mako/config`, `kitty/Catppuccin-Mocha.conf` and
  `starship.toml` (`[palettes.main]`). Change them together to switch themes.
- **Font**: `Theme.font` in Quickshell, `font=` in fuzzel and mako, and fontconfig defaults
  (sans → FiraCode Nerd Font Propo, monospace → FiraCode Nerd Font Mono).
- **Bar contents**: edit the `RowLayout` in `Bar.qml`. Each module is a short QML file.
- **Wallpaper**: change `path` in `hyprpaper.conf`, then restart hyprpaper.

## Reloading and troubleshooting

| What | Command |
|---|---|
| Reload Hyprland config | `hyprctl reload`, then check `hyprctl configerrors` |
| Restart the bar | `qs kill; hyprctl dispatch 'hl.dsp.exec_cmd("qs")'` |
| Bar logs | `qs log` |
| Restart notifications | `makoctl reload` |
| Log out | Power menu, or `hyprctl dispatch 'hl.dsp.exit()'` |

Notes:
- Programs start from `autostart.lua`, not from systemd user services, because
  `graphical-session.target` isn't started in this Hyprland session.
- Only one polkit agent can run. If hyprpolkitagent fails with "An authentication agent already
  exists", another agent is still running.
- `cliphist` only records what's copied after login. `wl-paste --watch` runs from autostart.
