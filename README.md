# dotfiles

## Quick Reference

- `reload!` - reload shell configuration after changes
- `.dotfiles` - run full install (new machine setup)
- `script/bootstrap` - symlink dotfiles and run installers

## How It Works

Everything is organized into topic directories. The file names control how each file is used:

| Pattern                | Behavior                                              |
| ---------------------- | ----------------------------------------------------- |
| `topic/*.zsh`          | Automatically sourced into your shell                 |
| `topic/path.zsh`       | Loaded first. Sets up `$PATH`                         |
| `topic/completion.zsh` | Loaded last. Sets up autocomplete                     |
| `topic/install.sh`     | Runs during `script/install`                          |
| `topic/*.symlink`      | Symlinked into `$HOME` (without `.symlink` extension) |
| `bin/*`                | Added to `$PATH` globally                             |

## Structure

### Shell

- `zsh/` - Primary shell. Powerlevel10k, zsh-defer, completions, aliases
- `bash/` - Bash profile and rc (symlinked)
- `system/` - System-wide aliases, env vars, keyboard configuration, macOS Automator workflows
- `functions/` - Shell functions and completions (for example `extract` and `c`)
- `bin/` - Utility scripts added to `$PATH` (for example git helpers, `e`, `dns-flush`, and `set-defaults`)

### Languages & Runtimes

- `node/` - Node.js aliases and install
- `python/` - PATH configuration
- `ruby/` - gemrc, irbrc
- `java/` - SDKMAN configuration and install
- `go/` - PATH configuration
- `rust/` - Cargo bin PATH configuration

### Tools

- `git/` - Aliases, gitconfig, global gitignore, commit template
- `docker/` - Aliases
- `k8s/` - Kubernetes aliases, install, PATH
- `postgres/` - Install and PATH
- `mongo/` - Install
- `tmux/` - Terminal multiplexer with easy-motion, thumbs, Catppuccin theme
- `homebrew/` - Install script

### Editors & IDEs

- `vim/` - vimrc (symlinked)
- `neovim/` - Neovim install (`brew install neovim`, ripgrep, and tree-sitter-cli) and the full setup in `neovim/config`, symlinked to `~/.config/nvim`
- `vscode/` - PATH configuration
- `jetbrains/` - Launcher scripts for IntelliJ, DataGrip, WebStorm
- `xcode/` - Aliases

### Applications

- `amphetamine/` - Install Amphetamine (keep-awake) from the Mac App Store via `mas`
- `brave/` - Install, default browser configuration, and extension checklist
- `claude/` - Claude Code install and global configuration: `settings.json`, `AGENTS.md` (linked to `~/.claude/CLAUDE.md`), `mcp.json`, hooks, scripts, skills, `omai/`, and auto-memory. `deploy.sh` links it into `~/.claude` and merges `mcp.json` into `~/.claude.json`. `cl` (`claude/alias.zsh`) runs Claude Code with the omai env and no sandbox. `cl --no-omai` skips the omai env. `claude/shim/security` sends Claude Code keychain items to `claude/.claude.keychain.db` (gitignored) instead of the login keychain. `claude/install.sh` creates that keychain.
- `commercetools/` - API/CLI aliases
- `obsidian/` - Aliases
- `lute/` - Lute v3 language reader (venv install and `lute` launcher). It also runs offline reader-dict `.df` dictionary servers (fr-en on `:8767`, fr-fr on `:8766`). `lute-import-podcast` imports podcast RSS transcripts and audio as books. `lute-prune-audio` deletes audio from archived or deleted books.
- `iterm/` - Shell integration, auto tab title (`repo (worktree:branch tool)`), and deterministic tab color per directory
- `rancher/` - Rancher Desktop install and PATH
- `magnet/` - Window layout overrides and install
- `renovate/` - Local configuration
- `nono/` - [nono](https://nono.sh) agent sandbox: install, packs, and profiles. The profiles are `agent-base`, `agent-extended`, `mcp`, `claude-sandboxed`, and `claude-directory`. They are symlinked to `~/.config/nono/profiles`. The topic also has a rollback `config.toml`. The `mcp` profile injects the AG client secrets from the keystore as env vars (`env_credentials`). It also swaps the CircleCI phantom token for the real one on upstream requests (`custom_credentials`). `claude-sandboxed` extends `mcp`. Store every keystore account listed in `mcp.jsonc`. `claude-nokeychain.sh` generates `profiles/claude-nokeychain.json`, a Keychain-free copy of the `nolabs-ai/claude` pack profile. Re-run it after `nono update`. `cln` (`nono/claude-nono`) launches Claude Code sandboxed. `clp` (`nono/claude-nono-personal`) launches it for the personal account only. It uses the `claude-personal` profile, which denies `~/code/ct`. `nonop <name>` promotes a `.jsonc` profile draft from `~/.config/nono/profile-drafts` into `profiles/`

### System

- `macos/` - macOS defaults and install
- `script/` - Bootstrap and install entry points

## Notes

- Oh My Zsh is not sourced at startup. OMZ is still installed (for p10k, z, and kube-ps1, which live under `~/.oh-my-zsh/`), but `oh-my-zsh.sh` is never loaded. `zsh/oh-my-zsh.zsh` sources only the parts that the shell needs.
- fnm manages Node versions. [fnm](https://github.com/Schniz/fnm) replaces NVM. It is written in Rust and switches versions automatically on `cd` through `fnm env --use-on-cd`, with near-zero overhead.
- zsh-defer defers non-critical sources (syntax highlighting, gcloud completion, iterm integration, terraform) until after the first prompt is drawn.
- kube-ps1 loads on demand. Type `kube-on` to load the Kubernetes context into your prompt.
- The tmux prefix is `Ctrl+a`, not the default `Ctrl+b`. `Ctrl+a Space` triggers easy-motion (2-character jump). `Ctrl+a F` triggers thumbs (quick copy). [TPM](https://github.com/tmux-plugins/tpm) manages the plugins. Press `prefix + I` to install them and `prefix + U` to update them.
- To profile startup, run `ZPROF=1 zsh -i -c exit`. It prints a startup timing breakdown.
- The Homebrew shellenv is cached in `zsh/zprofile.symlink` for faster startup. If you reinstall or move Homebrew, run `/opt/homebrew/bin/brew shellenv` again and update that file.

## Install

```sh
git clone <repo> ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

Forked from [holman/dotfiles](https://github.com/holman/dotfiles).
