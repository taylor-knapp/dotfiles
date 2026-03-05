# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# Terraform autocomplete — deferred because bashcompinit is expensive (~30ms)
# and terraform completion is only needed when typing `terraform <tab>`.
# bashcompinit adds bash-style `complete` support to zsh's completion system.
zsh-defer -c 'autoload -U +X bashcompinit && bashcompinit && complete -o nospace -C /opt/homebrew/bin/terraform terraform'
