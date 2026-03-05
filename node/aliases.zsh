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

  if [ "$nvmrc_node_version" = "N/A" ]; then
    nvm install
  elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
    nvm use
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

alias pn='pnpm'