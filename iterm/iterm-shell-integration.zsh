# iTerm2 shell integration — adds marks, badges, and imgcat support.
# Deferred with zsh-defer because it's cosmetic and not needed before
# the first prompt is drawn.
# https://iterm2.com/documentation-shell-integration.html
if [[ -f $HOME/.iterm2_shell_integration.zsh ]]; then
  zsh-defer source $HOME/.iterm2_shell_integration.zsh
fi
