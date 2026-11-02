# Changelog

## 2026-11-02

- nono: `opencode-sandboxed` gives read access to `~/.claude/skills`. OpenCode loads Claude Code skills from that directory, so `ocn` now has the skills in `claude/skills/`.
- opencode: Add the `opencode/` topic. `install.sh` installs OpenCode with Homebrew. `ocn` (`opencode/opencode-nono`) runs the OpenCode server and the TUI inside one nono sandbox with the new `opencode-sandboxed` profile. The server is `opencode serve` on a free port in 10900–10999, and the TUI connects with `--server`. A random per-session password protects the server. It does not use `--standalone`, because that binds a random port, and the sandbox proxy denies the TUI connection with `EPERM`. The wrapper adds the same worktree grants, GitHub credential, and repo-local `.nono.json` as `cln`. Wrappers for a tool now live in that tool's topic, not in `nono/`.
- opencode: `ocn` loads `opencode/omai` (OpenCode config and skills from omai) through `OPENCODE_CONFIG_DIR`, and opens the oktapus forward proxy port (`OKTAPUS_LISTEN`, default `8765`). It also limits OpenCode to the omai `ct-gateway` and `ct-gateway-gemini` providers (`enabled_providers` through `OPENCODE_CONFIG_CONTENT`), which hides the free Zen models. `ocn --no-omai` skips all of this. The `opencode` provider rendering needs omai 0.8.0 or newer.
- nono: `opencode-sandboxed` gives read and write access to the oktapus data directory (`~/Library/Application Support/oktapus`) and allows `commercetools.okta.com`. The agatha MCP server (`oktapus mcp`) needs both to read and refresh the Okta token.
- nono: Add the `opencode-sandboxed` profile. It extends the `nolabs-ai/opencode` pack profile, `agent-extended`, and `mcp`, and allows `opencode.ai` and `models.dev`.

## 2026-10-29

- nono, claude: `cln` exports the AG MCP client secrets from the keystore. The `mcp` profile no longer has `env_credentials` for them. Under `agent-base`, a live `command_policies` entry (`gpg`) turned those values into phantoms. The sandbox then sent the phantom as the `Basic` credential, and the AG auth server returned 401 `invalid_client`. An empty `commands` map does not cause this. To add an AG account, list it in `claude-nono`. The cause is in `nono/AGENTS.md`.
- nono: Add the `mcp` profile. Its `env_credentials` inject the MCP client secrets from the nono keystore (service `nono`) as env vars. `claude-sandboxed` extends it. A missing keystore entry aborts the sandbox launch.
- claude: `mcp-wrapper-ag.sh` reads `AG_<SERVER_NAME>_CLIENT_SECRET` (uppercased, `-` becomes `_`) instead of the Keychain. `circleci-mcp-wrapper.sh` reads `CIRCLECI_TOKEN`. The sandbox blocks Keychain access, so both lookups failed there.
- nono: Keystore accounts for MCP secrets are renamed to `ag_<server>` (base64 of `client_id:secret`) and `circleci_token`. AG secrets map to env vars (`env_credentials`). The CircleCI token is a phantom again: `mcp` has a `circleci` route that sends it in `Circle-Token`, and the proxy swaps in the real token. The new names replace the `ag-<server>` and `circleci-token` accounts. Re-store the secrets under the new names.
- claude: `mcp-wrapper-ag.sh` sends `AG_<SERVER_NAME>_CLIENT_SECRET` as the `Basic` credential, with no encoding step. `circleci-mcp-wrapper.sh` sets `NODE_USE_ENV_PROXY=1` so Node uses the proxy.
- claude: `mcp-wrapper-ag.sh` writes a debug log to `/tmp/claude/mcp-logs/wrapper-<env>.debug.log` and stderr. It logs each step, the token HTTP status, and redacted error bodies. It also logs the failing line on `ERR`, so silent exits leave a trace. Secret values are never logged.
- nono, claude: AG env vars are renamed from `AG_<SERVER_NAME>_CLIENT_SECRET` to `AG_<SERVER_NAME>_SECRET`. `mcp` maps them, and `mcp-wrapper-ag.sh` reads them. The new names avoid any stale `*_CLIENT_SECRET` value inherited from a shell.

## 2026-10-28

- nono: Moved the `claude_code` `credential_providers` and `credential_routes` from `claude-nokeychain` to `claude-sandboxed`. `claude-nokeychain.sh` no longer adds them. `claude-personal` and `claude-directory` extend `claude-nokeychain`, so they no longer inject OAuth phantoms.
- nono: `claude-nokeychain` phantoms use a `nono_` prefix. `access_token` and `refresh_token` get `format: "nono_{}"` (was `sk-ant-oat01-{}` for access). `phantom_fields` also covers the `mcpOAuth` entry's `accessToken` and `refreshToken` in `~/.claude/.credentials.json`. The `id_token` stays a JWT phantom, because `nono_` is not a JWT.
- nono: `claude-nokeychain.sh` regenerates `claude-nokeychain.jsonc` byte-for-byte, comments included. Comments are spliced in with `awk` because `jq` cannot emit them. The script also prints the last commit that changed the file (`git log -1 -p`).
- claude: Add the `claude/shim/security` wrapper, first on `PATH` through `claude/path.zsh`. When the parent process is `claude`, generic-password calls go to `claude/.claude.keychain.db` (or `$CLAUDE_KEYCHAIN`), not the login keychain. `claude/install.sh` creates that keychain. All other callers use `/usr/bin/security` unchanged.

## 2026-10-27

- claude: Add `cl` (`claude/alias.zsh`). It runs plain Claude Code with the omai `env` block from `omai/settings.json`, with no nono sandbox. `cl --no-omai` skips that env. The env reaches only the `claude` process, not the shell.

## 2026-10-22

- nono: `claude-nono` and `claude-nono-personal` run `gpgconf --launch gpg-agent` for `~/.gnupg-claude` before starting the sandbox. Before this, nothing started the agent outside the sandbox, so commit signing failed with `No agent running`. If the agent is already running, `gpgconf --launch` does nothing.
- nono: `agent-base` denies `.env` files, `*.client.env`, `secrets/` folders, `.git/hooks`, and `.git/config` with raw Seatbelt regex rules (`unsafe_macos_seatbelt_rules`) instead of `**` deny globs. At startup, nono walked the whole cwd (`node_modules` included) once for each `**` glob, so `cln` took 10–15s to start in `~/code/ct`. The rules now apply at any path, not only under the cwd, so they also cover a worktree's main checkout. `.env.template` stays readable and writable. A test rule denies files named `nono-deny-test.txt`.

## 2026-10-21

- nono: `agent-base` sets `network.open_port_range` to `[[10000, 10999]]`. Claude Code connects to the claudecode.nvim WebSocket server on localhost. The proxy-only network policy blocked that connection, so Neovim showed `Connection timeout` and cleared the queued `@` mentions. `neovim/config` sets the plugin `port_range` to the same window.
- nono: `agent-base` sets `network.tls_intercept.ca_validity` to `5d`, so the proxy CA lasts five days instead of one. An expired CA makes every intercepted request fail with `tls: access denied`.
- nono: `agent-base` sets `network.tls_intercept.ca_lifecycle` to `trusted`. nono 0.79 rejects the default `session` value. Every `cln` and `clp` launch failed with `Configuration parse error`.

## 2026-10-17

- lute: Use `truststore` so TLS checks go through the macOS Keychain, because Python 3.13+ rejects the Zscaler root CA (`Basic Constraints of CA cert not marked critical`).
- nono: If `claude auth status --json` reports the account `taylor.r.knapp@gmail.com`, `claude-nono` exits with an error before any setup. A missing login passes the check.
- nono: Add `clp` (`nono/claude-nono-personal`), which runs Claude Code with the personal account under the new `claude-personal` profile. If the cwd or an `--allow-dir` path resolves under `~/code/ct`, `clp` exits with an error. If the account is not `taylor.r.knapp@gmail.com`, `clp` also exits with an error. The profile extends `agent-base`, not `agent-extended`, and denies `~/code/ct` and the `~/code/ct` session transcripts in `~/.claude/projects`.

## 2026-10-15

- nono: add `nono/AGENTS.md`, which lists the nono CLI commands that agents use to learn, inspect, and test profiles.
- nono: `cln` loads `.nono.json` from the repo root, or from the cwd outside a repo. The local profile extends `claude-sandboxed`, or `claude-directory` with `--directory-only`.

## 2026-10-14

- nono: `agent-base` defines two GitHub proxy credentials, `github_personal` and `github_commercetools`. Each one injects a fine-grained PAT from Keychain (service `nono`) into `api.github.com` requests, and the sandbox sees only a phantom `GH_TOKEN`. `claude-nono` enables one of them from the owner of the `origin` remote. Other owners get no token.

- claude: `install.sh` now installs Claude Code, ccusage, and caveman on all platforms (no longer macOS-only) and drops agent-safehouse. It also adds the `simple-english` plugin marketplace and installs the plugin.
- claude: The default model switched to Haiku 5.5 (`settings.json` `model`, `ANTHROPIC_MODEL`). Haiku effort lowered from `xhigh` to `low`.
- claude: statusline line 2 ends with the base input price per million tokens. Opus shows `$4 Mtok`, and Sonnet shows `$2 Mtok`. Haiku shows `$0.10 Mtok` in green up to 100K used tokens and `$0.50 Mtok` in red above that.
- nono: `agent-base` now mirrors the `claude/settings.json` deny rules. The session cannot run `/usr/bin/security`. `git push` is denied. The session cannot read or write `.env`, `.env.*`, or `secrets/**` in the workdir.
- nono: `agent-base` allows `osascript` only with the exact notification scripts that the `claude/settings.json` Stop and Notification hooks run. Every other `osascript` call is denied. The session cannot run `/usr/bin/open`.
- nono: `claude-login` is now a standalone profile with no `extends`. It allows only what `claude auth login` needs: the claude install, `~/.claude`, `~/.claude.json`, the claude hosts, the OAuth callback ports, and browser opens. It also allows `~/Library/Keychains`, the whole folder, because Keychain saves write temp files there. `claude-nono --login` no longer passes `--allow-cwd`. The parent `agent-base` profile denied `security` with an explicit deny, which a child profile cannot override.

## 2026-10-13

- claude: Retargeted the `update-context`/`c` skills to the dotfiles layout (AGENTS.md, skills, hooks/settings, and nono profiles). Dropped the `.agents/` and `rules/` targets, the stale commit-signing example, and AskUserQuestion.
- claude: Condensed `AGENTS.md` from about 1.4k to about 330 words. Dropped the rules that nono made stale: commit signing, `git -C`, https push, and Claude sandbox notes. Also dropped rules that point to missing skills and removed the `.agents/` includes. Moved the macOS defaults guidance to the `macos-defaults` skill.
- claude: Absorbed `~/code/claudie`, which is deprecated.
- claude: `claude/` now holds `settings.json`, `AGENTS.md` (linked as `~/.claude/CLAUDE.md`), `mcp.json`, hooks, and the statusline and MCP wrapper scripts. It also holds `omai/`, the auto-memory directory, and the skills `pr`, `francais`, `anki`, `update-context`, `c`, and `note`.
- claude: `claude/deploy.sh` (run by `install.sh`) links them into `~/.claude` and prunes old claudie skill links. The `sandbox` block in `settings.json` and its `enforce-sandbox-on-tools` and `block-settings-edit` hooks are gone, because nono enforces the filesystem. Repointed the nono profiles and the `claude-nono` omai path. Removed the `cl` and `cj` safehouse aliases.
- nono: `claude-nono --allow-dir=PATH` (repeatable) grants read-write to PATH (`nono --allow`) and passes `claude --add-dir PATH`.
- nono: `nonop <name>` (`nono/nonop`) promotes `~/.config/nono/profile-drafts/<name>.jsonc` into `nono/profiles/` (`nono profile promote` reads only `.json`). It makes sure that the `.base` hash matches and that the profile is valid. It shows the diff, then asks you to approve it.
- nono: `agent-base` mediates `git`. The session is still denied `.git/config` and hooks. Mediated git gets write access to the repo and a list of allowed subcommands. It cannot run `config`, use global options, or use `--output`, `--exec`, `--upload-pack`, or `--template`. Mediated git can call `gpg` for signing. The gpg profile gets read access to `@git:toplevel`, so `getcwd` works. `user.signingkey` is overridden to the `~/.gnupg-claude` key. The command-level `GNUPGHOME` is absolute, because command `set_vars` do not expand `$HOME`. Git env overrides (gh credential helper, https insteadOf, gpg signing) now live in the git command sandbox. They no longer live in the session env, which does not reach command sandboxes.
- nono: `claude-nono --login` runs `claude auth login` under the new `claude-login` profile. It then starts the normal session. The profile extends `claude-sandboxed` and adds `listen_port_range` 49152–65535 for the OAuth callback, `interactive`, and `--allow-launch-services`. Normal sessions get no listen ports or browser opens. `oauth_capture` keeps real tokens on the host side. Phantoms in `~/.claude` keep later sessions logged in and able to refresh tokens.

## 2026-10-12

- nono: Added `nono/claude-nokeychain.sh`. It generates `nono/profiles/claude-nokeychain.json`, a jq copy of the `nolabs-ai/claude` pack profile without its `~/Library/Keychains` allow and `bypass_protection`. Child profiles cannot remove inherited bypasses, so the copy is needed. `claude-sandboxed` and `claude-directory` now extend it. `nono/install.sh` runs the script. Re-run it after `nono update`. If nono is already present, `install.sh` skips `brew install nono`.
- nono: removed `$HOME/code/*-worktrees` glob from `agent-extended` (globs hang nono 0.79). `cln` now grants access per repo. If `<repo>-worktrees` exists, it adds `--allow <repo>-worktrees`. If it runs in a worktree, it adds `--allow <main repo>`. If the repo is under `~/code/ct`, it adds `--read ~/code/ct` automatically. The `--ct` flag is removed.
- nono: `claude-nokeychain.sh` now adds an `oauth_capture` credential provider (`claude_code`) and an `anthropic_oauth` route. Claude Code's OAuth token reaches `api.anthropic.com` through nono's proxy. The sandbox sees only a phantom token.

## 2026-10-08

- Added `nono/profiles/` (`agent-base`, `claude-sandboxed`). This is a nono port of claudie's `claude-sandboxed` safehouse profiles and the `claude-netproxy` domain allowlist. `nono/install.sh` pulls the `nolabs-ai/claude` and `nolabs-ai/opencode` packs. It also symlinks the profiles into `~/.config/nono/profiles`.
- nono: `gpg` is now a mediated command. Only the argv for git signing and signature reading is allowed, and the session can no longer read `~/.gnupg-claude`. It replaces `gpg-claude-wrap.sh`. It also adds rollback exclusions and `nono/config.toml`, which sets rollback retention. The `nono/claude-nono` wrapper (`cln`) supports these flags: `--rollback`, `--online`, the omai env (`--no-omai`), `--directory-only` (profile `claude-directory`), `--playwright`, and `--ct`. MCP is disabled by default through `nono/disable-all-mcp.sh`, copied from claudie. The profiles now split into `agent-base` (essentials) and `agent-extended` (broader access). `claude-sandboxed` extends `nolabs-ai/claude`.
- nono: `claude-nono` passes `--trust-proxy-ca` so Go CLIs (`gh`) trust nono proxy CA.

## 2026-10-02

- Added `amphetamine/install.sh`. It installs Amphetamine from the Mac App Store with `mas` (app ID `937984704`).

## 2026-10-01

- Added `lute/lute-import-podcast FEED_URL [TAG]`. It imports a podcast's `<podcast:transcript>` HTML transcripts into a running Lute as books, oldest first, through Lute's `/book/new` form. It skips episodes already in Lute, so running it again only adds new ones.
- `lute-import-podcast` attaches each episode's `<enclosure>` audio. Existing unarchived books without audio get the audio added through Lute's edit form.
- `lute-import-podcast` takes an optional `TRANSCRIPTS_JSON` argument (`{episode <link>: transcript}`). Use it for feeds without `<podcast:transcript>`, for example innerFrench. Their transcripts sit behind Cloudflare, so you must fetch them from a logged-in browser.
- `lute-import-podcast` downloads files and posts them to Lute with `curl`. GETs retry 3 times, with a 10 minute cap. It aborts a transfer that runs under 1 KB/s for 60 seconds. urllib hung for hours on a stalled Podbean download and on posting a 150 MB episode. The script dropped the hand-rolled multipart encoder.
- If its size matches the feed's `<enclosure length>`, `lute-import-podcast` reuses audio already in `useraudio/`. This also covers files that an iCloud rollback of the DB orphaned. The script skips the download for these files.
- `lute-prune-audio [-n] [DIR...]` also prunes extra audio directories. Audio moved out of Lute's iCloud `useraudio/` and linked by absolute path, for example from `~/Documents/inner-french`, lives in extra directories.
- Added `lute/lute-prune-audio [-n]`. It unlinks audio from archived books. Then it deletes `useraudio/` files that no book references. Lute never deletes audio, even for deleted books. `-n` is a dry run.

## 2026-09-30

- Added `lute/dicts.sh`. If the reader-dict fr-en and fr-fr (no-etymology) `.df` dictionaries are missing from `~/Documents/Dictionaries`, it downloads them there. `lute` runs it on every start.
- `lute` moved the fr-en dictionary server from `8765` to `8767`. `oktapus` already listens on 8765. The "already running?" curl check mistook that port for the dict server, so fr-en never started. The check is gone. A busy port now fails loudly instead.

## 2026-09-28

- Added `lute/dictserver.py`. It serves a reader-dict `.df` file over HTTP for Lute. `lute` starts one server per dictionary in the background. `dict-fr-en.df` runs on `localhost:8765`, and `dict-fr-fr.df` runs on `localhost:8766`. Both files come from `~/Documents/Dictionaries`. If a file is missing, `lute` warns with setup steps. When Lute exits, `lute` stops the servers it started.

## 2026-09-27

- If `~/.pyenv/shims` exists, `python/path.zsh` adds pyenv shims to `$PATH`. The `command not found: pyenv` error no longer appears at startup. It also no longer runs a `$(pyenv root)` subshell.

- `claude/install.sh` brew-installs `ccusage` for Claude Code usage reports.
- Added `go/install.sh`, which brew-installs the Go toolchain. The `go/` topic only set `$PATH` before, so `go` itself was never installed.
- `neovim/install.sh` installs JetBrains Mono Nerd Font. Without a Nerd Font, icons render as `?`.
- If `npm` is missing, `neovim/install.sh` runs `node/install.sh`. Mason needs npm for jsonls and eslint.
- Removed the `ghostty/` topic and its README/AGENTS.md references.
- Added `AGENTS.md`. It covers the repo goal, the topic layout and conventions, and rules for coding agents.
- Merged `CLAUDE.md` into `AGENTS.md`, which now holds the change checklist and performance testing. `CLAUDE.md` now only imports `@AGENTS.md` and `@README.md`.
- `git/gitconfig.symlink` moved `[include] ~/.gitconfig.local` to the end. Machine-local values, for example `commit.gpgsign = false`, now override the shared values.
- Added the `neovim/` topic. `install.sh` brew-installs neovim, ripgrep, and tree-sitter-cli. It symlinks `neovim/config` to `~/.config/nvim` and backs up an existing directory that is not a symlink. The Neovim files moved in from `~/.config/nvim`, which was formerly the `nvim-config` repo.

## 2026-07-02

- `node/aliases.zsh` silenced the startup `_fnm_autoswitch` call (`>/dev/null 2>&1`). It runs before the first prompt in repos with `.nvmrc`. fnm's "Using Node vX" output tripped Powerlevel10k's instant-prompt warning. The `chpwd` hook still prints on interactive `cd`.

## 2026-06-23

- `iterm/com.googlecode.iterm2.plist` changed the default Background Color from pure black to `#282c34` (R 0.157, G 0.173, B 0.204). The new color matches the lighter gray default of Ghostty.
- Added the `ghostty/` topic. It ports the Ghostty terminal setup from `iterm/`. It includes `config` (symlinked to `~/.config/ghostty/config`), `tab.zsh` (title hooks, gated on `$TERM_PROGRAM == ghostty`), `install.sh`, and `README.md`. The per-tab color and the shell-integration download did not port. Ghostty has no per-tab color escape, and it injects shell integration automatically.
- `ghostty/config` sets `shell-integration-features = no-title`, so Ghostty's built-in title feature does not overwrite the `tab.zsh` titles. It also raises `background-opacity` from 0.97 to 0.98.
- `ghostty/CLAUDE.md` explains how to search the Ghostty docs (`ghostty +show-config --default --docs | grep`, CLI actions, and offline bundle docs). ghostty.org returns 403 to automated fetchers.
- Added `ghostty/dump-docs.sh`. It generates a gitignored `ghostty/ghostty-docs.txt` offline dump. The dump holds the Ghostty reference, actions, keybinds, themes, and bundled markdown. The script finds `ghostty` on PATH or in the app bundle. `ghostty/.gitignore` ignores the dump file. `install.sh` runs the script on a best-effort basis. `CLAUDE.md` tells the agent to read the dump first. If the dump is more than 30 days old, the agent flags the user.
- `ghostty/install.sh` installs an idempotent (safe to run twice) daily cron job at 09:00 that runs `dump-docs.sh`. The dump refreshes each day, so it stays current after Ghostty upgrades. The README and `CLAUDE.md` were updated.
- `ghostty/tab.zsh` dropped the OSC 11 per-project background tint. Ghostty tab color (1.3.0) works only in the macOS UI. It has no escape sequence, no keybind, and no way to set it. OSC 11 sets one solid color with no gradient or top-fade option. So there is no good per-directory tab-color equivalent. The title hooks are unchanged.

## 2026-06-18

- `iterm/com.googlecode.iterm2.plist` changed Option+Left and Option+Right to send the escape sequences `[1;3D` and `[1;3C` for Neovim, instead of a word jump.
- `zsh/zshrc.symlink` adds a key binding that translates the escape sequences to word jumps.

## 2026-06-11

- `iterm/com.googlecode.iterm2.plist` enabled `Blinking Cursor`.

## 2026-06-10

- Added the `ct` function (`functions/ct`) and its completion (`functions/_ct`). It jumps to `$PROJECTS/ct/<tab>`, like `c` does.

## 2026-05-12

- Added the caveman install to `claude/install.sh` (https://github.com/JuliusBrussee/caveman).
- Removed the `jetbrains/datagrip` and `jetbrains/idea` launcher scripts. Regenerated `jetbrains/storm` from Toolbox.

## 2026-04-03

- Added `cj` alias for `claude-jailed` in `claude/alias.zsh`.

## 2026-03-24

- `gw main` now goes to the main worktree root (alias for `gw root`) instead of trying to create a worktree called "main".

## 2026-03-17

- Added `bin/iterm-open-nvim`. Cmd+click on file paths in iTerm2 opens them in nvim, through a new tmux session.
- Configured iTerm2 Semantic History in the plist to run `iterm-open-nvim` on file clicks.
- Restored agent-safehouse install/upgrade logic in `claude/install.sh`.

## 2026-03-13

- Added the `glogs` alias. It is the same as `glog`, but it shows the GPG signature status (for example `G` and `N`) after the commit hash. It stays separate from `glog`, because `%G?` runs GPG verification for each commit, which is slow.
- Added `git/README.md`. It documents the primary aliases, the `glogs` signature indicators, and the alias groups ported from OMZ.

## 2026-03-12

- Removed agent-safehouse. `cl` is now a plain alias for `claude`. The install script installs only Claude Code.
- `claude/alias.zsh` added `SAFEHOUSE_ADD_DIRS`. It grants Claude read and write access to `claudie`, `.dotfiles`, `.config/nvim`, `uaa-shared`, `notes`, and `tickets`.
- The safehouse install in `claude/install.sh` now checks the install. If safehouse is missing, the script installs it. If Homebrew manages it, the script upgrades it. If another method installed it, the script exits with an error.
- Added `claude/install.sh`. It installs `claude-code` and `agent-safehouse` with Homebrew.
- `cl` now wraps claude through `safehouse` (`cl() { safehouse claude "$@"; }`), not a plain alias.
- The `gco` prompt now offers `[r]emote fetch / [c]reate` in one prompt, not two y/n questions in sequence. If the remote fetch finds nothing, it then offers to create the branch.

## 2026-03-11

- Migrated iTerm2 preferences from Dropbox sync to the repo. The cleaned plist is stored at `iterm/com.googlecode.iterm2.plist`. The install script points iTerm's "custom folder" setting here, so UI changes write directly to the repo copy.
- Fixed smart truncation not persisting. The root cause was the Dropbox plist, which overwrote local preferences on every launch.
- Replaced `set-title-components.py`, which used the iTerm2 Python API, with a PlistBuddy command in `iterm/install.sh`. The command works outside of iTerm2.
- Configured `git difftool` to use `nvimdiff` with no prompt in `git/gitconfig.symlink`.

## 2026-03-10

- Added `iterm/tab.zsh`. It sets the tab title automatically to `repo...:branch (tool)`, or to `repo.../worktree:branch (tool)` for named worktrees. Each git root gets a deterministic tab color.
- Configured iTerm to show session name only in tab title (removes `(-zsh)` job suffix).

## 2026-03-09

- Added the `tmux/` topic. It sets up tmux with the `Ctrl+a` prefix. It adds tmux-easy-motion (label jumping, similar to flash.nvim) and tmux-thumbs (quick copy of URLs, paths, and SHAs). It also includes a Catppuccin status bar, the TPM plugin manager, vi copy mode, and shell aliases.

## 2026-03-07

- Added the `brave/` topic. It has an install script that installs Brave and `defaultbrowser`, which sets the default browser. It also has an extensions checklist.

## 2026-03-06

- Replaced NVM with fnm (Fast Node Manager). fnm removes the delay of about 1 second on each version switch. It switches versions on `cd` through `fnm env --use-on-cd`.
- When `gw <worktree>` changes directory, it now clears the terminal, as `gw <worktree> cli` does.
- `gw` skips the `gw-layout` Python overhead for zero or one tool. A single tool runs directly in the shell. `gw-layout` runs only for multi-pane splits.
- Rewrote the `gw` CLI. Tools are positional arguments (`cl`, `nvim`, `cli`) instead of `--flags`. Tools and the branch can come in any order.
- Moved the worktree location from `{repo}/worktrees/` to the sibling directory `{repo}-worktrees/`.
- Updated `gw-layout` ratios. `cl+cli` and `nvim+cli` now use an H-split (90/10) instead of a V-split. The file also has tunable constants at the top.
- Added `gw root`, which goes to the main worktree root. It takes optional tools but no branch.
- Updated the `_gw` completion for the new positional arguments, the sibling worktree directory, and the `root` keyword.
- `gco` now checks for remote tracking branches before it offers to create one. If local refs are stale, it fetches from the remote. It automatically checks out and tracks remote branches that exist.
- Added a Hammerspoon shortcut (`Ctrl+Alt+H`). It stretches the window to the full screen height and keeps the current width and position.
- Added the `magnet/` topic. It manages custom Magnet window layout overrides from the dotfiles. The `rightTwoThirds` layout uses about 80% of the width. The `iTerm` override is a custom command.

## 2026-03-05

### Fix `load-nvmrc` breaking on `cd` into `.nvmrc` projects

- Removed the conditional `$+functions` check. The code now calls `nvm --version` every time. The first call triggers the lazy stub. Later calls do nothing, because nvm is already loaded. This avoids all zsh parsing ambiguity.

### Switch default editor to Neovim

- Changed `EDITOR` from `code` to `nvim` in `system/env.zsh`
- Changed `KUBE_EDITOR` from `code -w` to `nvim` in `zsh/zshrc.symlink`

### Restore Ctrl+S forward history search

- Added `setopt NO_FLOW_CONTROL` to disable XON/XOFF flow control. It is a zsh builtin and needs no TTY. This avoids `stty` issues with the p10k instant prompt.
- Added `bindkey '^S' history-incremental-search-forward` to restore the forward incremental search that the OMZ removal had dropped.

## 2025-03-05

### ZSH Startup Performance Overhaul (~1.9s → <200ms)

#### Dropped Oh My Zsh as the shell loader

- OMZ sourced ~20 lib files, ran compfix, auto-update checks, `scutil`, `git rev-parse`, and its own `compinit` on every startup (~800ms)
- Replaced with direct sources for the 3 features we actually used: Powerlevel10k, NVM (lazy-loaded), and z
- OMZ is still installed (p10k, z, and kube-ps1 live under `~/.oh-my-zsh/`). It is not sourced.

#### Added zsh-defer for non-critical sources

- After the first prompt is drawn, syntax highlighting, gcloud completion, iTerm shell integration, and terraform bashcompinit load
- zsh-defer is cloned into `$ZSH/custom/plugins/` and sourced early via `zsh/oh-my-zsh.zsh`
- `zsh/oh-my-zsh.zsh` is explicitly sourced before the main topic loop to guarantee zsh-defer is available for all topic files, for example `iterm/`

#### NVM lazy loading

- Stub functions for `nvm`, `node`, `npm`, `npx`, `yarn`, `pnpx`, `corepack` defer sourcing `nvm.sh` (4387 lines) until first use
- The `chpwd` hook in `node/aliases.zsh` triggers lazy-load on first `cd` into an `.nvmrc` project

#### Cached compinit

- `compinit -C` skips security audit and fpath re-scan unless the dump is >24h old
- `.zcompdump` is compiled to `.zwc` in a background subshell for faster future loads
- Cleaned up 25 stale `~/.zcompdump-*` files

#### Removed dead code

- Deleted `ruby/rvm.zsh`, because RVM is not installed
- Removed the `hub` git wrapper from `git/aliases.zsh`. `hub` is not installed, and `gh` replaced it.
- Fixed `$(gls &>/dev/null)` subshell fork in `system/aliases.zsh` → `$+commands[gls]` hash lookup

#### kube-ps1 on-demand

- Type `kube-on` to load the Kubernetes context into the prompt. This avoids the cost of about 50 ms on every startup.

#### Added ZPROF profiling toggle

- `ZPROF=1 zsh -i -c exit` prints a function-level timing breakdown of startup

#### Cached Homebrew shellenv

- `brew shellenv` output cached in `zsh/zprofile.symlink` to avoid a subprocess fork on every login shell
