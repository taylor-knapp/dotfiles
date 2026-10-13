#!/usr/bin/env bash
#
# Symlink shared, gitignored local files from the MAIN worktree into other
# worktrees, so each worktree reuses local config/secrets instead of
# recreating them. Dependency and build dirs (node_modules/, .pnpm-store/,
# compiled binaries) are intentionally NOT linked — each worktree owns its own.
#
# Items are discovered dynamically with `git ls-files --ignored` rather than
# hardcoded, so newly-ignored files get linked automatically.
#
# Usage:
#   link-worktree-files.sh                 # link into ALL worktrees except main
#   link-worktree-files.sh <worktree-path> # link into a single worktree (used by
#                                           # the WorktreeCreate hook)

set -euo pipefail

# ── Colors & Symbols ──────────────────────────────────────────────
bold="\033[1m"
dim="\033[2m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
red="\033[31m"
reset="\033[0m"

sym_ok="${green}✓${reset}"
sym_link="${cyan}→${reset}"
sym_skip="${yellow}–${reset}"
sym_err="${red}✗${reset}"

# Entries whose basename matches these are dependency/build dirs — never linked.
SKIP_NAMES=(node_modules .pnpm-store .turbo .next dist build out target coverage vendor)

# ── Resolve main worktree ────────────────────────────────────────
# Reference point: explicit target arg if given, else cwd. From there,
# --git-common-dir points at the MAIN repo's .git regardless of which
# worktree we start in; its parent is the main worktree.
ref="${1:-$PWD}"
common=$(git -C "$ref" rev-parse --git-common-dir)
case "$common" in
  /*) ;;                      # already absolute
  *) common="$ref/$common" ;; # relative to ref
esac
main_worktree=$(cd "$common/.." && pwd)

# ── Gather target worktrees ──────────────────────────────────────
targets=()
if [[ $# -ge 1 ]]; then
  # Single explicit target (the freshly-created worktree).
  targets+=("$(cd "$1" && pwd)")
else
  # Every worktree except main.
  while IFS= read -r line; do
    wt_path=$(echo "$line" | awk '{print $1}')
    [[ "$wt_path" == "$main_worktree" ]] && continue
    targets+=("$wt_path")
  done < <(git -C "$main_worktree" worktree list)
fi

if [[ ${#targets[@]} -eq 0 ]]; then
  echo -e "${dim}No worktrees to link besides main — nothing to do.${reset}"
  exit 0
fi

# ── Discover gitignored items in main, then filter ───────────────
# --directory collapses fully-ignored dirs to a single entry (node_modules/
# instead of every file inside); individual ignored files are listed as-is.
items=()
while IFS= read -r item; do
  [[ -z "$item" ]] && continue
  clean="${item%/}"                # strip trailing slash from dir entries
  base="${clean##*/}"              # basename

  skip=0
  for n in "${SKIP_NAMES[@]}"; do
    [[ "$base" == "$n" ]] && { skip=1; break; }
  done
  [[ $skip -eq 1 ]] && continue

  # Skip compiled binaries: regular file that is executable.
  src="$main_worktree/$clean"
  if [[ -f "$src" && -x "$src" ]]; then
    continue
  fi

  items+=("$clean")
done < <(git -C "$main_worktree" ls-files --others --ignored --exclude-standard --directory --no-empty-directory)

if [[ ${#items[@]} -eq 0 ]]; then
  echo -e "${dim}No linkable gitignored items in main — nothing to do.${reset}"
  exit 0
fi

echo -e "${bold}Linking worktrees${reset}"
echo -e "${dim}main: ${main_worktree}${reset}"
echo ""

# ── Link one item from main into a target worktree ───────────────
link_item() {
  local item="$1" target="$2"
  local src="$main_worktree/$item"
  local dest="$target/$item"

  if [[ ! -e "$src" ]]; then
    echo -e "  ${sym_skip} ${dim}${item}${reset} ${dim}(not in main)${reset}"
    return
  fi

  if [[ -L "$dest" ]]; then
    echo -e "  ${sym_ok} ${item}"
    return
  fi

  if [[ -e "$dest" ]]; then
    echo -e "  ${sym_err} ${item} ${dim}(exists, not a symlink — left alone)${reset}"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo -e "  ${sym_link} ${item} ${dim}linked${reset}"
}

# ── Process each target worktree ─────────────────────────────────
for wt in "${targets[@]}"; do
  branch=$(git -C "$main_worktree" worktree list | grep "^$wt " | sed 's/.*\[//;s/\]//' || true)
  echo -e "${bold}${wt}${reset} ${dim}[${branch}]${reset}"
  for item in "${items[@]}"; do
    link_item "$item" "$wt"
  done
  echo ""
done

echo -e "${dim}Done.${reset}"
