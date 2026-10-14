# pikadots

A complete Hyprland desktop and developer setup for Arch Linux and CachyOS. Hyprland (Lua config)
with a Quickshell bar and panels, colors taken from the wallpaper, Material Symbols icons, and a
`pikadots` command to install, check, repair, update and remove it all.

- **Wallpaper-driven colors**: picking a wallpaper recolors the bar and panels, kitty, Neovim,
  GTK apps, the lock screen, cava, fastfetch, git diffs, Hyprland borders and the keyboard lights.
- **One bar for everything**: workspaces, music, clock and next meeting, window title, tray,
  capture, network, Bluetooth, volume, system monitor, battery, GitHub, notifications, quick
  settings and power, each with its own dropdown panel.
- **Launcher with modes**: apps, calculator, commands, emoji, projects and clipboard history.
- **Developer tools**: drop-down terminal, Alt + Tab with live previews, a workspace overview,
  keyring and SSH agent, git with delta, GitHub notifications, per-project tool versions,
  daily encrypted backups.
- **Laptop care**: battery charge limit, GPU modes and keyboard lighting on ASUS ROG laptops,
  power profiles, lid handling, idle dimming and locking.

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [The pikadots command](#the-pikadots-command)
- [Packages](#packages)
- [The desktop](#the-desktop)
- [Keybindings](#keybindings)
- [Colors from the wallpaper](#colors-from-the-wallpaper)
- [Developer setup](#developer-setup)
- [Backups](#backups)
- [Laptop and power](#laptop-and-power)
- [Repository layout](#repository-layout)
- [Customizing](#customizing)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

## Requirements

- Arch Linux or a derivative (CachyOS, EndeavourOS, …) with `pacman` and `sudo`.
- Hyprland 0.56 or newer (the config is written in Lua) and Quickshell 0.3 or newer.
- A login manager that offers a Hyprland session (any of SDDM, Plasma Login, greetd, …).
- Optional: `yay` or `paru` for the one AUR package (the cursor theme).

## Installation

```sh
git clone <this repo> ~/dotfiles
~/dotfiles/install.sh
```

`~/dotfiles` is the expected place (the backup includes that folder), but the links work from
anywhere. `install.sh` installs stow if needed and runs
`pikadots install`, which:

1. **Installs packages** from [`packages.txt`](packages.txt) with pacman, the AUR ones from
   [`aur.txt`](aur.txt) when yay or paru is present, and `asusctl` on ASUS laptops.
2. **Links the configs** into `$HOME` with GNU Stow. Any file it would replace is moved to
   `~/.local/state/pikadots/backups/<date>/` first, and `pikadots uninstall` puts it back.
3. **Asks for your git name and email** and saves them to `~/.config/git/user`, which stays out
   of the repo.
4. **Enables services**: NetworkManager, Bluetooth and power-profiles-daemon (system), and the
   gnome-keyring SSH agent (user).
5. **Generates colors** from the current wallpaper, or the first image in
   `~/Pictures/Wallpapers`.

Then log out and choose the **Hyprland** session. Everything starts from
`hypr/.config/hypr/autostart.lua`.

### After installing

| Step | How |
|---|---|
| Add wallpapers | Put images in `~/Pictures/Wallpapers`, then Super + Shift + W |
| Set up backups | `pikadots backup-init`, then save the password somewhere safe ([Backups](#backups)) |
| GitHub in the bar | `gh auth login` |
| SSH key | `ssh-keygen -t ed25519 && gh ssh-key add ~/.ssh/id_ed25519.pub` |
| Next meeting in the bar | Put your calendar's ICS link in `~/.config/pikadots/calendar.url` ([details](#next-meeting)) |
| Check everything | `pikadots health` |

### Machine-specific settings

| File | What to change |
|---|---|
| `hypr/.config/hypr/monitors.lua` | Output name, resolution, refresh rate, scale (other monitors get `preferred, auto`) |
| `hypr/.config/hypr/hyprpaper.conf` | Wallpaper path (the wallpaper picker rewrites it) |
| `hypr/.config/hypr/scripts/vpn.sh` | Default VPN connection name (`Office VPN`) |
| `hypr/.config/hypr/autostart.lua` | Apps started hidden at login (Thunderbird, Teams and WhatsApp Chrome apps) |
| `hypr/.config/hypr/background.lua` | Apps that Super + Q hides instead of closing |
| `hypr/.config/hypr/keybinds.lua` | Super + B browser (Zen), Super + C editor (VS Code), Super + E file manager (Thunar) |
| `~/.config/pikadots/backup-repo` | Backup location (default `~/Backups/restic`) |

### Apps the keybindings open

These are your choice and aren't installed by pikadots: **Zen Browser** (`zen-browser-bin`,
AUR), **Visual Studio Code** (`code`), **Thunderbird**, **Google Chrome** (Teams and WhatsApp as
Chrome apps), **OneDriveGUI** and **Remmina** (started into the tray). Change or remove them in
`keybinds.lua`, `autostart.lua` and `scripts/tray-apps.sh`.

## The pikadots command

```
pikadots install      packages, links into $HOME (existing files backed up), services, colors
pikadots uninstall    remove the links, restore the backed-up files, stop the services,
                      then optionally remove the packages pikadots installed
pikadots health       check packages, links, services, configs, keyring, backups, …
pikadots repair       fix what health finds: packages, links, services, colors, reloads
pikadots update       pull the repo, then repair (new packages and links included)
pikadots backup       back up now
pikadots backup-init  create the backup password and repository, enable the daily backup
```

`health`, `repair` and `update` can also be called as `check`/`doctor` and `fix`.

### health

Prints a ✓ / ! / ✗ line per check and exits with 1 if anything failed:

- **Packages**: everything in `packages.txt` (plus `asusctl` on ASUS) is installed; AUR ones are
  reported as warnings.
- **Links**: every stow package is fully linked (`stow -n` finds nothing to do).
- **Services**: NetworkManager, Bluetooth, power-profiles-daemon, the SSH agent socket and the
  backup timer.
- **Desktop**: `hyprctl configerrors` is empty, Quickshell is running without load errors, and
  the wallpaper colors exist.
- **Developer**: git identity, keyring (Secret Service), SSH agent, GitHub CLI sign-in, calendar
  link.
- **Backups**: the last backup succeeded within 48 hours.
- **Laptop** (ASUS): a battery charge limit is set.

### repair

Installs missing packages, relinks every package (backing up anything in the way), re-enables
the services, regenerates the colors, reloads Hyprland and restarts Quickshell. Safe to run any
time.

### update

`git pull --rebase --autostash` in the repo, shows the new commits, then runs repair so new
packages, files and services are picked up.

### uninstall

Asks first. Stops the backup timer, removes every link, and copies back the files saved at the
first install (without overwriting anything). Backups, the keyring and your git identity are left
alone.

Then it lists packages it can remove and asks: **y** removes them all (`pacman -Rns`), **e** opens
the list in `$EDITOR` so you can delete the lines of ones to keep, anything else keeps them all.
The list is the packages install put on the machine (recorded in
`~/.local/state/pikadots/installed-packages`; installs from before that was recorded fall back to
`packages.txt` and `aur.txt`), minus:

- essentials, never offered: `keep_packages` in the script (networkmanager, bluez, pipewire,
  power daemons, zsh, git, neovim, stow, gnome-keyring, restic, asusctl, …)
- packages that aren't installed
- packages something outside the list still depends on (for example hyprland when HyprMod's
  python-hyprland-* packages are installed)

### Where pikadots keeps things

| Path | What |
|---|---|
| `~/.local/state/pikadots/backups/<date>/` | Files that install or repair moved out of the way |
| `~/.local/state/pikadots/backup.json` | Result of the last backup (shown in the system panel) |
| `~/.local/state/pikadots/installed-packages` | Packages install added, offered by uninstall |
| `~/.config/pikadots/backup-repo` | Backup location |
| `~/.config/pikadots/calendar.url` | Calendar ICS link (private, not in the repo) |
| `~/.config/git/user` | Your git name and email (git-ignored) |

Each top-level folder of the repo is a stow package that mirrors `$HOME`; for example
`hypr/.config/hypr` becomes `~/.config/hypr`. The `pikadots` package links single files
(`--no-folding`) so programs that write into `~/.local/bin` or `~/.config/systemd/user` don't
write into the repo.

## Packages

Everything below is in the official repos and listed in [`packages.txt`](packages.txt).

**Desktop**

| Package | Used for |
|---|---|
| hyprland | Compositor (Lua config) |
| quickshell | Bar, panels, launcher, notifications, OSD, overview, switcher, power menu |
| hypridle | Dim, lock, screen off and suspend on idle |
| hyprlock | Lock screen |
| hyprpaper | Wallpaper |
| hyprpolkitagent | Password prompts for admin actions |
| hyprpicker | Color picker |
| hyprsunset | Night light |
| xdg-desktop-portal-hyprland | Screen sharing, file pickers |
| xdg-user-dirs | `~/Pictures`, `~/Videos`, … paths for screenshots and recordings |
| matugen | Material You colors from the wallpaper |
| adw-gtk-theme | GTK3 theme that takes the generated colors |
| papirus-icon-theme | App icons (bar, launcher, notifications) |
| ttf-firacode-nerd | Main font, terminal and Neovim icons |
| ttf-fira-sans | Lock screen clock and text |
| ttf-material-symbols-variable | Icons in the shell (Material Symbols Rounded) |

**Apps and tools the shell uses**

| Package | Used for |
|---|---|
| kitty | Terminal (and the drop-down terminal) |
| fuzzel | Wi-Fi and VPN password prompts |
| fastfetch | System info in new terminals (Super + T) |
| starship | Shell prompt |
| cava | Audio visualizer |
| btop | Full system monitor (from the system panel) |
| grim, slurp | Screenshots |
| wl-clipboard, cliphist | Clipboard and clipboard history |
| wf-recorder | Screen recording |
| jq | JSON in scripts |
| brightnessctl | Screen and keyboard brightness |
| libnotify | `notify-send` |
| libqalculate | Launcher calculator (`qalc`) |
| unicode-emoji | Launcher emoji list |
| zoxide | Smarter `cd`, and the launcher's project list |
| eza | `ls` with icons |
| stow | Linking the configs |
| xdg-utils | Opening links and folders |
| pavucontrol | Advanced audio settings |
| thunar | File manager |

**System services**

| Package | Used for |
|---|---|
| networkmanager, networkmanager-openvpn | Wired, Wi-Fi and VPN |
| bluez, bluez-utils | Bluetooth |
| pipewire-pulse, wireplumber | Audio |
| upower | Battery status |
| power-profiles-daemon | Power saver / balanced / performance |

**Shell**

| Package | Used for |
|---|---|
| zsh, zsh-autosuggestions, zsh-syntax-highlighting | Shell (`zsh/.zshrc`) |

**Developer**

| Package | Used for |
|---|---|
| git, git-delta | Version control, readable diffs |
| neovim | Editor (projects open in it with Shift + Enter) |
| github-cli | `gh`, GitHub notifications in the bar |
| lazygit | Git in the terminal |
| mise | Per-project .NET / Node / Python versions |
| gnome-keyring, seahorse, libsecret | Password store, SSH agent, and an app to view them |

**Backups and calendar**

| Package | Used for |
|---|---|
| restic | Encrypted backups |
| python-icalendar, python-recurring-ical-events | Reading the calendar for the next meeting |

**Also installed when available**

| Package | When | Used for |
|---|---|---|
| bibata-cursor-theme-bin | yay or paru present (AUR) | Cursor theme (Bibata Modern Ice) |
| asusctl | ASUS laptops | Battery limit, GPU mode, keyboard lighting |

## The desktop

### The bar

Rounded "pills" across the top, transparent between them, with the desktop blurred behind.

| Where | Item | Click | Other |
|---|---|---|---|
| Left | Distro logo | App launcher | Found from `/etc/os-release`, so it shows your distro |
| Left | Workspaces | Switch workspace | The active one is a wide pill |
| Left | Music | Music panel | Right click play/pause, scroll skips tracks |
| Center | Clock | Calendar | |
| Center | Next meeting | Join the call | Only when a calendar is set and a meeting is within 12 h |
| Center | Window title | | Focused window's icon and title |
| Right | Tray | Open the app | Right click for its menu |
| Right | Capture | Capture menu | Right click: region screenshot; red timer while recording, click to stop |
| Right | Wallpaper (palette) | Wallpaper picker | |
| Right | Network | Network panel | Shows a key while a VPN is connected |
| Right | Bluetooth | Bluetooth panel | Right click turns it on or off |
| Right | Volume | Audio panel | Right click mutes, scroll changes volume |
| Right | System monitor | System panel | |
| Right | Battery | Battery panel | Charging bolt, warning when low |
| Right | GitHub | GitHub panel | Only after `gh auth login`; unread count |
| Right | Bell | Notification list | Right click toggles Do Not Disturb; unread count |
| Right | Coffee cup | Turn keep-awake off | Only while keep-awake is on |
| Right | Quick settings | Quick settings panel | |
| Right | Power | Power menu | |

### Panels

All panels drop down under the bar; click outside to close.

- **Music**: album art, title, artist and album, seek bar, previous / play-pause / next,
  shuffle, repeat, app volume, and a switcher when several apps play media. Works with any
  MPRIS player: Spotify, browsers (YouTube Music, …), VLC, mpv.
- **Calendar**: month view with the time; arrows or scroll change the month.
- **Network**: wired status, Wi-Fi on/off and networks (click to connect; secured ones ask for
  the password), saved-network "forget", VPN switches, and `nmtui` under **settings**.
- **Bluetooth**: on/off, paired devices (click to connect or disconnect, battery level, forget),
  and nearby devices while the panel is open (click to pair). **settings** opens `bluetoothctl`.
- **Audio**: output and input devices with volume, per-app volume, `pavucontrol` under
  **settings**.
- **System**: CPU, memory, GPU and disk usage with temperatures, fan speeds, the busiest
  processes and the last backup with a **back up now** button. A sleeping NVIDIA GPU isn't woken
  to read it. **btop** opens the full monitor.
- **Battery**: charge and time left, battery care (charge limit and "charge to 100% once"),
  power mode, and the GPU mode on ROG laptops.
- **GitHub**: notifications (review requests, mentions, CI, …); click to open, **mark all read**.
- **Notifications**: every notification, newest first, with **clear all**.
- **Capture**: screenshot a region, window or screen; record a region or screen.
- **Quick settings**: Do Not Disturb, keep awake, night light, color picker.

### Launcher (Super + A)

A grid of apps, most used first. Type to search by name, description, keywords or category. A
first character switches mode:

| Prefix | Mode | Enter | Shift + Enter |
|---|---|---|---|
| (none) | Apps | Open | |
| `=` | Calculator (`qalc`, units work: `=5 GiB to MB`) | Copy the result | |
| `>` | Run a command | Run it | Run it in a terminal |
| `:` | Emoji search | Copy the emoji | |
| `~` | Projects (zoxide folders with `.git` or a project file) | Open in VS Code | Open in Neovim |
| `+` | Clipboard history with image thumbnails | Copy it again | |

In clipboard mode Shift + Delete removes an entry. Arrows move, Esc closes. Super + P opens
projects and Super + V the clipboard directly.

### Overlays

- **Power menu** (Super + Escape or the power icon): Lock, Log out, Suspend, Restart, Shut down;
  click, use the arrows, or press L / E / S / R / P.
- **Alt + Tab**: live previews of the open windows, most recent first; release Alt to switch.
- **Overview** (Super + Tab): every workspace in use with live window previews in place. Click a
  window or workspace, or press 1–9.
- **Drop-down terminal** (Super + `): a kitty terminal that slides down from the top and keeps
  running while hidden.
- **Keybinding cheatsheet** (Super + ?): every shortcut, grouped, read live from Hyprland. Type
  to filter.
- **Wallpaper picker** (Super + Shift + W): thumbnails of `~/Pictures/Wallpapers`; picking one
  recolors everything.
- **Volume / brightness indicator**: appears when the volume, mute, mic-mute, screen-brightness or
  keyboard-light keys are used.

### Notifications

Quickshell is the notification daemon. Popups slide in at the top right, tinted with the accent
color, with the app's icon, actions as buttons, and a line that shows the time left (6 s by
default; hovering pauses it). Critical ones are red and stay until dismissed. Clicking a
notification runs its default action. Everything stays in the notification list until dismissed.
**Do Not Disturb** (quick settings, Super + Shift + N, or right click on the bell) stops popups
except critical ones.

### Lock screen

hyprlock with the current wallpaper lightly blurred, the date and a large clock at the top, a
greeting and a rounded password field at the bottom, now playing at the bottom left and the
battery at the bottom right. It locks after 10 minutes idle, before suspend, and from the power
menu (Super + Escape, L) or Super + Alt + L.

### Terminal

kitty with a translucent, blurred background. **Super + T** opens it with fastfetch (a pika photo
beside the system info, in the wallpaper's colors); **Super + Return** opens a plain one. The
prompt is starship, `ls` is eza, `cd` is zoxide.

## Keybindings

`Super` is the main key. Super + ? shows all of these on screen.

### Apps and system

| Keys | Action |
|---|---|
| Super + A | App launcher |
| Super + P | Projects (launcher `~` mode) |
| Super + V | Clipboard history (launcher `+` mode) |
| Super + T | Terminal with fastfetch |
| Super + Return | Terminal |
| Super + ` | Drop-down terminal |
| Super + B | Browser (Zen) |
| Super + C | VS Code |
| Super + E | File manager (Thunar) |
| Super + N | Notification list |
| Super + Shift + N | Do Not Disturb on/off |
| Super + S | Quick settings |
| Super + Shift + C | Pick a color from the screen (copies hex) |
| Super + Shift + W | Wallpaper picker |
| Super + ? | Keybinding cheatsheet |
| Super + Escape | Power menu |
| Super + Alt + L | Lock |

### Windows

| Keys | Action |
|---|---|
| Alt + Tab / Alt + Shift + Tab | Switch windows (hold Alt) |
| Super + Tab | Overview of all workspaces |
| Super + Q | Close window (Thunderbird and Chrome apps hide instead) |
| Super + F | Floating on/off |
| Super + Shift + M | Maximize |
| Super + M / Super + Ctrl + F | Fullscreen |
| Super + W | Group windows |
| Super + Arrows | Move focus |
| Super + Shift + Arrows | Move the window |
| Super + J | Change split direction |
| Super + [ / ] | Next window opens left / right |
| Super + - / = | Narrower / wider (with Shift: shorter / taller) |
| Super + left drag, or Super + Z | Move with the mouse |
| Super + right drag, or Super + X | Resize with the mouse |

### Workspaces and monitors

| Keys | Action |
|---|---|
| Super + 1…9 | Go to workspace |
| Super + Shift + 1…9 | Move the window there |
| Super + Alt + 1…9 | Move the window there without following |
| Super + U / I, Super + Page Down / Up, Super + scroll | Next / previous workspace |
| Super + Shift + U / I, Super + Ctrl + Down / Up, Super + Ctrl + scroll | Move the window to the next / previous workspace |
| Super + F1 / F2 | Show or hide scratch workspaces (with Shift: move the window there) |
| Super + Ctrl + Left / Right or H / J / K / L | Focus another monitor |
| Super + Shift + Ctrl + Arrows or H / J / K / L | Move the window to another monitor |
| Three-finger swipe | Switch workspace |

### Screenshots and recording

| Keys | Action |
|---|---|
| Print | Region → clipboard |
| Ctrl + Print | Screen → clipboard |
| Alt + Print | Window → clipboard |
| Super + Shift + F | Region → clipboard and `~/Pictures/Screenshots` |
| Super + Shift + R | Record a region (again to stop) |
| Super + Alt + R | Record the screen (again to stop) |

The capture icon in the bar does the same with a menu; screenshots taken there are always saved
and show a notification with a preview. Recordings are H.264 MP4 with desktop audio in
`~/Videos/Recordings`.

### Hardware keys

Volume up/down, mute, mic mute, screen and keyboard brightness show the on-screen indicator. Play,
pause, next and previous control the player shown in the music panel. Volume, mute and screen
brightness also work on the lock screen. Closing the lid with an external monitor attached turns
the laptop screen off.

## Colors from the wallpaper

Picking a wallpaper runs `hypr/scripts/theme.sh <image>` (without an argument it regenerates from
the current one). It sets the wallpaper with hyprpaper, runs **matugen** (Material You) on the
templates in `matugen/.config/matugen/templates/`, and reloads what's running.
Generated files go to `~/.local/state/theme/`, so switching wallpapers doesn't change the repo.

| What | How it gets the colors | Updates |
|---|---|---|
| Bar, panels, launcher, notifications | `Theme.qml` reads `quickshell.json` | Live |
| Hyprland borders | `settings.lua` loads `hyprland.lua` | Live |
| kitty (and so fastfetch, delta, lazygit) | `kitty.conf` includes `kitty.conf` | Live |
| Neovim | Catppuccin with the palette from `nvim.lua` ([Neovim](#neovim)) | Live |
| cava | `themes/wallpaper` gradient | Live |
| peaclock | matugen writes `~/.peaclock/config` (colors only) | Next start |
| GTK apps (Thunar, …) | `gtk.css` (translucent backgrounds, about kitty's 0.85 with blur) | GTK3 live, GTK4 on restart |
| Lock screen | `hyprlock.conf` sources `hyprlock.conf` | Next lock |
| fuzzel | `fuzzel.ini` includes `fuzzel.ini` | Next launch |
| starship | `STARSHIP_CONFIG` points at a generated copy | Next prompt |
| Alacritty (if used) | imports `alacritty.toml` | Live |
| ROG keyboard lighting | `asusctl aura effect static` with the accent | Immediately |

`hypr/scripts/theme-palette.py` looks at the wallpaper first (OKLab, on a 64×64 copy) and picks:

- **Light or dark**: light when the average lightness is above 0.6. Also switches the GTK theme
  (adw-gtk3 / adw-gtk3-dark), `color-scheme` (libadwaita apps, websites), Papirus / Papirus-Dark
  and Neovim's Catppuccin flavour (Latte / Mocha).
- **How colorful**: from the average chroma relative to lightness. Black and white or grey
  wallpapers get `scheme-monochrome` (pure greys, white or black accent), or `scheme-neutral`
  when a small colored spot stands out (a red sun on a grey painting). Muted ones also get
  `scheme-neutral`, then `scheme-tonal-spot`, and very colorful ones `scheme-content`, which
  follows the wallpaper's own colors.

Terminal colors (`ansi.*` in the templates) are Catppuccin's hues made by the same script, with
the mode's lightness and as much chroma as the wallpaper has, nudged up to 8° toward its main
hue. On grey wallpapers they're greyish but red and green still differ. Without generated files
everything falls back to Catppuccin Mocha. To tune it, change the thresholds in `main()`.

## Developer setup

### Keyring and SSH

**gnome-keyring** stores passwords for VS Code, git, browsers and other apps (Secret Service) and
unlocks with your login password through the login manager's PAM config. Its **SSH agent** runs
as the `gcr-ssh-agent.socket` user service; `settings.lua` sets `SSH_AUTH_SOCK` to it. **Seahorse**
shows what's stored.

### git

`git/.config/git/config` (linked to `~/.config/git/config`):

- **delta** for diffs, with line numbers and the terminal's (wallpaper) colors;
- `zdiff3` conflict markers and moved-line highlighting;
- HTTPS credentials saved in the keyring (`git-credential-libsecret`);
- `main` as the default branch;
- your name and email from `~/.config/git/user` (not in the repo).

lazygit shows diffs through delta too (`~/.config/lazygit/config.yml`).

### GitHub

After `gh auth login`, a GitHub icon in the bar shows unread notifications (review requests,
mentions, CI results). The panel lists them; click one to open it in the browser.

### Projects and tool versions

- The launcher's `~` mode (Super + P) lists folders you use often (from zoxide) that have a git
  repo or a project file (`package.json`, `*.csproj`, `*.sln`, `Cargo.toml`, `go.mod`,
  `pyproject.toml`). Enter opens VS Code, Shift + Enter Neovim.
- **mise** switches .NET, Node, Python and other versions per project from `mise.toml` or
  `.tool-versions` when you `cd` in.

### Neovim

The Neovim config is its own repo in `~/.config/nvim`. Its Catppuccin setup
(`lua/plugins/catppuccin.lua`) loads the palette matugen writes to `~/.local/state/theme/nvim.lua`,
uses a transparent background so kitty's blur shows through, and reloads when the wallpaper
changes. The status line is lualine with rounded sections.

### Next meeting

`pikadots-meetings` reads a published calendar (ICS) and the bar shows the next meeting beside
the clock: "Standup in 10 min", red while it's on. Clicking it opens the Teams / Zoom / Meet link
from the invite, and a notification comes 5 minutes before. Recurring meetings are handled.

To get an Outlook link: Outlook on the web → Settings → Calendar → Shared calendars → Publish a
calendar → choose a permission → copy the **ICS** link. Then:

```sh
mkdir -p ~/.config/pikadots && echo '<ICS link>' > ~/.config/pikadots/calendar.url
```

The link gives read access to your calendar, so it's kept out of the repo.

## Backups

`pikadots-backup` makes encrypted, deduplicated backups with **restic**, daily through the
`pikadots-backup.timer` user timer (if the laptop was off it runs at the next boot).

- **What**: `~/Projects`, `~/Documents`, `~/Pictures`, `~/dotfiles`, `~/.ssh`,
  `~/.local/share/keyrings` and `~/.config/restic`. Skipped: `node_modules`, `.venv`, and `bin`,
  `obj` and `target` inside projects.
- **Where**: the folder in `~/.config/pikadots/backup-repo` (default `~/Backups/restic`). A folder
  synced by OneDrive, Dropbox or similar keeps a copy off the machine; it only ever sees encrypted
  data.
- **Kept**: 7 daily, 4 weekly and 6 monthly snapshots (pruned on Sundays).
- **Password**: `~/.config/restic/password`. **Keep a copy somewhere else** (a password manager);
  without it the backups can't be read.
- **Status**: the system panel shows the last backup and has **back up now**; failures send a
  notification.

```sh
pikadots backup-init        # first time: password, repository, daily timer
pikadots backup             # back up now

# Browse and restore
export RESTIC_REPOSITORY=$(sed "s|^~|$HOME|" ~/.config/pikadots/backup-repo) RESTIC_PASSWORD_FILE=~/.config/restic/password
restic snapshots
restic restore latest --target ~/restored                     # everything
restic restore latest --target ~/restored --include ~/Projects/myapp
```

**System snapshots** are separate: on btrfs, snap-pac takes a snapper snapshot before and after
every pacman transaction, and grub-btrfs lists them in the GRUB menu, so a bad update can be
booted around and rolled back (btrfs-assistant).

## Laptop and power

### Idle

From `hypr/.config/hypr/hypridle.conf`:

| After | What happens |
|---|---|
| 5 min | Screen dims to 10% |
| 10 min | Lock |
| 11 min | Screen off |
| 30 min | Suspend |

**Keep awake** (quick settings) holds all of this off; a coffee cup in the bar shows it's on.

### Power and battery

- **Power mode** (battery panel): power saver, balanced or performance (power-profiles-daemon).
- **Battery care** on ASUS laptops: charge limit 80% (switch in the battery panel), with
  **charge to 100% once** for days away from a charger.
- **Night light** (quick settings): warmer colors with hyprsunset.

### ASUS ROG

With `asusctl`:

- **GPU mode** (battery panel), applied after a restart:
  - **Ultimate**: the NVIDIA GPU drives the screen (best performance, most power).
  - **Hybrid**: Intel drives the screen, NVIDIA wakes when an app needs it.
  - **Eco**: NVIDIA switched off. Only offered once Hybrid is active, so the screen always has a
    GPU.
- **Keyboard lighting** follows the wallpaper's accent color.

### Lid

`scripts/lid.sh`: closing the lid with an external monitor attached turns the laptop panel off
and moves everything to the external one; opening it brings the panel back. Without an external
monitor, logind suspends as usual.

### Background apps and the tray

- **Tray** apps (OneDrive, Remmina, …) have their own pill. `scripts/tray-apps.sh` starts them
  after the tray is ready, so closing their window hides them to the tray. Left click opens the
  app; right click (or left click for menu-only apps like Remmina) shows its menu.
- **Thunderbird and Chrome apps** (Teams, WhatsApp) have no tray on Linux, so **Super + Q hides
  them** on a hidden workspace instead of closing them; they keep sending notifications. Their
  icons sit at the start of the tray pill, with a dot while shown. Click to show or hide, right
  click to quit. Thunderbird, Teams and WhatsApp start hidden at login (`autostart.lua`). The list
  is in `background.lua` and the matching pattern in `BackgroundApps.qml`.

### VPN

VPNs are NetworkManager connections, switched on and off in the network panel. To import an
OpenVPN profile:

```sh
nmcli connection import type openvpn file client.ovpn
nmcli connection modify <name> connection.id "Office VPN" +vpn.data username=<user> +vpn.data password-flags=0
```

`scripts/vpn.sh` asks for the password the first time (fuzzel) and NetworkManager saves it;
a failed attempt clears it so the next one asks again.

## Repository layout

```
install.sh                    first-time setup (runs pikadots install)
packages.txt  aur.txt         packages pikadots installs
pikadots/                     → ~/.local/bin and ~/.config/systemd/user (single-file links)
  .local/bin/pikadots           the CLI
  .local/bin/pikadots-backup    restic backup
  .local/bin/pikadots-meetings  next meetings from the calendar (Python)
  .config/systemd/user/pikadots-backup.{service,timer}
hypr/.config/hypr/
  hyprland.lua                  entry point, requires the files below
  monitors.lua  settings.lua  rules.lua  keybinds.lua  autostart.lua  background.lua
  hypridle.conf  hyprlock.conf  hyprpaper.conf
  scripts/
    theme.sh                    set a wallpaper and recolor everything
    screenshot.sh               region | full | active [save]
    record.sh                   region | full (run again to stop)
    dropterm.sh                 drop-down terminal
    sysinfo.sh                  data for the system panel
    lid.sh                      lid switch handling
    lock-status.sh              battery and now-playing lines on the lock screen
    vpn.sh                      VPN toggle with password prompt
    tray-apps.sh                start tray apps once the tray is ready
quickshell/.config/quickshell/
  shell.qml                     everything that isn't per-bar (launcher, overlays, OSD, …)
  Bar.qml  Island.qml           the bar and its pills
  Theme.qml  Icon.qml           colors, fonts, sizes; Material Symbols icon by name
  Launcher.qml  PowerMenu.qml  Cheatsheet.qml  CheatsheetCard.qml  WallpaperPicker.qml
  WindowSwitcher.qml  Overview.qml  Windows.qml
  Osd.qml
  Notification{Service,Popups,Card,Panel,Button}.qml
  Media.qml  MediaButton.qml  MediaPanel.qml
  Network.qml  NetworkPanel.qml  VpnService.qml
  Bluetooth.qml  BluetoothPanel.qml
  Volume.qml  AudioPanel.qml
  Battery.qml  BatteryPanel.qml  Asus.qml
  SystemButton.qml  SystemPanel.qml
  Capture.qml  Recorder.qml  CaptureButton.qml  CapturePanel.qml
  QuickSettingsButton.qml  QuickSettingsPanel.qml  Toggles.qml  KeepAwakeIndicator.qml
  GitHub.qml  GitHubButton.qml  GitHubPanel.qml
  Meetings.qml  NextMeeting.qml  Clock.qml  CalendarPanel.qml
  OsIcon.qml  Workspaces.qml  ActiveWindow.qml  Tray.qml  BackgroundApps.qml
  WallpaperButton.qml  PowerButton.qml
  Label.qml  Pill.qml  Switch.qml  Slider.qml  PanelRow.qml   shared widgets
matugen/.config/matugen/        config.toml and templates/ (one per recolored app)
kitty/  fuzzel/  starship/  fastfetch/  cava/  gtk/  fontconfig/   app configs
git/.config/git/config          git settings (identity in ~/.config/git/user)
zsh/.zshrc                      shell setup
mako/                           old notification daemon config, unused (not linked)
```

## Customizing

- **Bar items**: the pills are in `Bar.qml`; each item is a small QML file.
- **Icons**: `Icon { name: "wifi"; filled: true }` takes any name from
  [Material Symbols](https://fonts.google.com/icons).
- **Fonts**: `Theme.font` in Quickshell; fontconfig defaults (sans → FiraCode Nerd Font Propo,
  monospace → FiraCode Nerd Font Mono); Fira Sans on the lock screen.
- **Which color goes where**: the templates in `matugen/.config/matugen/templates/`.
- **Idle times**: `hypridle.conf`. **Lock screen**: `hyprlock.conf`.
- **Keybindings**: `keybinds.lua` (the cheatsheet updates by itself).
- **fastfetch**: `fastfetch/.config/fastfetch/config.jsonc`; the logo is `pika.png`.

## Troubleshooting

Start with `pikadots health`, and `pikadots repair` if it finds problems.

| What | Command |
|---|---|
| Hyprland config errors | `hyprctl reload && hyprctl configerrors` |
| Restart the bar | `qs kill; hyprctl dispatch 'hl.dsp.exec_cmd("QS_ICON_THEME=Papirus-Dark qs")'` |
| Bar logs | `qs log` |
| Bar commands | `qs ipc show` (e.g. `qs ipc call launcher open '='`) |
| Test a notification | `notify-send -A default=Open "Title" "Body"` |
| Regenerate colors | `~/.config/hypr/scripts/theme.sh` |
| Backup log | `journalctl --user -u pikadots-backup` |
| Log out | Power menu, or `hyprctl dispatch 'hl.dsp.exit()'` |

Notes:

- Programs start from `autostart.lua`, not systemd, because `graphical-session.target` isn't
  started in this Hyprland session.
- Quickshell reloads by itself when a QML file changes. A newly installed font needs a full
  restart (above).
- **Plain-looking notifications** mean another notification daemon (mako, dunst, swaync) took
  over, usually started by D-Bus while Quickshell was restarting. `pikadots repair` masks them;
  `pikadots health` checks who shows notifications.
- Only one polkit agent can run; "An authentication agent already exists" means another one is
  still running.
- cliphist only has what was copied since login.
- Tray menus need Quickshell's QApplication mode (`//@ pragma UseQApplication` at the top of
  `shell.qml`).

## Credits

- [Hyprland](https://hyprland.org), [Quickshell](https://quickshell.org),
  [matugen](https://github.com/InioX/matugen), [Catppuccin](https://catppuccin.com) (fallback
  colors and terminal hues).
- Icons: [Material Symbols](https://fonts.google.com/icons) (Apache 2.0) and
  [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).
- `fastfetch/.config/fastfetch/pika.png` is cropped from
  ["Royle's Pika in it's home"](https://commons.wikimedia.org/wiki/File:Royle%27s_Pika_in_it%27s_home.jpg)
  by Nikeet123, licensed [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); the
  cropped image is under the same license.
