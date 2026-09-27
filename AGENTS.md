# AGENTS.md

## Goal

Personal macOS dotfiles (forked from holman/dotfiles). One repo that bootstraps a new machine and version-controls shell, editor, terminal, and tool configuration. Optimized for fast zsh startup.

## Layout

Everything lives in **topic directories** (`git/`, `zsh/`, `neovim/`, `tmux/`, …). File conventions drive behavior:

| Pattern                | Behavior                                              |
| ---------------------- | ----------------------------------------------------- |
| `topic/*.zsh`          | Auto-sourced into the shell                           |
| `topic/path.zsh`       | Sourced first; sets `$PATH`                           |
| `topic/completion.zsh` | Sourced last; completions                             |
| `topic/install.sh`     | Run by `script/install`                               |
| `topic/*.symlink`      | Symlinked into `$HOME` without the extension          |
| `bin/*`                | On `$PATH`                                            |

Configs under `~/.config/<app>` (e.g. `neovim/`) are symlinked by that topic's `install.sh`.

Entry points: `script/bootstrap` (symlinks + installers), `script/install` (runs every `install.sh`).

Key topics: `zsh/` (p10k, zsh-defer; Oh My Zsh is NOT sourced), `git/`, `neovim/` (full nvim config in `neovim/config`), `tmux/`, `iterm/`, `node/` (fnm), `macos/`, `homebrew/`.

## After Every Change

1. **CHANGELOG.md** — Always add an entry under today's date. Create a new date heading if one doesn't exist. Keep entries concise.
2. **README.md** — Update if the change affects the project structure, conventions, or anything documented there (new topics, changed file conventions, removed features, etc.). Skip if the change is purely internal.

Some topics have their own `CLAUDE.md`/`README.md` (e.g. `neovim/config/`); read them before editing there. See `README.md` for the full topic list and notes.

## Performance Testing

Don't regress shell startup. Benchmark shell startup and commands to catch regressions:

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

# Isolate a specific piece — eval into fnm then time
eval "$(fnm env --shell zsh)" && time fnm use --silent-if-unchanged
```

**Key gotchas:**

- `time` can't measure functions that `cd` in the current shell — wrap in `( subshell )`
- Aliases (e.g. `cl`) don't expand inside functions — use the real command name
- `node -v` through fnm shims is ~1.2s; use `fnm current` (~11ms) to check versions
- `POWERLEVEL9K_INSTANT_PROMPT=off` avoids p10k warnings in timing subshells
