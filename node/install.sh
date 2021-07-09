# Install nvm.

export NVM_DIR="$HOME/.nvm"

# Clone nvm if it is not present.
if [ ! -d $NVM_DIR ]; then
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR";
fi;

cd "$NVM_DIR"

# Fetch latest release to ensure it is up to date.
git fetch --tags origin

# Checkout the latest release. When the nvm oh-my-zsh plugin sources $NVM_DIR/nvm.sh this commit will be used.
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`