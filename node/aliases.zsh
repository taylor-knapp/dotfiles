autoload -U add-zsh-hook
load-nvmrc() {
  # Only act when an .nvmrc exists in the current directory.
  # This means we auto-switch when cd'ing into a repo root, but don't
  # slow down every other cd with nvm lookups.
  [[ -f .nvmrc ]] || return

  # Ensure nvm is loaded (triggers lazy stub on first call, no-op after).
  nvm --version >/dev/null 2>&1 || return

  # We already know .nvmrc is in cwd (guard on line 6), so read it directly
  # instead of calling nvm_find_nvmrc which may not be available.
  local nvmrc_node_version=$(nvm version "$(cat .nvmrc)")

  # Silence nvm output to avoid triggering p10k's instant prompt warning.
  # nvm prints "Now using node vX.Y.Z" which counts as console I/O during init.
  if [ "$nvmrc_node_version" = "N/A" ]; then
    nvm install >/dev/null 2>&1
  elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
    nvm use >/dev/null 2>&1
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

alias pn='pnpm'