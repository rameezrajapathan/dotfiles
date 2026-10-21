# The pikadots command

[← README](../README.md)

```
pikadots install      packages, links into $HOME, services, colors
pikadots link         only link the files in config/ into $HOME
pikadots uninstall    undo install, then optionally remove packages
pikadots health       check everything (alias: check, doctor)
pikadots repair       fix what health finds (alias: fix)
pikadots update       pull the repo, then repair if anything changed
pikadots backup       back up now
pikadots backup-init  set up encrypted daily backups
pikadots export       save your settings to one file
pikadots import FILE  apply an exported file on this machine
pikadots greeter [--reset]  login screen with the wallpaper (Plasma Login Manager)
pikadots splash [--reset]   boot splash (Plymouth) in the wallpaper colors
pikadots keybinds [status|reset]  reset restores the default keybinds.lua and clears Settings shortcut changes
pikadots docs-check   compare keybinds.lua with docs/keybindings.md
pikadots help         this list
```

## install

1. Installs [`packages.txt`](../packages.txt) with pacman, [`aur.txt`](../aur.txt) with yay or paru
   when present, and `asusctl` on ASUS laptops.
2. Links the files in `config/` into `$HOME` (`config/hypr` → `~/.config/hypr`; the full list is the
   `links` table at the top of `config/pikadots/pikadots`). Files in the way are moved to
   `~/.local/state/pikadots/backups/<date>/`. `pikadots link` does only this step.
3. Asks for your git name and email, saved to `~/.config/git/user`. `config/git` is linked as a
   whole, so the file sits in the repo folder, but `config/git/.gitignore` keeps it out of git.
4. Enables NetworkManager, Bluetooth, power-profiles-daemon and the SSH agent, masks other
   notification daemons (mako, dunst, swaync) so the shell shows notifications, and enables the
   daily backup timer if a restic password already exists.
5. Sets up the apps that follow the wallpaper: the Pywalfox helper for Firefox and Zen, each Zen
   and [Thunderbird](theming.md#thunderbird) profile's `user.js` and `userChrome.css`, the
   [mpv](theming.md#mpv) font file and the VS Code theme. Sets default apps that aren't
   set yet ([desktop.md](desktop.md#default-apps)).
6. Creates `~/Pictures/Screenshots` and `~/Videos/Recordings`, copies the
   [wallpapers](../wallpapers/CREDITS.md) into `~/Pictures/Wallpapers` (existing files are left
   alone) and generates colors from the current one. Inside Hyprland it then reloads Hyprland and
   restarts the shell.

## health and repair

`health` prints a ✓ / ! / ✗ line for: packages (and AUR packages), links, services and the
backup timer, Hyprland config errors, Quickshell showing notifications (not another daemon),
Quickshell running without errors, generated colors, `settings.json` being valid JSON, the glass
shader's `.qsb` being built and newer than its source, hypridle, the Pywalfox helper, git identity,
keyring, SSH agent, GitHub sign-in, the calendar link, whether
[docs/keybindings.md](keybindings.md) matches `keybinds.lua`, the login screen and boot splash
(informational), snapper snapshots, the last backup and, on ASUS laptops, the battery charge
limit. `repair` runs the install steps again (packages, links, services, Pywalfox, Zen,
Thunderbird, mpv, VS Code theme, default apps, colors), then reloads Hyprland and restarts the shell. Safe to
run any time.

## update

Pulls the repo (`git pull --rebase --autostash`) and shows the new commits. Only when something
new came in does it run repair (new packages, links and services), and when snapper has a root
config it takes a pre/post snapshot pair named "pikadots update" around it (skipped when snap-pac
is installed, since that already snapshots every pacman run); when it's already up to date it
stops there, and `pikadots repair` checks everything anyway.
Settings > Updates shows what's new before you update, checks in the background and runs this
for you in a terminal ([settings.md](settings.md#updates)).

## uninstall

Asks first. Stops the backup timer, puts Plasma's own colors, icons and fonts back into
`~/.config/kdeglobals` and its cursor into `~/.config/kcminputrc` (see [Qt and KDE apps](theming.md#qt-and-kde-apps)) and restores the VS Code
settings ([theming.md](theming.md#vs-code-and-code---oss)). Then it removes the links and copies
back the files from the oldest folder in `~/.local/state/pikadots/backups/` (the one from the
first install) with `cp -an`, so it never overwrites a file that's there now. If the login screen
or boot splash was themed, it offers `greeter --reset` and `splash --reset` (each asks before using
sudo). Backups, the keyring and your git identity stay.

Then it offers to remove the packages pikadots installed: **y** removes them, **e** opens the list
in `$EDITOR` to choose, anything else keeps them. Essentials (`networkmanager`, `networkmanager-openvpn`,
`bluez`, `bluez-utils`, `pipewire-pulse`, `wireplumber`, `upower`, `power-profiles-daemon`, `zsh`,
`git`, `neovim`, `xdg-utils`, `xdg-user-dirs`, `gnome-keyring`, `libsecret`, `restic`, `asusctl`)
are never offered, nor anything another installed package needs.

## Login screen and boot splash

Both are opt-in, change files outside your home folder, and list exactly what they'll do before
asking and using sudo. Run them again after changing the wallpaper; `--reset` undoes them.

- **`pikadots greeter`** (Plasma Login Manager only): copies the wallpaper to
  `/var/lib/pikadots/greeter`, writes `/etc/plasmalogin.conf.d/pikadots.conf` to show it, and
  copies the KDE colors (when [Qt and KDE apps](theming.md#qt-and-kde-apps) is on) into the
  greeter's `kdeglobals`, keeping the old one for `--reset`. It warns when
  `/etc/plasmalogin.conf` sets its own wallpaper, which would win.
- **`pikadots splash`**: installs a pikadots Plymouth script theme from `config/plymouth` (the
  wallpaper's base color, the distro logo, an accent spinner and a password prompt for encrypted
  disks) and switches to it with `sudo plymouth-set-default-theme -R`, which rebuilds the
  initramfs. The kernel command line needs `splash`. The previous theme is saved in
  `~/.local/state/pikadots/splash-previous` (and a copy inside the theme folder) for `--reset`.

To go back, run `pikadots greeter --reset` or `pikadots splash --reset`:

- **greeter --reset** removes the drop-in and the copied wallpaper and puts back the login
  screen's old colors, so it looks exactly as before.
- **splash --reset** switches back to the recorded theme, rebuilds the initramfs and removes the
  pikadots theme. If nothing was recorded, it falls back to the distribution default
  (`plymouth-set-default-theme --reset`).
- Both say so and do nothing when there's nothing to undo. `pikadots uninstall` offers both
  resets when they're in place.

## Snapshots

With snapper and a root config, `pikadots update` takes snapshots (above), `health` reports the
newest one's age and the System tab shows it. Listing snapshots needs root, so the age is read
from grub-btrfs's boot menu instead; add yourself to `ALLOW_USERS` in
`/etc/snapper/configs/root` to let it read snapper directly.

## docs-check

`pikadots docs-check` compares `config/hypr/keybinds.lua` with
[docs/keybindings.md](keybindings.md) and lists binds missing from the docs and documented keys
that aren't bound. `health` runs it too.

## export and import

`pikadots export [FILE]` saves what the Settings app changed into one file, by default
`~/pikadots-settings-DATE.tar.gz`. That covers `~/.config/pikadots/settings.json` and the Hyprland
files written from it (Windows, Effects and Input options, startup apps, window rules), plus the
current wallpaper and `~/.face`: `~/.config/pikadots/settings.json`,
`~/.local/state/pikadots/hypr-settings.lua`, `autostart.lua` and `window-rules.lua`. `glass.lua`
isn't saved; it's generated from `settings.json`. Export stops with an error if there's no
`settings.json` yet (nothing changed in the Settings app). Keep the file in cloud storage or on a
USB drive.

On a new machine, after `install.sh`: `pikadots import pikadots-settings-DATE.tar.gz`. It saves
the files it replaces to `~/.local/state/pikadots/backups/import-DATE/`, stops the shell so it
can't write its old settings back, and copies the files in. Then it recolors from the wallpaper
and applies fonts, icons, accessibility, clipboard and idle timers, and restarts the shell. A plain
`settings.json` works too (any JSON file with an `appearance` key is taken as one). Monitor layouts, clipboard pins and backups stay per machine.

## Backups

`pikadots backup-init` creates an encrypted [restic](https://restic.net) repository and a daily
timer. It backs up `~/Projects`, `~/Documents`, `~/Pictures`, `~/dotfiles`, `~/.ssh`, the
keyring and `~/.config/restic`. It skips `bin`, `obj` and `target` in `~/Projects`, and
`node_modules`, `.venv`, `__pycache__`, `.cache` and `*.tmp` anywhere. It keeps 7 daily, 4 weekly
and 6 monthly snapshots; old data is pruned on Sundays (`config/pikadots/pikadots-backup`).

- The location is in `~/.config/pikadots/backup-repo`. A OneDrive or Dropbox folder keeps a copy
  off the machine (it only sees encrypted data).
- **Save `~/.config/restic/password` somewhere else.** Without it the backups can't be read.
- The System tab shows the last backup; failures send a notification.

Restore:

```sh
export RESTIC_REPOSITORY=$(sed "s|^~|$HOME|" ~/.config/pikadots/backup-repo) RESTIC_PASSWORD_FILE=~/.config/restic/password
restic snapshots
restic restore latest --target ~/restored --include ~/Projects/myapp
```

## Repo layout

```
config/       one folder per app (config/kitty → ~/.config/kitty; some apps link single files)
docs/         these pages and their screenshots
wallpapers/   copied to ~/Pictures/Wallpapers on install
install.sh    first-time setup (runs pikadots install)
packages.txt  pacman packages; aur.txt: AUR packages
```

Most folders are linked whole, but some apps only get single files linked, such as
`config/zsh/zshrc` → `~/.zshrc`, `config/starship/starship.toml` → `~/.config/starship.toml`, the
GTK, btop, cava, superfile, lazygit (`config.yml`) and mpv (`mpv.conf` only, so your
`input.conf` and scripts stay yours) files, and the scripts in `config/pikadots` → `~/.local/bin`. The
`links` table at the top of `config/pikadots/pikadots` lists every one.

The shell (`config/quickshell/`) is split by role: `bar/`, `controlcenter/`,
`panels/` (control center pages), `overlays/` (launcher, overview, switcher, OSD, popups),
`lock/`, `settings/` (the Settings app), `services/` (singletons: state and system access),
`widgets/` (shared controls) and `shaders/` (the glass shader and its compiled `.qsb`). Files import other folders as `import qs.<folder>`.
