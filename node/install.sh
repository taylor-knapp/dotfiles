export NVM_DIR="$HOME/.nvm"
# clone if it doesn't exist
git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
cd "$NVM_DIR"
# fetch latest to ensure we're up to date if it exists already
git fetch --tags origin
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

# source nvm to finish loading
[ -s $NVM_DIR/nvm.sh ] && source $NVM_DIR/nvm.sh  # This loads nvm
[ -s $NVM_DIR/bash_completion ] && source $NVM_DIR/bash_completion  # This loads nvm bash_completion