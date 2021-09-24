if test ! "$(uname)" = "Darwin"
  then
  exit 0
fi

# The Brewfile handles Homebrew-based app and library installs, but there may
# still be updates and installables in the Mac App Store. There's a nifty
# command line interface to it that we can use to just install everything, but
# often errors out so we use this as an opportunity to remind ourselves to install them!

echo "› softwareupdate -l"
softwareupdate -l