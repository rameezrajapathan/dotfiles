[[ $- == *i* ]] || return 0
[[ :$PATH: == *":$HOME/.local/bin:"* ]] || PATH=$HOME/.local/bin:$PATH

[[ -f ~/.local/state/theme/starship.toml ]] && export STARSHIP_CONFIG=~/.local/state/theme/starship.toml
command -v starship >/dev/null && eval "$(starship init bash)"

[[ -f ~/.local/state/theme/eza-colors ]] && export EZA_COLORS=$(<~/.local/state/theme/eza-colors)
if command -v eza >/dev/null; then
	alias ls='eza --icons=auto'
	alias ll='eza -lah --icons=auto --git'
	alias la='eza -a --icons=auto'
	alias lt='eza --tree --icons=auto'
fi

HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

[[ -f ~/.local/state/theme/lazygit.yml ]] && export LG_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml,$HOME/.local/state/theme/lazygit.yml"

command -v zoxide >/dev/null && eval "$(zoxide init bash --cmd cd)"
command -v mise >/dev/null && eval "$(mise activate bash)"

_pikadots_starship=$(command -v starship) _pikadots_mise=$(command -v mise) _pikadots_zoxide=$(command -v zoxide)
_pikadots_unhook() {
	local status=$?
	if [[ -n $_pikadots_starship && ! -x $_pikadots_starship ]]; then
		_pikadots_starship=
		starship_precmd() { eval "${STARSHIP_PROMPT_COMMAND-}"; }
		starship_preexec() { :; }
		starship_preexec_all() { :; }
		PS0= PS1='\u@\h:\w\$ ' PS2='> '
	fi
	if [[ -n $_pikadots_mise && ! -x $_pikadots_mise ]]; then
		_pikadots_mise=
		_mise_hook() { :; }
		_mise_hook_prompt_command() { :; }
		_mise_hook_chpwd() { :; }
	fi
	if [[ -n $_pikadots_zoxide && ! -x $_pikadots_zoxide ]]; then
		_pikadots_zoxide=
		__zoxide_hook() { :; }
		__zoxide_z() { builtin cd "$@"; }
		__zoxide_zi() { builtin cd "$@"; }
	fi
	return $status
}
if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
	PROMPT_COMMAND=(_pikadots_unhook "${PROMPT_COMMAND[@]}")
else
	PROMPT_COMMAND="_pikadots_unhook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

if [[ -n $FASTFETCH ]]; then
	unset FASTFETCH
	fastfetch
fi
