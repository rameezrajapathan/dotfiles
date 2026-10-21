#!/usr/bin/env bash
set -uo pipefail

self=$(readlink -f ~/.local/bin/pikadots 2>/dev/null || true)
repo=${PIKADOTS_DIR:-$([ -n "$self" ] && git -C "$(dirname "$self")" rev-parse --show-toplevel 2>/dev/null)}

lines_json() { jq -R . | jq -s .; }

repo_json() {
	if [ -z "$repo" ] || ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
		jq -n '{error: "pikadots repository not found"}'
		return
	fi
	local error="" behind=0 ahead=0 incoming="[]"
	if git -C "$repo" rev-parse '@{u}' >/dev/null 2>&1; then
		timeout 30 git -C "$repo" fetch --quiet 2>/dev/null || error="Couldn't reach the remote"
		behind=$(git -C "$repo" rev-list --count 'HEAD..@{u}')
		ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD')
		incoming=$(git -C "$repo" log --format='%h %s' 'HEAD..@{u}' | head -30 | lines_json)
	else
		error="No remote set"
	fi
	jq -n --arg path "$repo" --arg commit "$(git -C "$repo" rev-parse --short HEAD)" \
		--arg subject "$(git -C "$repo" log -1 --format=%s)" \
		--arg date "$(git -C "$repo" log -1 --format=%cr)" \
		--arg branch "$(git -C "$repo" rev-parse --abbrev-ref HEAD)" \
		--argjson behind "$behind" --argjson ahead "$ahead" \
		--argjson dirty "$(git -C "$repo" status --porcelain | wc -l)" \
		--argjson incoming "$incoming" --arg error "$error" \
		'{path: $path, commit: $commit, subject: $subject, date: $date, branch: $branch,
		  behind: $behind, ahead: $ahead, dirty: $dirty, incoming: $incoming, error: $error}'
}

system_json() {
	local packages="[]" aur="[]" flatpak="[]" helper="" manager=Arch log=/var/log/pacman.log
	if command -v pacman >/dev/null; then
		command -v checkupdates >/dev/null && packages=$(timeout 120 checkupdates 2>/dev/null | lines_json)
		helper=$(command -v paru || command -v yay || true)
		[ -n "$helper" ] && aur=$(timeout 120 "$helper" -Qua 2>/dev/null | lines_json)
	elif command -v dnf >/dev/null; then
		manager=Fedora log=/var/log/dnf5.log
		packages=$(timeout 180 dnf -q check-upgrade 2>/dev/null | awk 'NF == 3 && $1 ~ /\./ { sub(/\.[^.]+$/, "", $1); print $1 " " $2 }' | lines_json)
	fi
	command -v flatpak >/dev/null && flatpak=$(timeout 60 flatpak remote-ls --updates --columns=application,version 2>/dev/null | lines_json)
	jq -n --argjson packages "$packages" --argjson aur "$aur" --argjson flatpak "$flatpak" \
		--arg helper "$(basename "${helper:-}")" --arg manager "$manager" --arg log "$log" \
		'{packages: $packages, aur: $aur, flatpak: $flatpak, helper: $helper, manager: $manager, log: $log}'
}

if [ "${1:-}" = repo ]; then
	jq -n --argjson repo "$(repo_json)" '{pikadots: $repo, system: null, checked: now}'
else
	jq -n --argjson repo "$(repo_json)" --argjson sys "$(system_json)" '{pikadots: $repo, system: $sys, checked: now}'
fi
