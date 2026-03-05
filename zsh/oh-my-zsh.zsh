# =============================================================================
# Direct shell setup — replaces Oh My Zsh
# =============================================================================
# OMZ sourced ~20 lib files (2588 lines), ran compfix.zsh, check_for_upgrade.sh,
# scutil --get ComputerName, git rev-parse HEAD, and its own compinit on every
# shell startup. This file replaces all of that with direct, minimal sources
# for just the features we actually use.
# =============================================================================

# Keep $ZSH set so p10k and z paths still resolve (they live under ~/.oh-my-zsh/)
export ZSH=$HOME/.oh-my-zsh

# ---------------------------------------------------------------------------
# Powerlevel10k prompt theme
# ---------------------------------------------------------------------------
# Sourced directly instead of going through OMZ's theme loader, which adds
# overhead scanning for theme files and running its own init sequence.
# p10k is installed as an OMZ custom theme (cloned into $ZSH/custom/themes/).
source ${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme

# ---------------------------------------------------------------------------
# NVM lazy loading
# ---------------------------------------------------------------------------
# Instead of sourcing nvm.sh eagerly (which parses 4387 lines and adds ~400ms),
# we create lightweight stub functions for common Node commands. The first time
# any of these commands is invoked, the stubs remove themselves, source nvm.sh
# once, then transparently forward the call. Subsequent calls go directly to
# the real binary with zero overhead.
export NVM_DIR="$HOME/.nvm"
if [[ -f "$NVM_DIR/nvm.sh" ]]; then
  function nvm node npm npx yarn pnpx corepack {
    # Remove all stub functions so they don't intercept future calls
    unfunction nvm node npm npx yarn pnpx corepack 2>/dev/null
    # Now source the real nvm — this only happens once per shell session
    source "$NVM_DIR/nvm.sh"
    # Forward the original command: if nvm defined it as a function, call
    # the function; otherwise fall back to the external command.
    if (( $+functions[$0] )); then
      "$0" "$@"
    else
      command "$0" "$@"
    fi
  }
fi

# ---------------------------------------------------------------------------
# z — directory jumping (frecency-based)
# ---------------------------------------------------------------------------
# z tracks your most-used directories and lets you jump to them with partial
# matches, e.g. `z proj` -> ~/code/project. Sourced from the OMZ bundled copy.
[[ -f $ZSH/plugins/z/z.sh ]] && source $ZSH/plugins/z/z.sh

# ---------------------------------------------------------------------------
# kube-ps1 — Kubernetes context in prompt (on-demand)
# ---------------------------------------------------------------------------
# kube-ps1 adds ~50ms by querying kubectl on every prompt. Load it only when
# needed by typing `kube-on`. To disable again, restart your shell.
alias kube-on='source $ZSH/plugins/kube-ps1/kube-ps1.plugin.zsh 2>/dev/null && PROMPT="\$(kube_ps1)$PROMPT"'
