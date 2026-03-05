# OMZ is still installed because p10k, z, and kube-ps1 live under ~/.oh-my-zsh/.
# However, oh-my-zsh.sh is NOT sourced at startup — we load those plugins directly.
# See zsh/oh-my-zsh.zsh for details.

# Remove existing oh-my-zsh installation.
rm -rf $ZSH

# Install oh-my-zsh. Do not replace the existing .zshrc file. Do not start zsh after the install.
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended

ZSH_CUSTOM=$ZSH/custom

# Setup powerlevel10k theme.
# https://github.com/romkatv/powerlevel10k/#meslo-nerd-font-patched-for-powerlevel10k
rm -rf $ZSH_CUSTOM/themes/powerlevel10k
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Install zsh-defer — lets us defer non-critical source commands so they run
# after the prompt is drawn, keeping interactive startup fast.
# https://github.com/romkatv/zsh-defer
ZSH_DEFER_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-defer"
rm -rf "$ZSH_DEFER_DIR"
git clone https://github.com/romkatv/zsh-defer.git "$ZSH_DEFER_DIR"

# Install syntax highlighting support.
brew install zsh-syntax-highlighting

# Install ripgrep.
# https://github.com/BurntSushi/ripgrep
brew install ripgrep
