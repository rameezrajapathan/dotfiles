# Laptop, power and apps

[← README](../README.md)

## Idle

| After | |
|---|---|
| 5 min | Dim |
| 10 min | Lock |
| 11 min | Screen off |
| 30 min | Suspend |

These are the defaults; change them in Settings > Power (`hypr/scripts/idle.sh` writes the hypridle
config from your choices at login). Keep awake (Account tab or the Power page) holds this off.

## Power

- **Power mode** in the Battery tab: power saver, balanced, performance. [Game mode](desktop.md#game-mode)
  switches to performance while it's on.
- **Night light** from the Account tab, or on a schedule in Settings > Displays: sunset to sunrise
  where Weather says you are, or your own times.
- **Lid**: with an external monitor, closing the lid turns the laptop screen off instead of
  suspending. Arrange the screens from the [Displays tab](desktop.md#displays).

## ASUS ROG

With `asusctl` (installed automatically on ASUS laptops):

- **Charge limit** of 80%, with "charge to 100% once" for travel.
- **GPU mode** (Ultimate, Hybrid, Eco) in the Battery tab, applied after a restart.
- **Keyboard lighting** in the wallpaper's accent color.

## Background apps

- **Tray apps** (OneDrive, Remmina) start after the tray is ready, so closing them hides them to
  the tray. Started from `hypr/scripts/tray-apps.sh`.
- **Thunderbird and Chrome apps** (Teams, WhatsApp) have no tray, so Super + Q hides them instead
  of closing them. They appear in the tray pill; right click quits. The list is in
  `hypr/background.lua`.
