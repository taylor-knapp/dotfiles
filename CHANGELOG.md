# Changelog

## 2025-03-05

### ZSH Startup Performance Overhaul (~1.9s → <200ms)

#### Dropped Oh My Zsh as the shell loader
- OMZ sourced ~20 lib files, ran compfix, auto-update checks, `scutil`, `git rev-parse`, and its own `compinit` on every startup (~800ms)
- Replaced with direct sources for the 3 features we actually used: Powerlevel10k, NVM (lazy-loaded), and z
- OMZ is still *installed* (p10k, z, kube-ps1 live under `~/.oh-my-zsh/`) — just not *sourced*

#### Added zsh-defer for non-critical sources
- Syntax highlighting, gcloud completion, iTerm shell integration, and terraform bashcompinit now load *after* the first prompt is drawn
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
