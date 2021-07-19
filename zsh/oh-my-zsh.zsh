# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="powerlevel10k/powerlevel10k"

HIST_STAMPS="mm-dd-yyyy"

# This speeds up initial zsh load time by lazy loading nvm whenever node, npm, or nvm is first used.
NVM_LAZY=true

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git npm nvm z)

source $ZSH/oh-my-zsh.sh

#PROMPT='%{$fg[cyan]%}%30<...<%~%<<%{$reset_color%} $(git_prompt_info)'
#PROMPT+='
#%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$reset_color%}'
#
#RPROMPT='%{$fg[yellow]%}[%D{%f/%m/%y} %D{%L:%M:%S}]'