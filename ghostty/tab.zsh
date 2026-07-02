# Ghostty tab title — auto-updates based on cwd and running tool.
# Ported from iterm/tab.zsh.
#
# Title format (git, main wt):    tool: repo branch           — repo abbreviated if >30 chars
# Title format (git, named wt):   tool: repo/worktree branch
# Title format (non-git):         tool: dirname
# Tool: claude, nvim, or cli (default shell prompt)
#
# NOTE: iTerm's per-tab background color (the deterministic hash color) is NOT
# ported — Ghostty has no per-tab color escape sequence. Only the title ports.
#
# Claude Code overrides the title by default. Disable with:
#   "env": { "CLAUDE_CODE_DISABLE_TERMINAL_TITLE": "1" }
# in ~/.claude/settings.json.

[[ "$TERM_PROGRAM" == "ghostty" ]] || return 0

typeset -g _ghostty_tab_last_dir=""
typeset -g _ghostty_tab_repo=""
typeset -g _ghostty_tab_wt_name=""

# Refresh cached repo/worktree info (runs on directory change only)
_ghostty_tab_refresh() {
  local toplevel main_root

  toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$toplevel" ]]; then
    main_root=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //')
    _ghostty_tab_repo="${main_root:t}"
    if [[ "$toplevel" == "$main_root" ]]; then
      _ghostty_tab_wt_name="main"
    else
      _ghostty_tab_wt_name="${toplevel:t}"
    fi
  else
    _ghostty_tab_repo=""
    _ghostty_tab_wt_name=""
  fi
}

# Abbreviate a name to its initials: agent-gateway-services → ags, audit-log → al
# No separators: first 5 chars (dotfiles → dotfi). Strips leading non-alnum chars.
_ghostty_tab_initials() {
  setopt localoptions extended_glob
  local name="${1##[^a-zA-Z0-9]##}" result=""
  if [[ "$name" != *[-_]* ]]; then
    echo "${name[1,5]}"
    return
  fi
  local -a words=("${(@s/ /)${name//[-_]/ }}")
  for w in "${words[@]}"; do
    [[ -n "$w" ]] && result+="${w[1]}"
  done
  echo "$result"
}

_ghostty_tab_set_title() {
  local tool="${1:-cli}" title repo_abbr
  if [[ -n "$_ghostty_tab_repo" ]]; then
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch="detached"
    repo_abbr=$(_ghostty_tab_initials "$_ghostty_tab_repo")

    # Build title with full repo name first
    if [[ "$_ghostty_tab_wt_name" == "main" ]]; then
      title="${tool}: ${_ghostty_tab_repo} ${branch}"
    else
      title="${tool}: ${_ghostty_tab_repo}/${_ghostty_tab_wt_name} ${branch}"
    fi

    # Abbreviate repo to initials only if title exceeds 30 chars
    if (( ${#title} > 30 )); then
      if [[ "$_ghostty_tab_wt_name" == "main" ]]; then
        title="${tool}: ${repo_abbr} ${branch}"
      else
        title="${tool}: ${repo_abbr}/${_ghostty_tab_wt_name} ${branch}"
      fi
    fi

    printf '\e]0;%s\a' "$title"
  else
    printf '\e]0;%s: %s\a' "$tool" "${PWD:t}"
  fi
}

_ghostty_tab_precmd() {
  if [[ "$PWD" != "$_ghostty_tab_last_dir" ]]; then
    _ghostty_tab_last_dir="$PWD"
    _ghostty_tab_refresh
  fi
  _ghostty_tab_set_title "cli"
}

_ghostty_tab_preexec() {
  local cmd="${1%% *}"
  case "$cmd" in
    claude|cl|cj) _ghostty_tab_set_title "claude" ;;
    nvim|vim)  _ghostty_tab_set_title "nvim" ;;
  esac
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _ghostty_tab_precmd
add-zsh-hook preexec _ghostty_tab_preexec
