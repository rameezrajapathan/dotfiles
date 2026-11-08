# The pikadots command

[← README](../README.md)

```
pikadots install      packages, links into $HOME, services, colors
pikadots link         only link the files in config/ into $HOME
pikadots uninstall    undo install (as far as it safely can), then optionally remove packages
pikadots health       check everything (alias: check, doctor)
pikadots repair       fix what health finds (alias: fix)
pikadots update       pull the repo, then repair if anything changed
pikadots backup       back up now
pikadots backup-init  set up encrypted daily backups
pikadots export       save your settings to one file
pikadots import FILE  apply an exported file on this machine
pikadots setup        go through the welcome steps again
pikadots greeter [--reset]  login screen with the wallpaper (Plasma Login Manager)
pikadots greeter install|remove|preview  the pikadots greeter on greetd
pikadots splash [--reset]   boot splash (Plymouth) in the wallpaper colors
pikadots keybinds [status|reset]  reset restores the default keybinds.lua and clears Settings shortcut changes
pikadots docs-check   compare keybinds.lua with docs/keybindings.md
pikadots help         this list
```

## install

1. Installs [`packages.txt`](../packages.txt) with pacman, [`aur.txt`](../aur.txt) with yay or paru
   when present, and `asusctl` on ASUS laptops. On Fedora it enables the COPR repositories in
   [`copr.txt`](../copr.txt) (plus `lukenukem/asus-linux` on ASUS laptops), installs
   [`packages-fedora.txt`](../packages-fedora.txt) with dnf, and downloads what Fedora doesn't
   package (or ships too old): matugen 4, `spf` (superfile) and `papirus-folders` into
   `~/.local/bin`; FiraCode Nerd Font, Fira Sans and Material Symbols into
   `~/.local/share/fonts/pikadots`; pywalfox and recurring-ical-events with `pip --user`.
   `uninstall` offers to remove them again. wl-clip-persist has no Fedora package, so copied text
   isn't kept after its app closes.
2. Links the files in `config/` into `$HOME` (`config/hypr` → `~/.config/hypr`; the full list is the
   `links` table at the top of `config/pikadots/pikadots`). Files in the way are moved to
   `~/.local/state/pikadots/backups/<date>/`. The shell files in `config/shell` are in the table
   too; the fish and nushell ones are linked only when that shell is installed. `pikadots link`
   does only this step.
3. Asks for your git name and email, saved to `~/.config/git/user`. `config/git` is linked as a
   whole, so the file sits in the repo folder, but `config/git/.gitignore` keeps it out of git.
   Sets up the starship prompt, wallpaper colors for `eza`, the `ls`/`ll`/`la`/`lt` aliases,
   zoxide (`cd`) and mise for bash, zsh, fish and nushell, whichever you use: zsh through
   `~/.zshrc`, bash with one line added to `~/.bashrc` (sourcing `~/.config/pikadots/pikadots.bash`),
   fish in `~/.config/fish/conf.d`, and nushell in `~/.local/share/nushell/vendor/autoload` (plus
   generated `pikadots-starship.nu`, `pikadots-zoxide.nu` and `pikadots-mise.nu` there). Other
   shells are left alone.
4. Enables NetworkManager, Bluetooth, power-profiles-daemon and the SSH agent, masks other
   notification daemons (mako, dunst, swaync) so the shell shows notifications, enables
   `pikadots-idle.service` (the idle timers, started with the Hyprland session) and the daily
   backup timer if a restic password already exists. It retires the old
   `pikadots-wallpaper.service` (the shell draws the wallpaper now): disabled and its link removed.
   If the pikadots greeter is installed, it is refreshed (see [below](#login-screen-and-boot-splash)).
5. Sets up the apps that follow the wallpaper: the Pywalfox helper for Firefox and Zen, each Zen
   and [Thunderbird](theming.md#thunderbird) profile's `user.js` and `userChrome.css`, the
   [mpv](theming.md#mpv) font file and the VS Code theme. Sets default apps that aren't
   set yet ([desktop.md](desktop.md#default-apps)).
6. Creates `~/Pictures/Screenshots` and `~/Videos/Recordings`, copies the
   [wallpapers](../wallpapers/CREDITS.md) into `~/Pictures/Wallpapers` (existing files are left
   alone) and generates colors from the current one. Inside Hyprland it then reloads Hyprland and
   restarts the shell.

## health and repair

`health` prints a ✓ / ! / ✗ line for: packages (and AUR packages, or on Fedora the downloaded fonts and tools), links, services and the
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

Asks first. Stops the backup timer and disables `pikadots-idle.service`, puts Plasma's own colors,
icons and fonts back into `~/.config/kdeglobals` and its cursor into `~/.config/kcminputrc` (see
[Qt and KDE apps](theming.md#qt-and-kde-apps)), restores the VS Code settings
([theming.md](theming.md#vs-code-and-code---oss)) and unmasks the notification daemons it masked.
It removes the Pywalfox helper manifests it wrote, the `@import` line it put at the top of each Zen
and Thunderbird profile's `userChrome.css`, the `user.js` prefs it added, and the default apps it
set (terminal list, file manager, text editor) if they're still the ones it picked.

If the login screen, the pikadots greeter or the boot splash is in place, it offers
`greeter --reset`, `greeter remove` and `splash --reset` (each asks before using sudo). Then it
removes the links and copies back the files from the oldest folder in
`~/.local/state/pikadots/backups/` (the one from the first install) with `cp -an`, so it never
overwrites a file that's there now. If you keep the pikadots greeter, `~/.local/bin/pikadots`
stays linked so `pikadots greeter remove` keeps working from a text console; it runs from the
repo folder, so keep that until then, and remove the link afterwards. Backups, the keyring and
your git identity stay.

Some things it can't safely undo, so it leaves them: notifier masks, `user.js` prefs and default
apps set by a pikadots older than this (it didn't record them; `systemctl --user unmask
mako.service`, and the `user_pref` lines at the end of `user.js`, undo them by hand), and the
values Zen and Thunderbird already copied from `user.js` into `prefs.js` (they're harmless; reset
them in `about:config` if you like).

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
- **`pikadots greeter install`**: the pikadots greeter, a Quickshell login screen that looks
  like the lock screen (blurred wallpaper, the big clock, your picture, a password field), with a
  session picker (Hyprland, Plasma, …), the keyboard layout and suspend, restart and shut down. It
  installs greetd if needed, copies `config/greeter` to `/usr/share/pikadots-greeter`, your
  wallpaper, colors, fonts, picture and keyboard layout to `/var/lib/pikadots-greeter`, writes
  `/etc/greetd/config.toml` (keeping the old one; the greeter starts through `start-hyprland`, as
  Hyprland 0.57 crashes when greetd starts it directly, with its output sent to the journal so no
  text shows on the console), adds a greetd drop-in
  (`/etc/systemd/system/greetd.service.d/pikadots.conf`) that hides the cursor on the login console
  so the hand-off to your session is plain black, adds GNOME Keyring to `/etc/pam.d/greetd` (keeping
  the old one) so your keyring unlocks with your login password, and switches the display manager to
  greetd, remembering the previous one (also when that was greetd itself). The fonts the theme
  uses (Settings > Fonts & icons, plus Material Symbols in the icon style) are copied to
  `/var/lib/pikadots-greeter/fonts` with a `fonts.conf` next to them; greetd starts the greeter
  with `FONTCONFIG_FILE` pointing at it and `PIKADOTS_GREETER_DIR=/var/lib/pikadots-greeter`, so it
  finds them without the fonts in your home folder. The greetd user is read from the old
  `config.toml` or the greetd package (`greeter`, `greetd` or `_greetd`). It shows from the next
  boot. Run it again after changing the wallpaper. `pikadots install` and `repair` (and so
  `update`) refresh an installed greeter whose files, fonts or greetd command are older than the
  repo's, copying the wallpaper, colors and fonts again; `health` flags one. If a session closes right
  after login, the greeter says so next time instead of looping silently. Why greetd and not a themed Plasma Login Manager:
  [ADR 0001](adr/0001-greetd-quickshell-greeter.md).
- **`pikadots greeter remove`** switches back to the previous display manager, restores
  `config.toml` and removes both folders. With no previous one recorded, it picks an installed
  Plasma Login Manager, SDDM, GDM, LightDM or ly, or keeps greetd with its old `config.toml`; if
  there's none, it says that the next boot ends at a text console. `pikadots uninstall` offers it
  too. It needs nothing but a shell, so it works from a text
  console (Ctrl + Alt + F3) if the greeter ever fails to start.
- **`pikadots greeter preview`** shows the greeter on your screen now, without changing anything;
  Esc closes it.
- **`pikadots splash`**: installs a pikadots Plymouth script theme from `config/plymouth` (the
  wallpaper's base color, the distro logo, an accent spinner and a password prompt for encrypted
  disks) and switches to it with `sudo plymouth-set-default-theme -R`, which rebuilds the
  initramfs. The kernel command line needs `splash`. The previous theme is saved in
  `~/.local/state/pikadots/splash-previous` (and a copy inside the theme folder) for `--reset`.

To go back, run `pikadots greeter --reset` or `pikadots splash --reset`:

- **greeter --reset** (Plasma Login Manager theming) removes the drop-in and the copied wallpaper
  and puts back the login screen's old colors, so it looks exactly as before. It works whichever
  display manager is active, and never touches the pikadots greeter (that's `greeter remove`).
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
packages-fedora.txt  dnf packages; copr.txt: COPR repositories (Fedora)
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
