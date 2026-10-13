#!/usr/bin/env bash
#
# Claude Code WorktreeCreate hook.
# https://code.claude.com/docs/en/hooks#worktreecreate
#
# Overrides Claude Code's default worktree location (.claude/worktrees/) and
# instead creates worktrees as siblings of the repo, in the pattern:
#
#     <repo>-worktrees/<branch>
#
# e.g. /Users/me/code/claudie  ->  /Users/me/code/claudie-worktrees/<branch>
#
# After creating the worktree it symlinks shared, gitignored local files
# (local config/secrets) into it via scripts/link-worktree-files.sh.
#
# Contract:
#   * Reads a JSON object on stdin with base_directory, branch_name, worktree_id.
#   * On success: prints the absolute worktree path to STDOUT and exits 0.
#   * Any non-zero exit aborts worktree creation.
#   * Everything except the final path goes to STDERR so stdout stays clean.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK_SCRIPT="$HERE/../scripts/link-worktree-files.sh"

# ── Parse stdin ──────────────────────────────────────────────────
input=$(cat)

# Claude Code renamed these keys across versions: base_directory->cwd,
# branch_name->name, and dropped worktree_id. `//` falls back old->new.
base_directory=$(jq -r '.base_directory // .cwd // ""' <<<"$input")
branch_name=$(jq -r '.branch_name // .name // ""' <<<"$input")
worktree_id=$(jq -r '.worktree_id // ""' <<<"$input")

if [[ -z "$base_directory" || -z "$branch_name" ]]; then
  echo "WorktreeCreate: missing base_directory or branch_name in hook input." >&2
  exit 1
fi

# ── Resolve the MAIN worktree root ───────────────────────────────
# base_directory may be the repo root or a linked worktree; --git-common-dir
# always points at the main .git, whose parent is the main worktree.
common=$(git -C "$base_directory" rev-parse --git-common-dir)
case "$common" in
  /*) ;;
  *) common="$base_directory/$common" ;;
esac
main_worktree=$(cd "$common/.." && pwd)

# ── Compute the target path: <repo>-worktrees/<branch> ───────────
worktrees_dir="${main_worktree}-worktrees"
safe_branch="${branch_name//\//-}"          # feature/foo -> feature-foo
target="$worktrees_dir/$safe_branch"

# Avoid clobbering an existing path: disambiguate with the worktree id.
if [[ -e "$target" && -n "$worktree_id" ]]; then
  target="$worktrees_dir/${safe_branch}-${worktree_id}"
fi

# ── Guard: never create under .claude/worktrees/ ─────────────────
# That is Claude Code's DEFAULT (fallback) worktree location. A target
# landing there means this hook was bypassed and creation fell back to
# manual/default behavior — which is explicitly forbidden. Fail loudly so
# the agent debugs this hook WITH the user instead of silently falling back.
case "/$target/" in
  */.claude/worktrees/*)
    echo "WorktreeCreate: REFUSING — target '$target' is under .claude/worktrees/ (Claude Code's default fallback)." >&2
    echo "WorktreeCreate: a worktree here means hook-based creation is broken and something fell back to manual creation." >&2
    echo "WorktreeCreate: do NOT create worktrees manually. Debug why this hook produced that path with the user, then retry." >&2
    exit 1
    ;;
esac

mkdir -p "$worktrees_dir"

# ── Create the worktree ──────────────────────────────────────────
# Reuse the branch if it already exists, otherwise create it.
if git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch_name"; then
  git -C "$main_worktree" worktree add "$target" "$branch_name" >&2
else
  git -C "$main_worktree" worktree add -b "$branch_name" "$target" >&2
fi

# ── Link shared gitignored local files into the new worktree ─────
# Non-fatal: the worktree already exists, so a link failure must not abort.
if [[ -f "$LINK_SCRIPT" ]]; then
  bash "$LINK_SCRIPT" "$target" >&2 || \
    echo "WorktreeCreate: link-worktree-files.sh failed (worktree still created)." >&2
fi

# ── Return the path (stdout only) ────────────────────────────────
echo "$target"
