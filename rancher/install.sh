#!/bin/sh
#
# Rancher Desktop installation.
#
if test ! "$(which rd > /dev/null)"
then
  echo "  Installing Rancher Desktop for you."

  brew install rancher
fi