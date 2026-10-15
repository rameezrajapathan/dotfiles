#!/usr/bin/env bash
# USB drives, SD cards and disk images through udisks (no root: polkit allows it for the active
# session). Used by the shell's Drives panel (quickshell/Drives.qml).
#   drives.sh mount DEVICE [--notify] [--open]   mount; --notify offers Open / Eject afterwards,
#                                               --open shows it in the file manager
#   drives.sh offer DEVICE                      notification with a Mount button (automount off)
#   drives.sh unlock DEVICE [--open]            ask for the passphrase, unlock and mount
#   drives.sh eject DISK                        unmount (and lock) everything on DISK, then power
#                                               it off, or detach it for a disk image
set -uo pipefail

app=~/.config/hypr/scripts/app.sh
icon=drive-removable-media

# udisks errors end with the useful part: "...UDisks2.Error.DeviceBusy: Error unmounting: target is busy"
error_text() {
	sed -E 's/^.*UDisks2\.Error\.[A-Za-z]+: //; s/^GDBus\.Error:[^ ]+ //' <<<"$1" | head -3
}

fail() {
	notify-send -a Drives -i "$icon" -u critical "$1" "$(error_text "$2")"
	exit 1
}

name_of() {
	local label
	label=$(lsblk -ndo LABEL "$1" 2>/dev/null)
	[[ -n $label ]] || label=$(lsblk -ndo MODEL "$(disk_of "$1")" 2>/dev/null | sed 's/ *$//')
	echo "${label:-$(lsblk -ndo SIZE "$1") drive}"
}

# The whole disk a partition (or an unlocked volume on it) belongs to
disk_of() {
	local dev=$1 parent
	while parent=$(lsblk -ndo PKNAME -p "$dev" 2>/dev/null | head -1) && [[ -n $parent ]]; do
		dev=$parent
	done
	echo "$dev"
}

mountpoint_of() {
	lsblk -no MOUNTPOINT "$1" 2>/dev/null | sed '/^$/d' | head -1
}

mount_dev() {
	local dev=$1 notify=$2 open=$3 out mp name
	name=$(name_of "$dev")
	mp=$(mountpoint_of "$dev")
	if [[ -z $mp ]]; then
		out=$(udisksctl mount -b "$dev" --no-user-interaction 2>&1) || fail "Couldn't open $name" "$out"
		mp=$(sed -nE 's/^Mounted .* at (.*)$/\1/p' <<<"$out")
		mp=${mp%.}
	fi
	[[ $open == 1 ]] && "$app" files "$mp"
	if [[ $notify == 1 ]]; then
		case $(notify-send -a Drives -i "$icon" -A open=Open -A eject=Eject "$name connected" "${mp/#$HOME/\~}") in
		open) "$app" files "$mp" ;;
		eject) eject "$(disk_of "$dev")" ;;
		esac
	fi
}

offer() {
	local dev=$1
	if [[ $(notify-send -a Drives -i "$icon" -A mount=Open "$(name_of "$dev") connected" "Not opened yet") == mount ]]; then
		mount_dev "$dev" 0 1
	fi
}

unlock() {
	local dev=$1 open=$2 name pass out unlocked
	name=$(name_of "$dev")
	pass=$(zenity --password --title="Unlock $name") || exit 0
	out=$(printf '%s' "$pass" | udisksctl unlock -b "$dev" --key-file /dev/stdin --no-user-interaction 2>&1) ||
		fail "Couldn't unlock $name" "$out"
	unlocked=$(sed -nE 's/^Unlocked .* as (.*)\.$/\1/p' <<<"$out")
	[[ -n $unlocked ]] && mount_dev "$unlocked" 0 "$open"
}

eject() {
	local disk=$1 name type path pkname mounted out
	name=$(name_of "$disk")
	# Children first: unmount filesystems, then lock the encrypted partitions they were on
	while IFS='|' read -r type path pkname mounted; do
		if [[ $mounted -gt 0 ]]; then
			out=$(udisksctl unmount -b "$path" --no-user-interaction 2>&1) || fail "Couldn't eject $name" "$out"
		fi
		if [[ $type == crypt && -n $pkname ]]; then
			out=$(udisksctl lock -b "$pkname" --no-user-interaction 2>&1) || fail "Couldn't eject $name" "$out"
		fi
	done < <(lsblk -J -p -o PATH,TYPE,PKNAME,MOUNTPOINTS "$disk" | jq -r '
		[.blockdevices[] | recurse(.children[]?)] | reverse | .[]
		| "\(.type)|\(.path)|\(.pkname // "")|\((.mountpoints // []) | map(select(. != null)) | length)"')
	if [[ $(lsblk -ndo TYPE "$disk") == loop ]]; then
		out=$(udisksctl loop-delete -b "$disk" --no-user-interaction 2>&1) || fail "Couldn't eject $name" "$out"
	else
		# Some card readers can't be powered off; unmounted is safe to remove too
		udisksctl power-off -b "$disk" --no-user-interaction >/dev/null 2>&1 || true
	fi
	notify-send -a Drives -i "$icon" "$name can be removed" "It's safe to unplug it now."
}

cmd=${1:-}
dev=${2:-}
[[ -n $cmd && -b $dev ]] || {
	sed -n '2,10s/^# \{0,1\}//p' "$0" >&2
	exit 2
}
shift 2
notify=0 open=0
for arg; do
	case $arg in
	--notify) notify=1 ;;
	--open) open=1 ;;
	esac
done

case $cmd in
mount) mount_dev "$dev" "$notify" "$open" ;;
offer) offer "$dev" ;;
unlock) unlock "$dev" "$open" ;;
eject) eject "$dev" ;;
*) exit 2 ;;
esac
