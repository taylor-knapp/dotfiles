#!/bin/sh
#
# Install bun 

if ! command -v bun >/dev/null 2>&1; then
  # https://bun.com/
  curl -fsSL https://bun.sh/install | bash
fi

