let theme = ($env.HOME | path join .local/state/theme)

$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.HOME | path join .local/bin) | uniq)
$env.config.show_banner = false

if ($theme | path join starship.toml | path exists) {
    $env.STARSHIP_CONFIG = ($theme | path join starship.toml)
}
if ($theme | path join eza-colors | path exists) {
    $env.EZA_COLORS = (open --raw ($theme | path join eza-colors) | str trim)
}
if ($theme | path join lazygit.yml | path exists) {
    $env.LG_CONFIG_FILE = ($env.HOME | path join .config/lazygit/config.yml) + "," + ($theme | path join lazygit.yml)
}

alias ll = eza -lah --icons=auto --git
alias la = eza -a --icons=auto
alias lt = eza --tree --icons=auto

if ($env.FASTFETCH? | is-not-empty) {
    hide-env FASTFETCH
    fastfetch
}
