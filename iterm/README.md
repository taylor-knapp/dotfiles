# iTerm Tab Titles & Colors

Auto-sets tab title and color based on your current directory.

## What It Does

**Title** — shows the running tool, repo, and branch:

```
cli: ags main              # main worktree, abbreviated repo
nvim: audit-log feature-x  # full repo name (fits in 30 chars)
claude: ags/wt-1 branch    # named worktree
cli: Downloads             # non-git directory
```

- Repo names are shown in full when the title fits in 30 chars, otherwise abbreviated to initials (`agent-gateway-services` → `ags`)
- Tool is `cli` (default shell), `claude`, or `nvim` — detected from the command you run
- Named worktrees show as `repo/worktree branch`

**Color** — each git root (or directory outside git) gets a deterministic tab color so you can visually distinguish projects at a glance.

## Files

| File | Purpose |
|------|---------|
| `tab.zsh` | Sourced into zsh — sets tab title via `precmd`/`preexec` hooks, sets tab color on `cd` |
| `install.sh` | One-time setup — configures iTerm preferences (title components, smart truncation, etc.) |

## Setup

### 1. Run the install script

Quit iTerm first (the script writes to iTerm's plist, and a running instance will overwrite changes on quit).

```sh
# From Terminal.app or another terminal:
bash install.sh
```

This does:
- Downloads iTerm shell integration for zsh
- Sets tab title to show **session name only** (removes the `(-zsh)` job suffix)
- Disables **smart truncation** (always truncates from the right, preserving the beginning of the title)
- Opens **new tabs next to the current tab** instead of at the end of the tab bar
- Enables the Python API server
- Sets new panes/tabs to reuse the current working directory

### 2. Source `tab.zsh` in your shell

Add to your `.zshrc` (or let a dotfiles framework auto-source it):

```zsh
source /path/to/tab.zsh
```

### 3. Disable Claude Code's title override (optional)

Claude Code sets its own tab title by default. To let `tab.zsh` stay in control, add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_TERMINAL_TITLE": "1"
  }
}
```

### 4. Relaunch iTerm

Open iTerm — tabs should now show colored titles based on your directory.
