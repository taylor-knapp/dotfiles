export NVM_DIR="$HOME/.nvm"

# clone if it doesn't exist
if [ ! -d $NVM_DIR ]; then
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR";
fi;

cd "$NVM_DIR"

# fetch latest to ensure we're up to date
git fetch --tags origin

# checkout latest release
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

# source nvm to finish loading
[ -s $NVM_DIR/nvm.sh ] && source $NVM_DIR/nvm.sh  # This loads nvm
[ -s $NVM_DIR/bash_completion ] && source $NVM_DIR/bash_completion  # This loads nvm bash_completion