echo 'loading oh-my-zsh'

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

HIST_STAMPS="mm-dd-yyyy"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git npm)

source $ZSH/oh-my-zsh.sh

source $ZSH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

PROMPT='%{$fg[cyan]%}%30<...<%~%<<%{$reset_color%} $(git_prompt_info)'
PROMPT+='
%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$reset_color%}'

RPROMPT='%{$fg[yellow]%}[%D{%f/%m/%y} %D{%L:%M:%S}]'