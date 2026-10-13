# Changelog

## 2026-10-13

- claude: `update-context`/`c` skills retargeted to the dotfiles layout (AGENTS.md + skills + hooks/settings + nono profiles); dropped `.agents/`/`rules/` targets, stale commit-signing example, AskUserQuestion.
- claude: condensed `AGENTS.md` (~1.4k → ~330 words); dropped rules made stale by nono (commit signing, `git -C`, https push, Claude sandbox notes) and missing skills; removed `.agents/` includes; macOS defaults guidance moved to `macos-defaults` skill.
- claude: absorbed `~/code/claudie` (deprecated). `claude/` now holds `settings.json`, `AGENTS.md` (linked as `~/.claude/CLAUDE.md`), `mcp.json`, hooks, statusline + MCP wrapper scripts, `omai/`, auto-memory dir, and skills (`pr`, `francais`, `anki`, `update-context`, `c`, `note`). `claude/deploy.sh` (run by `install.sh`) links them into `~/.claude` and prunes old claudie skill links. Dropped settings `sandbox` block + its `enforce-sandbox-on-tools`/`block-settings-edit` hooks (nono enforces fs). nono profiles, `claude-nono` omai path repointed; removed `cl`/`cj` safehouse aliases.
- nono: `claude-nono --allow-dir=PATH` (repeatable) grants read-write to PATH (`nono --allow`) and passes `claude --add-dir PATH`.
- nono: `nonop <name>` (`nono/nonop`) promotes `~/.config/nono/profile-drafts/<name>.jsonc` into `nono/profiles/` (`nono profile promote` only reads `.json`). Checks `.base` hash, validates, shows diff, confirms.
- nono: `agent-base` mediates `git` — session still denied `.git/config`/hooks; mediated git gets repo write + allowlisted subcommands (no `config`, no global opts, no `--output`/`--exec`/`--upload-pack`/`--template`), can call `gpg` for signing (gpg gets read on `@git:toplevel` so `getcwd` works; `user.signingkey` overridden to the `~/.gnupg-claude` key; command-level `GNUPGHOME` is absolute since command `set_vars` do not expand `$HOME`); git env overrides (gh credential helper, https insteadOf, gpg signing) now live in the git command sandbox, not session env, which does not reach command sandboxes.
- nono: `claude-nono --login` runs `claude auth login` (then starts the normal session) under new profile `claude-login` (extends `claude-sandboxed` + `listen_port_range` 49152–65535 for the OAuth callback, `interactive`, `--allow-launch-services`). Normal sessions get no listen ports/browser opens. `oauth_capture` keeps real tokens host-side; phantoms in `~/.claude` keep later sessions logged in and refreshing.

## 2026-10-12

- nono: added `nono/claude-nokeychain.sh` — generates `nono/profiles/claude-nokeychain.json` (jq copy of the `nolabs-ai/claude` pack profile minus its `~/Library/Keychains` allow + `bypass_protection`). Child profiles can't remove inherited bypasses, hence the copy. `claude-sandboxed` and `claude-directory` now extend it. Run by `nono/install.sh`; re-run after `nono update`. `install.sh` skips `brew install nono` if already present.
- nono: removed `$HOME/code/*-worktrees` glob from `agent-extended` (globs hang nono 0.79). `cln` now grants per repo: `--allow <repo>-worktrees` if it exists, `--allow <main repo>` when run in a worktree, `--read ~/code/ct` automatically when the repo is under it (`--ct` flag removed).
- nono: `claude-nokeychain.sh` now adds an `oauth_capture` credential provider (`claude_code`) + `anthropic_oauth` route, so Claude Code's OAuth token reaches `api.anthropic.com` via nono's proxy (sandbox only sees a phantom token).

## 2026-10-08

- Added `nono/profiles/` (`agent-base`, `claude-sandboxed`) — nono port of claudie's `claude-sandboxed` safehouse profiles + `claude-netproxy` domain allowlist. `nono/install.sh` pulls `nolabs-ai/claude` + `nolabs-ai/opencode` packs and symlinks profiles into `~/.config/nono/profiles`.
- nono: `gpg` is now a mediated command (only git sign/verify argv allowed; session can no longer read `~/.gnupg-claude`) — replaces `gpg-claude-wrap.sh`. Added rollback exclusions, `nono/config.toml` (rollback retention), and `nono/claude-nono` wrapper (`cln`): `--rollback`, `--online`, omai env (`--no-omai`), `--directory-only` (profile `claude-directory`), `--playwright`, `--ct`, MCP disabled by default (`nono/disable-all-mcp.sh`, copied from claudie). Profiles split: `agent-base` (essentials) / `agent-extended` (broader access). `claude-sandboxed` extends `nolabs-ai/claude`.
- nono: `claude-nono` passes `--trust-proxy-ca` so Go CLIs (`gh`) trust nono proxy CA.

## 2026-10-02

- Added `amphetamine/install.sh` — installs Amphetamine from the Mac App Store with `mas` (app ID `937984704`).

## 2026-10-01

- Added `lute/lute-import-podcast FEED_URL [TAG]` — imports a podcast's `<podcast:transcript>` HTML transcripts into a running Lute as books (oldest first) via Lute's `/book/new` form. Skips episodes already in Lute, so re-running only adds new ones.
- `lute-import-podcast` — attaches each episode's `<enclosure>` audio; existing unarchived books without audio get it added via Lute's edit form.
- `lute-import-podcast` — optional `TRANSCRIPTS_JSON` arg (`{episode <link>: transcript}`) for feeds without `<podcast:transcript>`, e.g. innerFrench, whose transcripts sit behind Cloudflare and must be fetched from a logged-in browser.
- `lute-import-podcast` — downloads and posts to Lute with `curl` (GETs retried 3×; 10 min cap; aborts transfers under 1 KB/s for 60s). urllib hung for hours on a stalled Podbean download and on posting a 150 MB episode; dropped the hand-rolled multipart encoder.
- `lute-import-podcast` — reuses audio already in `useraudio/` when its size matches the feed's `<enclosure length>` (e.g. files orphaned when iCloud rolled the DB back) instead of re-downloading.
- `lute-prune-audio [-n] [DIR...]` — also prunes extra audio dirs (audio moved out of Lute's iCloud `useraudio/` and linked by absolute path, e.g. `~/Documents/inner-french`).
- Added `lute/lute-prune-audio [-n]` — unlinks audio from archived books, then deletes `useraudio/` files no book references (Lute never deletes audio, even for deleted books). `-n` is a dry run.

## 2026-09-30

- Added `lute/dicts.sh` — downloads the reader-dict fr-en and fr-fr (no-etymology) `.df` dictionaries into `~/Documents/Dictionaries` when missing. `lute` runs it on every start.
- `lute` — fr-en dictionary server moved `8765` → `8767`; `oktapus` already listens on 8765, and the "already running?" curl check mistook it for the dict server, so fr-en never started. Dropped that check: a busy port now fails loudly instead.

## 2026-09-28

- Added `lute/dictserver.py` — serves a reader-dict `.df` file over HTTP for Lute. `lute` starts one per dictionary in the background: `dict-fr-en.df` on `localhost:8765`, `dict-fr-fr.df` on `localhost:8766` (from `~/Documents/Dictionaries`). Warns with setup steps if a file is missing. Servers started by `lute` are stopped when Lute exits.

## 2026-09-27

- `python/path.zsh` — only adds pyenv shims to `$PATH` when `~/.pyenv/shims` exists; no more `command not found: pyenv` at startup (and no `$(pyenv root)` subshell).

- `claude/install.sh` — brew-installs `ccusage` (Claude Code usage reports).
- Added `go/install.sh` — brew-installs the Go toolchain. The `go/` topic only set `$PATH` before, so `go` itself was never installed.
- `neovim/install.sh` — installs JetBrains Mono Nerd Font (icons render as `?` without a Nerd Font).
- `neovim/install.sh` — runs `node/install.sh` when `npm` is missing; Mason needs npm for jsonls/eslint.
- Removed `ghostty/` topic and its README/AGENTS.md references.
- Added `AGENTS.md` — repo goal, topic layout/conventions, and rules for coding agents.
- Merged `CLAUDE.md` into `AGENTS.md` (change checklist + performance testing); `CLAUDE.md` now just imports `@AGENTS.md` and `@README.md`.
- `git/gitconfig.symlink` — moved `[include] ~/.gitconfig.local` to the end so machine-local settings (e.g. `commit.gpgsign = false`) override shared ones.
- Added `neovim/` topic — `install.sh` brew-installs neovim, ripgrep, tree-sitter-cli and symlinks `neovim/config` → `~/.config/nvim` (backs up an existing non-symlink dir). Config moved in from `~/.config/nvim` (formerly the `nvim-config` repo).

## 2026-07-02

- `node/aliases.zsh` — silenced the startup `_fnm_autoswitch` call (`>/dev/null 2>&1`). It runs before the first prompt in repos with `.nvmrc`, and fnm's "Using Node vX" output tripped Powerlevel10k's instant-prompt warning. The `chpwd` hook still prints on interactive `cd`.

## 2026-06-23

- `iterm/com.googlecode.iterm2.plist` — changed default Background Color from pure black to `#282c34` (R 0.157, G 0.173, B 0.204) to match Ghostty's lighter gray default.
- Added `ghostty/` topic — Ghostty terminal config ported from `iterm/`. `config` (symlinked to `~/.config/ghostty/config`), `tab.zsh` (title hooks, gated on `$TERM_PROGRAM == ghostty`), `install.sh`, `README.md`. Per-tab color and shell-integration download did not port (Ghostty has no per-tab color escape; auto-injects integration).
- `ghostty/config` — set `shell-integration-features = no-title` so `tab.zsh` titles aren't clobbered by Ghostty's built-in title feature; bumped `background-opacity` 0.97 → 0.98.
- `ghostty/CLAUDE.md` — how to search Ghostty docs (`ghostty +show-config --default --docs | grep`, CLI actions, offline bundle docs). ghostty.org 403s automated fetchers.
- `ghostty/dump-docs.sh` + `ghostty/.gitignore` — script generates a gitignored `ghostty/ghostty-docs.txt` offline dump (config ref + actions + keybinds + themes + bundled markdown); finds `ghostty` on PATH or the app bundle. Wired into `install.sh` (best-effort). `CLAUDE.md` instructs reading it first and flagging the user when the dump is >30 days old.
- `ghostty/install.sh` — installs an idempotent daily cron (09:00) running `dump-docs.sh`, so the docs dump auto-refreshes on Ghostty upgrades. README/CLAUDE.md updated.
- `ghostty/tab.zsh` — dropped the OSC 11 per-project background tint. Ghostty tab color (1.3.0) is macOS UI-only (no escape/keybind/config), and OSC 11 is a single solid color with no gradient/top-fade option, so there's no good per-directory tab-color analog. Title hooks unchanged.

## 2026-06-18

- `iterm/com.googlecode.iterm2.plist` — changed Option+Left/Right to send escape sequences `[1;3D`/`[1;3C` for Neovim instead of word-jump
- `zsh/zshrc.symlink` - added key binding to translate the escape sequences to word-jumps

## 2026-06-11

- `iterm/com.googlecode.iterm2.plist` — enabled `Blinking Cursor`

## 2026-06-10

- Added `ct` function (`functions/ct`) + completion (`functions/_ct`) — jumps to `$PROJECTS/ct/<tab>`, mirrors `c`

## 2026-05-12

- `claude/install.sh` — added caveman install (https://github.com/JuliusBrussee/caveman)
- Removed `jetbrains/datagrip` and `jetbrains/idea` launcher scripts; regenerated `jetbrains/storm` from Toolbox

## 2026-04-03

- Added `cj` alias for `claude-jailed` in `claude/alias.zsh`

## 2026-03-24

- `gw main` now navigates to the main worktree root (alias for `gw root`) instead of trying to create a worktree called "main"

## 2026-03-17

- Added `bin/iterm-open-nvim` — Cmd+click file paths in iTerm2 open in nvim via a new tmux session
- Configured iTerm2 Semantic History in plist to run `iterm-open-nvim` on file clicks
- Restored agent-safehouse install/upgrade logic in `claude/install.sh`

## 2026-03-13

- Added `glogs` alias — same as `glog` but includes GPG signature status (`G`/`N`/etc.) after the commit hash. Kept separate from `glog` because `%G?` triggers per-commit GPG verification which is slow.
- Added `git/README.md` documenting all primary aliases, `glogs` signature indicators, and OMZ-ported alias groups

## 2026-03-12

- Removed agent-safehouse — `cl` is now a plain alias to `claude`, install script only installs Claude Code
- `claude/alias.zsh` — added `SAFEHOUSE_ADD_DIRS` to grant Claude read/write access to `claudie`, `.dotfiles`, `.config/nvim`, `uaa-shared`, `notes`, `tickets`

- `claude/install.sh` — safehouse install now checks: install if missing, upgrade if Homebrew-managed, error if installed via another method
- Added `claude/install.sh` — installs `claude-code` and `agent-safehouse` via Homebrew
- `cl` now wraps claude through `safehouse` (`cl() { safehouse claude "$@"; }`) instead of a plain alias
- `gco` prompt now offers `[r]emote fetch / [c]reate` in a single prompt instead of two sequential y/n questions; if remote fetch finds nothing, follows up with a create offer

## 2026-03-11

- Migrated iTerm2 prefs from Dropbox sync to repo — stored cleaned plist at `iterm/com.googlecode.iterm2.plist`, install script points iTerm's "custom folder" here so UI changes write directly to the repo copy
- Fixed smart truncation not persisting — root cause was Dropbox plist overwriting local prefs on every launch
- Replaced `set-title-components.py` (iTerm2 Python API) with a PlistBuddy command in `iterm/install.sh` — works outside of iTerm2
- Configured `git difftool` to use `nvimdiff` with no prompt in `git/gitconfig.symlink`

## 2026-03-10

- Added `iterm/tab.zsh` — auto-sets tab title to `repo...:branch (tool)` (or `repo.../worktree:branch (tool)` for named worktrees) with deterministic tab color per git root
- Configured iTerm to show session name only in tab title (removes `(-zsh)` job suffix)

## 2026-03-09

- Added `tmux/` topic — tmux config with `Ctrl+a` prefix, tmux-easy-motion (flash.nvim-like label jumping), tmux-thumbs (quick-copy URLs/paths/SHAs), Catppuccin status bar, TPM plugin manager, vi copy mode, and shell aliases

## 2026-03-07

- Added `brave/` topic — install script (Brave + `defaultbrowser` for setting default browser) and extensions checklist

## 2026-03-06

- Replaced NVM with fnm (Fast Node Manager) — eliminates ~1s version-switch delay; auto-switches on cd via `fnm env --use-on-cd`
- `gw <worktree>` now clears the terminal on navigation (like `gw <worktree> cli`)
- Skip `gw-layout` Python overhead for 0–1 tools — single tool runs directly in shell, layout only invoked for multi-pane splits
- Rewrote `gw` CLI: positional tool args (`cl`, `nvim`, `cli`) instead of `--flags`, tools and branch in any order
- Changed worktree location from `{repo}/worktrees/` to `{repo}-worktrees/` (sibling dir)
- Updated `gw-layout` ratios: `cl+cli` and `nvim+cli` now use H-split (90/10) instead of V-split; added tunable constants at top
- Added `gw root` to cd to main worktree root (with optional tools, no branch)
- Updated `_gw` completion to match new positional args, sibling worktree dir, and `root` keyword
- `gco` now checks for remote tracking branches before prompting to create; fetches from remote if local refs are stale — automatically checks out and tracks remote branches that exist
- Added Hammerspoon shortcut (`Ctrl+Alt+H`) to stretch window to full screen height while keeping current width and position
- Added `magnet/` topic to manage custom Magnet window layout overrides from dotfiles (`rightTwoThirds` → ~80% width, `iTerm` custom command)

## 2026-03-05

### Fix `load-nvmrc` breaking on `cd` into `.nvmrc` projects

- Removed conditional `$+functions` check entirely — just call `nvm --version` unconditionally to trigger the lazy stub (first call) or no-op (already loaded), avoiding all zsh parsing ambiguity

### Switch default editor to Neovim

- Changed `EDITOR` from `code` to `nvim` in `system/env.zsh`
- Changed `KUBE_EDITOR` from `code -w` to `nvim` in `zsh/zshrc.symlink`

### Restore Ctrl+S forward history search

- Added `setopt NO_FLOW_CONTROL` to disable XON/XOFF flow control (zsh builtin, no TTY needed — avoids p10k instant prompt `stty` issues)
- Added `bindkey '^S' history-incremental-search-forward` to restore forward incremental search lost when OMZ was dropped

## 2025-03-05

### ZSH Startup Performance Overhaul (~1.9s → <200ms)

#### Dropped Oh My Zsh as the shell loader

- OMZ sourced ~20 lib files, ran compfix, auto-update checks, `scutil`, `git rev-parse`, and its own `compinit` on every startup (~800ms)
- Replaced with direct sources for the 3 features we actually used: Powerlevel10k, NVM (lazy-loaded), and z
- OMZ is still _installed_ (p10k, z, kube-ps1 live under `~/.oh-my-zsh/`) — just not _sourced_

#### Added zsh-defer for non-critical sources

- Syntax highlighting, gcloud completion, iTerm shell integration, and terraform bashcompinit now load _after_ the first prompt is drawn
- zsh-defer is cloned into `$ZSH/custom/plugins/` and sourced early via `zsh/oh-my-zsh.zsh`
- `zsh/oh-my-zsh.zsh` is explicitly sourced before the main topic loop to guarantee zsh-defer is available for all topic files (e.g. `iterm/`)

#### NVM lazy loading

- Stub functions for `nvm`, `node`, `npm`, `npx`, `yarn`, `pnpx`, `corepack` defer sourcing `nvm.sh` (4387 lines) until first use
- The `chpwd` hook in `node/aliases.zsh` triggers lazy-load on first `cd` into an `.nvmrc` project

#### Cached compinit

- `compinit -C` skips security audit and fpath re-scan unless the dump is >24h old
- `.zcompdump` is compiled to `.zwc` in a background subshell for faster future loads
- Cleaned up 25 stale `~/.zcompdump-*` files

#### Removed dead code

- Deleted `ruby/rvm.zsh` — RVM is not installed
- Removed `hub` git wrapper from `git/aliases.zsh` — hub is not installed, `gh` replaced it
- Fixed `$(gls &>/dev/null)` subshell fork in `system/aliases.zsh` → `$+commands[gls]` hash lookup

#### kube-ps1 on-demand

- Type `kube-on` to load Kubernetes context into prompt instead of paying ~50ms every startup

#### Added ZPROF profiling toggle

- `ZPROF=1 zsh -i -c exit` prints a function-level timing breakdown of startup

#### Cached Homebrew shellenv

- `brew shellenv` output cached in `zsh/zprofile.symlink` to avoid a subprocess fork on every login shell
