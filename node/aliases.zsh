# fnm — fast Node version manager
# Init without --use-on-cd; we provide our own chpwd hook that
# only invokes fnm when an .nvmrc is present.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --shell zsh)"

  autoload -U add-zsh-hook
  _fnm_autoswitch() {
    [[ -f .nvmrc ]] || return
    fnm use --silent-if-unchanged
  }
  add-zsh-hook chpwd _fnm_autoswitch
  # Startup call silenced: it runs before the first prompt, so any
  # "Using Node vX" output trips Powerlevel10k's instant-prompt warning.
  _fnm_autoswitch >/dev/null 2>&1
fi

alias pn='pnpm'
