# The Greeter runs on greetd with Quickshell, not Plasma Login Manager

The Greeter should look exactly like the lock screen. Plasma Login Manager can only be themed through Plasma's own QML theme system, which can't load the shell's Quickshell code, so a themed Plasma Login Manager would at best be a near copy that drifts out of step. Instead, greetd starts a small Hyprland session that runs a Quickshell greeter, reusing the lock screen's look. greetd can't read the user's home folder, so `pikadots greeter install` copies the wallpaper, colors and fonts into `/var/lib/pikadots-greeter`, and `pikadots greeter remove` switches the display manager back to Plasma Login Manager.

## Considered Options

- Theme Plasma Login Manager to roughly match: no new packages, but it's a second codebase that never quite matches.
- Autologin into the lock screen: no greeter at all, but there's no session choice and it shares a single account.

## Consequences

The KDE session remains available from the Greeter's session picker. A broken greeter means a broken login, so `pikadots greeter remove` must work from a TTY.
