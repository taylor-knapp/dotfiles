# Install rvm.

# GPG keys will confirm rvm package integrity.
brew install gnupg gnupg2
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -

# Download rvm and setup with rails. Do not add any initialization to dotfiles.
curl -sSL https://get.rvm.io | bash -s stable --rails --ignore-dotfiles