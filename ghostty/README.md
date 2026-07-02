# Ghostty

Ghostty terminal config, ported from the `iterm/` topic.

## Files

| File         | Purpose                                                                     |
| ------------ | --------------------------------------------------------------------------- |
| `config`       | Ghostty settings — symlinked to `~/.config/ghostty/config`                  |
| `tab.zsh`      | Auto-sourced into zsh — sets tab/window title via `precmd`/`preexec` hooks  |
| `dump-docs.sh` | Dumps the full Ghostty reference to gitignored `ghostty-docs.txt`           |
| `install.sh`   | Symlinks `config`, runs `dump-docs.sh`, installs a daily cron to refresh it |

## Setup

```sh
bash install.sh
```

Then reload Ghostty (`cmd+shift+,`) or restart. `tab.zsh` is auto-sourced by the
dotfiles loader (`topic/*.zsh`) and only activates when `$TERM_PROGRAM == ghostty`.

Optionally disable Claude Code's title override in `~/.claude/settings.json`:

```json
{ "env": { "CLAUDE_CODE_DISABLE_TERMINAL_TITLE": "1" } }
```

## What Ported From iTerm

- **Title** — `tool: repo branch` format, repo abbreviated to initials when >30 chars.
- **Colors** — classic xterm/iTerm 16-ANSI palette, `#bbbbbb` fg. Background left at
  Ghostty's lighter gray default (iTerm's pure black not ported, by choice).
- **Font** — JetBrains Mono Nerd Font Mono 12.
- **Window** — ~3% transparency + background blur, blinking cursor, reuse cwd for new
  tabs/splits, new tab next to current.

## What Did NOT Port

- **Per-tab background color** — iTerm's deterministic hash color used the proprietary
  `\e]6;1;bg;...` escape. Ghostty has no per-tab color sequence, so this is dropped.
- **Shell integration download** — Ghostty auto-injects zsh integration; no
  `iterm-shell-integration.zsh` equivalent needed.

## Gotchas

- Confirm the font family name matches what Ghostty sees: `ghostty +list-fonts | grep -i jetbrains`.
- iTerm blur radius (4.79, iTerm scale) doesn't map 1:1 to Ghostty. `config` uses
  `background-blur = true` (default radius); bump to `background-blur = 20` to taste.
- Scrollback: iTerm was 100k lines. Ghostty defaults to a generous byte limit
  (`scrollback-limit`), left at default here.
