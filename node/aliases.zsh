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
  _fnm_autoswitch
fi

alias pn='pnpm'
