# iTerm tab title + color — auto-updates based on cwd and running tool
#
# Title format (git, main wt):    tool: repo branch           — branch truncated if >30 chars
# Title format (git, named wt):   tool: repo/worktree branch  — branch truncated if >30 chars
# Title format (non-git):         tool: dirname
# Repo is always abbreviated to initials: agent-gateway-services → ags
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

# Abbreviate a name to its initials: agent-gateway-services → ags, audit-log → al
# No separators: first 5 chars (dotfiles → dotfi). Strips leading non-alnum chars.
_iterm_tab_initials() {
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

_iterm_tab_set_title() {
  local tool="${1:-cli}" title repo_abbr
  if [[ -n "$_iterm_tab_repo" ]]; then
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || branch="detached"
    repo_abbr=$(_iterm_tab_initials "$_iterm_tab_repo")

    # Build title with full repo name first
    if [[ "$_iterm_tab_wt_name" == "main" ]]; then
      title="${tool}: ${_iterm_tab_repo} ${branch}"
    else
      title="${tool}: ${_iterm_tab_repo}/${_iterm_tab_wt_name} ${branch}"
    fi

    # Abbreviate repo to initials only if title exceeds 30 chars
    if (( ${#title} > 30 )); then
      if [[ "$_iterm_tab_wt_name" == "main" ]]; then
        title="${tool}: ${repo_abbr} ${branch}"
      else
        title="${tool}: ${repo_abbr}/${_iterm_tab_wt_name} ${branch}"
      fi
    fi

    printf '\e]1;%s\a' "$title"
  else
    printf '\e]1;%s: %s\a' "$tool" "${PWD:t}"
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
