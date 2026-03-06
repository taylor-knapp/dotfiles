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
# zsh-defer — deferred source loading
# ---------------------------------------------------------------------------
# zsh-defer queues commands to run after the prompt is first drawn, so they
# don't block interactive startup. Used below and in zshrc.symlink to defer
# syntax highlighting, gcloud completions, iterm integration, and terraform.
# https://github.com/romkatv/zsh-defer
source ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh

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
