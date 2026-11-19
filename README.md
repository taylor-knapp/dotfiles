# dotfiles

## Quick Reference

- `reload!`: reload the shell configuration after you change it
- `.dotfiles`: run the full install on a new machine
- `script/bootstrap`: create the symlinks and run the installers

## How It Works

Everything is organized into topic directories. The file names control how each file is used:

| Pattern                | Behavior                                              |
| ---------------------- | ----------------------------------------------------- |
| `topic/*.zsh`          | Automatically sourced into your shell                 |
| `topic/path.zsh`       | Loaded first. Sets up `$PATH`                         |
| `topic/completion.zsh` | Loaded last. Sets up autocomplete                     |
| `topic/install.sh`     | Runs during `script/install`                          |
| `topic/*.zshenv`       | Not auto-sourced. `zsh/zshenv.symlink` sources it for every shell, including non-interactive shells |
| `topic/*.symlink`      | Symlinked into `$HOME` (without `.symlink` extension) |
| `bin/*`                | Added to `$PATH` globally                             |

## Structure

### Shell

- `zsh/`: Primary shell. Uses Powerlevel10k, zsh-defer, completions, and aliases
- `bash/`: Bash profile and rc files (symlinked)
- `system/`: System-wide aliases, environment variables, keyboard configuration, and macOS Automator workflows
- `functions/`: Shell functions and completions (for example, `extract` and `c`)
- `bin/`: Utility scripts added to `$PATH` (for example, git helpers, `e`, `dns-flush`, and `set-defaults`)

### Languages & Runtimes

- `node/`: Node.js aliases and install
- `python/`: PATH configuration
- `ruby/`: gemrc and irbrc
- `java/`: SDKMAN configuration and install
- `go/`: PATH configuration
- `rust/`: Cargo bin PATH configuration

### Tools

- `git/`: Aliases, gitconfig, global gitignore, and commit template
- `docker/`: Aliases
- `k8s/`: Kubernetes aliases, install, and PATH
- `postgres/`: Install and PATH
- `mongo/`: Install
- `tmux/`: Terminal multiplexer with easy-motion, thumbs, and Catppuccin theme
- `homebrew/`: Install script

### Editors & IDEs

- `vim/`: vimrc (symlinked)
- `neovim/`: Neovim install (`brew install neovim`, ripgrep, and tree-sitter-cli). The full setup lives in `neovim/config`, which is symlinked to `~/.config/nvim`
- `vscode/`: PATH configuration
- `jetbrains/`: Launcher scripts for IntelliJ, DataGrip, and WebStorm
- `xcode/`: Aliases

### Applications

- `amphetamine/`: Install Amphetamine (keep-awake) from the Mac App Store with `mas`
- `brave/`: Install, default browser configuration, and extension checklist
- `claude/`: Claude Code install and global configuration. The topic holds `settings.json`, `AGENTS.md` (linked to `~/.claude/CLAUDE.md`), `mcp.json`, hooks, scripts, skills, `omai/`, and auto-memory. `deploy.sh` links it into `~/.claude` and merges `mcp.json` into `~/.claude.json`. `cl` (`claude/alias.zsh`) runs Claude Code with the omai env and no sandbox. `cl --no-omai` skips the omai env. `claude/shim/security` sends Claude Code keychain items to `claude/.claude.keychain.db` (gitignored) instead of the login keychain. `claude/install.sh` creates that keychain. It also installs colgrep (semantic code search) and registers it as a Claude Code plugin.
- `commercetools/`: API and CLI aliases
- `obsidian/`: Aliases
- `opencode/`: OpenCode install. `ocn` (`opencode/opencode-nono`) runs OpenCode under nono with the `opencode-sandboxed` profile and the omai configuration in `opencode/omai`. `ocn --no-omai` skips the omai configuration. OpenCode also loads the Claude Code skills from `~/.claude/skills`.
- `lute/`: Lute v3 language reader (venv install and `lute` launcher). It also runs offline reader-dict `.df` dictionary servers: fr-en on `:8767` and fr-fr on `:8766`. `lute-import-podcast` imports podcast RSS transcripts and audio as books. `lute-prune-audio` deletes audio from archived or deleted books.
- `iterm/`: Shell integration, tab titles (`repo (worktree:branch tool)`), and a fixed tab color for each directory
- `rancher/`: Rancher Desktop install and PATH
- `magnet/`: Window layout overrides and install
- `renovate/`: Local configuration
- `nono/`: [nono](https://nono.sh) agent sandbox with install, packs, and profiles. The profiles are `agent-base`, `agent-extended`, `mcp`, `claude-sandboxed`, `claude-directory`, and `opencode-sandboxed`. They are symlinked to `~/.config/nono/profiles`. The topic also has a rollback `config.toml`. `cln` exports the AG client secrets from the keystore as env vars, and `claude-nono` lists them. `env_credentials` turn into phantoms under `agent-base`, which is why `cln` does this. See `nono/AGENTS.md`. The `mcp` profile swaps the CircleCI phantom token for the real one on upstream requests (`custom_credentials`). `claude-sandboxed` extends `mcp`. Store every keystore account that `claude-nono` or `mcp.jsonc` lists. `claude-nokeychain.sh` generates `profiles/claude-nokeychain.json`, a Keychain-free copy of the `nolabs-ai/claude` pack profile. Re-run it after `nono update`. `cln` (`nono/claude-nono`) launches Claude Code sandboxed. `clp` (`nono/claude-nono-personal`) launches it for the personal account only. It uses the `claude-personal` profile, which denies `~/code/ct`. `nonop <name>` promotes a `.jsonc` profile draft from `~/.config/nono/profile-drafts` into `profiles/`

### System

- `macos/`: macOS defaults and install
- `script/`: Bootstrap and install entry points

## Notes

- Oh My Zsh is not sourced at startup. OMZ is still installed for p10k, z, and kube-ps1, which live under `~/.oh-my-zsh/`. The `oh-my-zsh.sh` file is never loaded. `zsh/oh-my-zsh.zsh` sources only the parts that the shell needs.
- fnm manages Node versions. [fnm](https://github.com/Schniz/fnm) replaces NVM. It is written in Rust and switches versions automatically on `cd` through `fnm env --use-on-cd`. The overhead is small.
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
