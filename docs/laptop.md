# Laptop, power and apps

[← README](../README.md)

## Idle

| After | |
|---|---|
| 5 min | Dim |
| 10 min | Lock |
| 11 min | Screen off |
| 30 min | Suspend |

Keep awake (quick settings) holds this off. Times are in `hypr/.config/hypr/hypridle.conf`.

## Power

- **Power mode** in the battery panel: power saver, balanced, performance.
- **Night light** in quick settings.
- **Lid**: with an external monitor, closing the lid turns the laptop screen off instead of
  suspending.

## ASUS ROG

With `asusctl` (installed automatically on ASUS laptops):

- **Charge limit** of 80%, with "charge to 100% once" for travel.
- **GPU mode** (Ultimate, Hybrid, Eco) in the battery panel, applied after a restart.
- **Keyboard lighting** in the wallpaper's accent color.

## Background apps

- **Tray apps** (OneDrive, Remmina) start after the tray is ready, so closing them hides them to
  the tray. Started from `hypr/scripts/tray-apps.sh`.
- **Thunderbird and Chrome apps** (Teams, WhatsApp) have no tray, so Super + Q hides them instead
  of closing them. They appear in the tray pill; right click quits. The list is in
  `hypr/background.lua`.

## VPN

VPNs are NetworkManager connections, toggled in the network panel. To import OpenVPN:

```sh
nmcli connection import type openvpn file client.ovpn
nmcli connection modify <name> connection.id "Office VPN" +vpn.data username=<user>
```

The first connect asks for the password and saves it.
