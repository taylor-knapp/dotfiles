# This loads string replacement for the current prompt text.
# Press alt+r to invoke and alt+g to repeat the last substitution.
# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#index-replace_002dstring
autoload replace-string
zle -N replace-string
zle -N replace-string-again
bindkey '\eg' replace-string-again
bindkey '\er' replace-string