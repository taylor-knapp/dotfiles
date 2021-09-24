# Set the skdman directory.
# This is the default, but the path is used elsewhere so force it to ensure it never varies.
SDKMAN_DIR="$HOME/.sdkman"

# Install sdkman, or update if it already is installed.
if [ ! -d $SDKMAN_DIR ]; then
  curl -s "https://get.sdkman.io?rcupdate=false" | bash
fi