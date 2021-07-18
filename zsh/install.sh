# Remove existing oh-my-zsh installation.
rm -rf $ZSH

# Install oh-my-zsh. Do not replace the existing .zshrc file. Do not start zsh after the install.
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

# Fix slow pasting with this odd trick.
# https://www.reddit.com/r/zsh/comments/bj6rwz/what_is_a_good_ohmyzsh_alternative/em7l131?utm_source=share&utm_medium=web2x&context=3
mkdir -p $ZSH_CUSTOM/lib && touch $ZSH_CUSTOM/lib/misc.zsh

# Install syntax highlighting support.
brew install zsh-syntax-highlighting

# Install ripgrep.
# https://github.com/BurntSushi/ripgrep
brew install ripgrep