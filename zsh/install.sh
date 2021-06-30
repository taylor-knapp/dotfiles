# clone spaceship theme and setup symlink
# https://spaceship-prompt.sh/
rm -rf "$ZSH/custom/themes/spaceship-prompt"
rm "$ZSH/themes/spaceship.zsh-theme"
git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH/custom/themes/spaceship-prompt" --depth=1
ln -s "$ZSH/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH/themes/spaceship.zsh-theme"

# if you have weird symbols on iterm, you need to enable the powerline fonts
# https://apple.stackexchange.com/a/413332

# todo: turn off symbol for stashed changes... I usually always have something in stash so it's meaningless

:'

Spaceship Info

Currently it shows:

Clever hostname and username displaying.
Prompt character turns red if the last command exits with non-zero code.
Current Git branch and rich repo status:
  ? — untracked changes;
  + — uncommitted changes in the index;
  ! — unstaged changes;
  » — renamed files;
  ✘ — deleted files;
  $ — stashed changes;
  = — unmerged changes;
  ⇡ — ahead of remote branch;
  ⇣ — behind of remote branch;
  ⇕ — diverged chages.
  Current Mercurial branch and rich repo status:
  ? — untracked changes;
  + — uncommitted changes in the index;
  ! — unstaged changes;
  ✘ — deleted files;
Indicator for jobs in the background (✦).
Current Node.js version, through nvm/nodenv/n (⬢).
Current Ruby version, through rvm/rbenv/chruby (💎).
Current Elixir version, through kiex/exenv/elixir (💧).
Current Swift version, through swiftenv (🐦).
Current Xcode version, through xenv (🛠).
Current Go version (🐹).
Current PHP version (🐘).
Current Rust version (𝗥).
Current version of Haskell Tool Stack (λ).
Current Julia version (ஃ).
Current Docker version and connected machine (🐳).
Current Amazon Web Services (AWS) profile (☁️) (Using named profiles).
Current Python virtualenv.
Current Conda virtualenv (🅒).
Current Python pyenv (🐍).
Current .NET SDK version, through dotnet-cli (.NET).
Current Ember.js version, through ember-cli (🐹).
Current Kubectl context (☸️).
Package version, if there is a package in the current directory (📦).
Current battery level and status:
⇡ - charging;
⇣ - discharging;
• - fully charged.
Current Vi-mode mode (with handy aliases for temporarily enabling).
Optional exit-code of the last command.
Optional time stamps 12/24hr in format.
Execution time of the last command if it exceeds the set threshold.
'