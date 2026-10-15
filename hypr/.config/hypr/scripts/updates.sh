#!/usr/bin/env bash
# Checks for updates and prints one JSON object for the shell (Updates.qml):
#   pikadots: the dotfiles repo — commit, behind/ahead of its remote, incoming commits, local changes
#   system:   pacman (checkupdates, no root needed), AUR (yay/paru -Qua) and Flatpak updates
# `updates.sh repo` skips the system part.
set -uo pipefail

self=$(readlink -f ~/.local/bin/pikadots 2>/dev/null || true)
repo=${PIKADOTS_DIR:-$([ -n "$self" ] && cd "$(dirname "$self")/../../.." && pwd)}

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
	local pacman="[]" aur="[]" flatpak="[]" helper
	command -v checkupdates >/dev/null && pacman=$(timeout 120 checkupdates 2>/dev/null | lines_json)
	helper=$(command -v paru || command -v yay || true)
	[ -n "$helper" ] && aur=$(timeout 120 "$helper" -Qua 2>/dev/null | lines_json)
	command -v flatpak >/dev/null && flatpak=$(timeout 60 flatpak remote-ls --updates --columns=application,version 2>/dev/null | lines_json)
	jq -n --argjson pacman "$pacman" --argjson aur "$aur" --argjson flatpak "$flatpak" \
		--arg helper "$(basename "${helper:-}")" \
		'{pacman: $pacman, aur: $aur, flatpak: $flatpak, helper: $helper}'
}

if [ "${1:-}" = repo ]; then
	jq -n --argjson repo "$(repo_json)" '{pikadots: $repo, system: null, checked: now}'
else
	jq -n --argjson repo "$(repo_json)" --argjson sys "$(system_json)" '{pikadots: $repo, system: $sys, checked: now}'
fi
