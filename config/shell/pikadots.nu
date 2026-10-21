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

let pikadots_tools = [starship mise zoxide] | each {|tool|
    {tool: $tool, path: ($env.PATH | each {|dir| $dir | path join $tool } | where {|p| ($p | path type) == file } | get 0? | default "")}
} | transpose -rd
$env.config.hooks.pre_prompt = ($env.config.hooks.pre_prompt? | default [] | prepend {||
    let gone = ($pikadots_tools | transpose tool path | where {|t| ($t.path | is-not-empty) and not ($t.path | path exists) } | get tool)
    if "starship" in $gone {
        hide-env -i PROMPT_COMMAND PROMPT_COMMAND_RIGHT PROMPT_INDICATOR PROMPT_MULTILINE_INDICATOR
    }
    if "mise" in $gone {
        hide-env -i MISE_SHELL
    }
    if "zoxide" in $gone {
        $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD? | default [] | where {|h| not (($h | describe) starts-with "record" and "__zoxide_hook" in $h) })
    }
})

if ($env.FASTFETCH? | is-not-empty) {
    hide-env FASTFETCH
    fastfetch
}
