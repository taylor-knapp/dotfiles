#!/usr/bin/env bash
#
# Claude Code PreToolUse hook — blocks directory-switching patterns in Bash commands.
#
# Catches: cd, pushd, popd
# The agent should always operate in the current working directory.
#
# Receives JSON on stdin:
#   { "tool_name": "Bash", "tool_input": { "command": "..." } }

set -euo pipefail

input=$(cat)

command=$(printf '%s' "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))")

if echo "$command" | grep -qE '(^|\s|;|&&|\|\|)\s*(cd|pushd|popd)\s'; then
  echo "BLOCKED: Do not switch directories with cd/pushd/popd. Use absolute paths or run commands from the current working directory." >&2
  exit 2
fi

exit 0
