#!/usr/bin/env bash
#
# Claude Code SessionStart hook — auto-names the session "<repo>/<branch>" so
# Agent View rows show which repo and branch each session is working in.
#
# Fires on source=startup|resume (Claude Code ignores SessionStart output on
# clear/compact). Preserves any title the user already set via --name or /rename.
#
# Receives JSON on stdin:
#   { "hook_event_name": "SessionStart", "source": "startup", "session_title": "..." , "cwd": "..." }
# Emits JSON on stdout:
#   { "hookSpecificOutput": { "hookEventName": "SessionStart", "sessionTitle": "<repo>/<branch>" } }

set -euo pipefail

input=$(cat)

source_val=$(printf '%s' "$input" | jq -r '.source // ""')
existing_title=$(printf '%s' "$input" | jq -r '.session_title // ""')
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

# Only auto-title on fresh start or resume.
if [[ "$source_val" != "startup" && "$source_val" != "resume" ]]; then
  exit 0
fi

# Don't clobber a title the user set explicitly (--name / /rename).
if [[ -n "$existing_title" ]]; then
  exit 0
fi

# Resolve repo + branch from the session's cwd.
[[ -n "$cwd" ]] && cd "$cwd" 2>/dev/null || exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || true)" 2>/dev/null || true)

if [[ -z "$branch" || -z "$repo" ]]; then
  exit 0
fi

jq -n --arg title "$repo/$branch" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", sessionTitle: $title}}'
