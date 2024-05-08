#!/bin/sh
#
# Postgres utility installation.
#
if test ! "$(which psql > /dev/null)"
then
  echo "  Installing postgres tools for you."

  brew doctor
  brew update
  brew install libpq
fi