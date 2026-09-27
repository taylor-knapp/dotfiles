# TODO: install pyenv via homebrew during init; and set pyenv global for python and python2
#  this is how we get python2 easily accessible on macos M1
# Use PYENV_ROOT (default ~/.pyenv) instead of `$(pyenv root)` to avoid a subshell
# at startup and to stay silent when pyenv isn't installed.
[[ -d "${PYENV_ROOT:-$HOME/.pyenv}/shims" ]] && PATH="${PATH}:${PYENV_ROOT:-$HOME/.pyenv}/shims"
