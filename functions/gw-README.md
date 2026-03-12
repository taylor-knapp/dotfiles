# gw — Git Worktree Manager

A set of zsh functions for managing git worktrees with optional iTerm2 pane layouts.

## Components

| File | Type | Description |
|---|---|---|
| `gw` | zsh function | Main entry point — create, navigate, and launch tools in worktrees |
| `gw-link` | zsh function | Symlinks shared files from the main worktree into child worktrees |
| `_gw` | zsh completion | Tab completion for worktree names, branches, and tool arguments |
| `gw-layout` | python script (`bin/`) | iTerm2 pane layout manager using the iterm2 Python API |

## Usage

```bash
gw                           # list worktrees
gw <name>                    # create/navigate worktree (branch = <name>)
gw <name> <branch>           # create/navigate worktree, checkout <branch>
gw <name> cl nvim            # open with Claude + nvim panes
gw <name> <branch> cli       # checkout branch, open with cli pane
gw root                      # cd to main worktree root
gw root cl nvim              # cd to root + open with tools
```

### Tools

Tool arguments are positional and can appear in any order:

- `cl` (or `claude`) — launches Claude Code
- `nvim` — opens neovim
- `cli` — clears terminal (useful as a shell pane alongside other tools)

## Worktree Layout

Worktrees are created in a sibling directory named `<repo>-worktrees/`:

```
~/code/my-project/              # main worktree
~/code/my-project-worktrees/
  ├── feature-a/                # gw feature-a
  └── bugfix-123/               # gw bugfix-123
```

## gw-link

When entering a worktree, `gw-link` automatically symlinks shared files from the main worktree so config doesn't need to be duplicated. It reads a `.gwlinks` file from the repo root:

```
# .gwlinks — one path per line, # comments allowed
.vscode/
.claude/settings.local.json
local/
```

If `.gwlinks` doesn't exist, it falls back to: `.vscode/`, `.local/`, `local/`, `.claude/settings.local.json`.

## iTerm Pane Layouts (gw-layout)

When multiple tools are specified, `gw-layout` arranges iTerm2 panes:

| Tools | Layout |
|---|---|
| 1 tool | full screen |
| `cl` + `nvim` | V-split (cl 20% left, nvim 80% right) |
| `cl` + `cli` | H-split (cl 90% top, cli 10% bottom) |
| `nvim` + `cli` | H-split (nvim 90% top, cli 10% bottom) |
| `cl` + `nvim` + `cli` | V-split + H-split (cl left, nvim top-right, cli bottom-right) |

Requires iTerm2 with Python API enabled. The venv at `~/.local/venvs/gw-layout` is auto-created on first run.

## Installation

Place `gw`, `gw-link`, and `_gw` in your zsh functions directory (e.g., `~/.dotfiles/functions/`). Place `gw-layout` in a directory on your `$PATH` (e.g., `~/.dotfiles/bin/`).
