autoload -U add-zsh-hook
load-nvmrc() {
  # If node is not in the commands list yet, it hasn't been lazy loaded,
  # so don't worry about loading the right version with nvm!
  ! (( ${+commands[node]} )) && return;

  # To increase performance, only run the script if .nvmrc is in the current directory.
  # This means we only change node automatically if cd'ing into the root directory of a repo,
  # and we don't go back to the nvm default, but it decreases delay of cd'ing around elsewhere.
  [ -f .nvmrc ] || return

  local nvmrc_node_version=$(nvm version "$(cat "$(nvm_find_nvmrc)")")

  if [ "$nvmrc_node_version" = "N/A" ]; then
    nvm install
  elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
    nvm use
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

alias pn='pnpm'