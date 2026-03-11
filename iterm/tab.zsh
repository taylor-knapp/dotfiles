# iTerm tab title + color — auto-updates based on cwd and running tool
#
# Title format (git, main wt):    repo:branch (tool)          — truncated to repo*:branch* (tool) if >30 chars
# Title format (git, named wt):   repo/worktree:branch (tool) — truncated to repo*/wt:branch* (tool) if >30 chars
# Title format (non-git):         dirname (tool)
#
# Requires iTerm profile "Title Components" = Session Name only (no Job).
# Set via install.sh or: Profile > General > Title > Session Name
#
# Claude Code overrides the tab title by default. Disable with:
#   "env": { "CLAUDE_CODE_DISABLE_TERMINAL_TITLE": "1" }
# in your user-level Claude settings (~/.claude/settings.json).
# Color: deterministic per git-root (or $PWD outside git)
# Tool: claude, nvim, or cli (default shell prompt)

[[ "$TERM_PROGRAM" == "iTerm.app" ]] || return 0

typeset -g _iterm_tab_last_dir=""
typeset -g _iterm_tab_repo=""
typeset -g _iterm_tab_wt_name=""
typeset -g _iterm_tab_color_r=""
typeset -g _iterm_tab_color_g=""
typeset -g _iterm_tab_color_b=""

# Compute deterministic RGB from a directory path (no forks — pure zsh arithmetic)
_iterm_tab_hash_color() {
  local dir="$1" hash=5381 i char_val
  for (( i = 1; i <= ${#dir}; i++ )); do
    printf -v char_val '%d' "'${dir[$i]}"
    hash=$(( (hash * 33 + char_val) & 0x7FFFFFFF ))
  done
  # Constrain to 60-210 range so colors are visible on both light/dark themes
  _iterm_tab_color_r=$(( hash % 150 + 60 ))
  _iterm_tab_color_g=$(( (hash / 150) % 150 + 60 ))
  _iterm_tab_color_b=$(( (hash / 22500) % 150 + 60 ))
}

# Refresh cached repo/worktree info and tab color (runs on directory change only)
_iterm_tab_refresh() {
  local toplevel main_root color_key

  toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -n "$toplevel" ]]; then
    main_root=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //')
    _iterm_tab_repo="${main_root:t}"
    if [[ "$toplevel" == "$main_root" ]]; then
      _iterm_tab_wt_name="main"
    else
      _iterm_tab_wt_name="${toplevel:t}"
    fi
    color_key="$toplevel"
  else
    _iterm_tab_repo=""
    _iterm_tab_wt_name=""
    color_key="$PWD"
  fi

  _iterm_tab_hash_color "$color_key"
  printf '\e]6;1;bg;red;brightness;%d\a' "$_iterm_tab_color_r"
  printf '\e]6;1;bg;green;brightness;%d\a' "$_iterm_tab_color_g"
  printf '\e]6;1;bg;blue;brightness;%d\a' "$_iterm_tab_color_b"
}

_iterm_tab_set_title() {
  local tool="${1:-cli}" title repo_display
  if [[ -n "$_iterm_tab_repo" ]]; then
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch="detached"

    # Build full title first to check length
    if [[ "$_iterm_tab_wt_name" == "main" ]]; then
      title="${_iterm_tab_repo}:${branch} (${tool})"
    else
      title="${_iterm_tab_repo}/${_iterm_tab_wt_name}:${branch} (${tool})"
    fi

    # Truncate repo then branch if total title exceeds 30 chars
    if (( ${#title} > 30 )); then
      repo_display="${_iterm_tab_repo[1,6]}"
      repo_display="${repo_display%[-_]}"  # strip trailing - or _
      repo_display="${repo_display%[-_]}"
      repo_display="${repo_display}*"
      if [[ "$_iterm_tab_wt_name" == "main" ]]; then
        title="${repo_display}:${branch} (${tool})"
      else
        title="${repo_display}/${_iterm_tab_wt_name}:${branch} (${tool})"
      fi
    fi
    # Still over? Truncate branch to fit within 30 chars
    if (( ${#title} > 30 )); then
      local prefix suffix branch_max trunc_branch
      if [[ "$_iterm_tab_wt_name" == "main" ]]; then
        prefix="${repo_display}:"
      else
        prefix="${repo_display}/${_iterm_tab_wt_name}:"
      fi
      suffix=" (${tool})"
      branch_max=$(( 30 - ${#prefix} - ${#suffix} ))  # * appended after
      if (( branch_max < 4 )); then branch_max=4; fi
      trunc_branch="${branch[1,$branch_max]}"
      trunc_branch="${trunc_branch%[-_]}"
      trunc_branch="${trunc_branch%[-_]}"
      title="${prefix}${trunc_branch}*${suffix}"
    fi

    printf '\e]1;%s\a' "$title"
  else
    printf '\e]1;%s (%s)\a' "${PWD:t}" "$tool"
  fi
}

_iterm_tab_precmd() {
  if [[ "$PWD" != "$_iterm_tab_last_dir" ]]; then
    _iterm_tab_last_dir="$PWD"
    _iterm_tab_refresh
  fi
  _iterm_tab_set_title "cli"
}

_iterm_tab_preexec() {
  local cmd="${1%% *}"
  case "$cmd" in
    claude|cl) _iterm_tab_set_title "claude" ;;
    nvim|vim)  _iterm_tab_set_title "nvim" ;;
  esac
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _iterm_tab_precmd
add-zsh-hook preexec _iterm_tab_preexec
