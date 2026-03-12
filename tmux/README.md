# tmux

Terminal multiplexer with flash.nvim-like label jumping (easy-motion), quick-copy (thumbs), and Catppuccin status bar.

## What's Installed

- **tmux** — terminal multiplexer
- **TPM** — Tmux Plugin Manager (`~/.tmux/plugins/tpm`)
- **tmux-easy-motion** — label-based jumping across the visible pane
- **tmux-thumbs** — quick-copy URLs, paths, SHAs, and other patterns
- **catppuccin/tmux** — Mocha-flavored status bar theme
- **tmux-sensible** — sensible defaults

## Key Bindings

Prefix: `Ctrl+a`

### Core

| Key | Action |
|---|---|
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + r` | Reload config |
| `prefix + I` | Install plugins (TPM) |
| `prefix + U` | Update plugins (TPM) |

### Easy-Motion

| Key | Action |
|---|---|
| `prefix + Space` | 2-char bidirectional search — type 2 chars, labels appear, press label to jump |

### Thumbs

| Key | Action |
|---|---|
| `prefix + F` | Highlight URLs/paths/SHAs — press label to copy to clipboard |

### Copy Mode

| Key | Action |
|---|---|
| `prefix + [` | Enter copy mode |
| `v` | Begin selection (vi mode) |
| `y` | Yank to system clipboard |

## Shell Aliases

| Alias | Command |
|---|---|
| `t` | `tmux new-session -A -s main` (attach or create) |
| `ta` | `tmux attach -t` |
| `tls` | `tmux list-sessions` |
| `tks` | `tmux kill-session -t` |
| `tka` | `tmux kill-server` |

## Common Workflows

```sh
# Start or reattach to main session
t

# New named session
tmux new -s project

# Split into editor + terminal
prefix + |    # side-by-side
prefix + -    # top/bottom

# Jump anywhere visible (flash.nvim-like)
prefix + Space → type 2 chars → press label

# Quick-copy a URL or path
prefix + F → press label → pasted to clipboard
```

## Plugin Management

- **Install plugins:** `prefix + I`
- **Update plugins:** `prefix + U`
- **Reload config:** `prefix + r`

Plugins are defined in `~/.tmux.conf` and managed by [TPM](https://github.com/tmux-plugins/tpm).
