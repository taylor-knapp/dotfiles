# Remove existing oh-my-zsh installation.
rm -rf $ZSH

# Install oh-my-zsh. Do not replace the existing .zshrc file. Do not start zsh after the install.
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

# Install syntax highlighting support.
brew install zsh-syntax-highlighting