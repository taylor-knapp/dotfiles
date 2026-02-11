# dotfiles

## Quick Reference

- `reload!` - reload shell configuration after changes
- `.dotfiles` - run full install (new machine setup)
- `script/bootstrap` - symlink dotfiles and run installers

## How It Works

Everything is organized into **topic directories**. Special file conventions:

| Pattern | Behavior |
|---|---|
| `topic/*.zsh` | Automatically sourced into your shell |
| `topic/path.zsh` | Loaded first; sets up `$PATH` |
| `topic/completion.zsh` | Loaded last; sets up autocomplete |
| `topic/install.sh` | Runs during `script/install` |
| `topic/*.symlink` | Symlinked into `$HOME` (without `.symlink` extension) |
| `bin/*` | Added to `$PATH` globally |

## Structure

### Shell
- **zsh/** - Primary shell. Oh My Zsh, Powerlevel10k, completions, aliases
- **bash/** - Bash profile and rc (symlinked)
- **system/** - System-wide aliases, env vars, keyboard config, macOS Automator workflows
- **functions/** - Shell functions and completions (`extract`, `c`, etc.)
- **bin/** - Utility scripts added to `$PATH` (git helpers, `e`, `dns-flush`, `set-defaults`, etc.)

### Languages & Runtimes
- **node/** - Node.js aliases and install
- **python/** - PATH config
- **ruby/** - gemrc, irbrc, RVM setup
- **java/** - SDKMAN config and install
- **go/** - PATH config
- **rust/** - Cargo bin PATH config

### Tools
- **git/** - Aliases, gitconfig, global gitignore, commit template
- **docker/** - Aliases
- **k8s/** - Kubernetes aliases, install, PATH
- **postgres/** - Install and PATH
- **mongo/** - Install
- **homebrew/** - Install script

### Editors & IDEs
- **vim/** - vimrc (symlinked)
- **vscode/** - PATH config
- **jetbrains/** - Launcher scripts for IntelliJ, DataGrip, WebStorm
- **xcode/** - Aliases

### Applications
- **claude/** - Claude CLI aliases and PATH
- **commercetools/** - API/CLI aliases
- **obsidian/** - Aliases
- **iterm/** - Shell integration
- **rancher/** - Rancher Desktop install and PATH
- **renovate/** - Local config

### System
- **macos/** - macOS defaults and install
- **script/** - Bootstrap and install entry points

## Install

```sh
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

Forked from [holman/dotfiles](https://github.com/holman/dotfiles).
