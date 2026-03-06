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
- **zsh/** - Primary shell. Powerlevel10k, lazy NVM, zsh-defer, completions, aliases
- **bash/** - Bash profile and rc (symlinked)
- **system/** - System-wide aliases, env vars, keyboard config, macOS Automator workflows
- **functions/** - Shell functions and completions (`extract`, `c`, etc.)
- **bin/** - Utility scripts added to `$PATH` (git helpers, `e`, `dns-flush`, `set-defaults`, etc.)

### Languages & Runtimes
- **node/** - Node.js aliases and install
- **python/** - PATH config
- **ruby/** - gemrc, irbrc
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
- **magnet/** - Window layout overrides and install
- **renovate/** - Local config

### System
- **macos/** - macOS defaults and install
- **script/** - Bootstrap and install entry points

## Notes

- **Oh My Zsh is NOT sourced at startup.** OMZ is still installed (for p10k, z, and kube-ps1 which live under `~/.oh-my-zsh/`) but `oh-my-zsh.sh` is never loaded. Instead, `zsh/oh-my-zsh.zsh` sources only what we need directly.
- **NVM is lazy-loaded.** Stub functions for `nvm`, `node`, `npm`, `npx`, `yarn`, `pnpx`, and `corepack` defer sourcing `nvm.sh` until first use.
- **zsh-defer** defers non-critical sources (syntax highlighting, gcloud completion, iterm integration, terraform) until after the first prompt is drawn.
- **kube-ps1 is on-demand.** Type `kube-on` to load Kubernetes context into your prompt.
- **Profiling:** Run `ZPROF=1 zsh -i -c exit` to see a startup timing breakdown.
- **Homebrew shellenv is cached** in `zsh/zprofile.symlink` for faster startup. If Homebrew is reinstalled or moved, re-run `/opt/homebrew/bin/brew shellenv` and update that file.

## Install

```sh
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

Forked from [holman/dotfiles](https://github.com/holman/dotfiles).
