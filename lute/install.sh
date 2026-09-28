#!/bin/sh
#
# Install Lute v3 into a venv beside this script.
# https://luteorg.github.io/lute-manual/install/install.html

set -e
DIR="$(dirname "$0")"
[ -d "$DIR/.venv" ] || python3 -m venv "$DIR/.venv"
"$DIR/.venv/bin/pip" install --quiet --upgrade pip lute3
