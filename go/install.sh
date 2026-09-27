#!/bin/sh
#
# go
#
# Installs the Go toolchain. `go/path.zsh` puts $HOME/go/bin on $PATH
# so binaries from `go install` are available.

if command -v brew >/dev/null 2>&1; then
  brew list go >/dev/null 2>&1 || brew install go
else
  echo "  Install go manually: https://go.dev/dl/"
fi
