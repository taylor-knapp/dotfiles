# AGENTS.md

## Goal

Personal macOS dotfiles (forked from holman/dotfiles). This repo bootstraps a new machine. It keeps the shell, editor, terminal, and tool configuration under version control. It is optimized for fast zsh startup.

## Layout

Everything lives in topic directories (`git/`, `zsh/`, `neovim/`, `tmux/`, …). The file names control behavior.

| Pattern                | Behavior                                              |
| ---------------------- | ----------------------------------------------------- |
| `topic/*.zsh`          | Auto-sourced into the shell                           |
| `topic/path.zsh`       | Sourced first. Sets `$PATH`                           |
| `topic/completion.zsh` | Sourced last. Sets up completions                     |
| `topic/install.sh`     | Run by `script/install`                               |
| `topic/*.symlink`      | Symlinked into `$HOME` without the extension          |
| `bin/*`                | On `$PATH`                                            |

`script/bootstrap` links every `*.symlink` file at depth 2 to `~/.<name>`. For example, `zsh/zshrc.symlink` becomes `~/.zshrc`. It prompts before it replaces an existing file.

Non-interactive shells (Neovim `:!`, `zsh -c`) read only `~/.zshenv`. They skip every `topic/*.zsh` file. `zsh/zshenv.symlink` keeps the `~/.cargo/env` line. It also sources every `topic/*.zshenv` file (a glob at depth 2) for every shell, interactive or not. The glob and the git aliases add about 7 to 10 ms to each zsh start. If a file must load there, name it `*.zshenv`, without the `.zsh` suffix. The `topic/*.zsh` glob then skips that file, so it loads once. Keep terminal-only setup, for example `GPG_TTY`, out of those files. `.zshenv` must use `$HOME/.dotfiles`, because `$DOTFILES` is not set yet. `bin/.dotfiles` exports `$DOTFILES`. `PATH` setup from `system/_path.zsh` does not run in non-interactive shells.

The nono sandbox denies agents read access to the shell startup files: `zsh/zshrc.symlink`, `zsh/zprofile.symlink`, `zsh/zlogin.symlink`, `bash/*.symlink`, and `nono-demo/.env`. Do not try to work around the deny. Ask the user to read or edit those files.

Configuration files under `~/.config/<app>` (for example, `neovim/`) are symlinked by the `install.sh` of that topic.

Run `script/bootstrap` to create the symlinks and run the installers. Run `script/install` to run every `install.sh` file.

The `zsh/` topic uses p10k and zsh-defer. It does not source Oh My Zsh. Other key topics are `git/`, `neovim/` (full nvim configuration in `neovim/config`), `tmux/`, `iterm/`, `node/` (fnm), `macos/`, and `homebrew/`.

## After Every Change

1. `CHANGELOG.md`: Always add an entry under today's date. Keep entries concise. If no heading exists for today's date, create one first.
2. `README.md`: If the change affects the project structure, conventions, or anything documented there, update it. For example, add new topics, changed file conventions, or removed features. If the change is purely internal, skip it.

Some topics have their own `CLAUDE.md` or `README.md` files, for example `neovim/config/`. Read them before you edit that topic. See `README.md` for the full topic list and notes.

## Performance Testing

Do not regress shell startup. Benchmark shell startup and commands to catch regressions:

```zsh
# Full shell startup time
time zsh -i -c exit

# Startup with profiling breakdown (uses zprof)
ZPROF=1 zsh -i -c exit

# Time a specific shell function (wrap in subshell since cd modifies state)
time (POWERLEVEL9K_INSTANT_PROMPT=off gw review)

# Time an individual command/function in an already-loaded shell
time _fnm_autoswitch
time gw-link ~/path/to/worktree

# Time a command in a fresh zsh with full dotfiles loaded
zsh -c 'time (some_command)'

# Isolate a specific piece: eval into fnm, then time
eval "$(fnm env --shell zsh)" && time fnm use --silent-if-unchanged
```

Key gotchas:

- `time` cannot measure a function that runs `cd` in the current shell. Wrap the function in `( subshell )`.
- Aliases (for example, `cl`) do not expand inside functions. Use the real command name.
- `node -v` through fnm shims takes about 1.2 s. To show versions, use `fnm current` (about 11 ms).
- `POWERLEVEL9K_INSTANT_PROMPT=off` prevents p10k warnings in timing subshells.
