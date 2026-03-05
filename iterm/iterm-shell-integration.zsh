# iTerm2 shell integration — adds marks, badges, and imgcat support.
# Deferred with zsh-defer (if available) because it's cosmetic and not needed
# before the first prompt is drawn. Falls back to eager loading if zsh-defer
# hasn't been sourced yet (e.g. during install before zsh-defer is cloned).
# https://iterm2.com/documentation-shell-integration.html
if [[ -f $HOME/.iterm2_shell_integration.zsh ]]; then
  if (( $+functions[zsh-defer] )); then
    zsh-defer source $HOME/.iterm2_shell_integration.zsh
  else
    source $HOME/.iterm2_shell_integration.zsh
  fi
fi
