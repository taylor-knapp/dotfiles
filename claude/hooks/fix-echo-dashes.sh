#!/usr/bin/env bash
#
# Claude Code PostToolUse hook — when a Bash command containing echo "---"
# fails, tell the agent to use echo --- (unquoted) instead.
#
# Receives JSON on stdin:
#   { "tool_name": "Bash", "tool_input": { "command": "..." }, "tool_response": { "exitCode": N, ... } }

set -euo pipefail

input=$(cat)

tool_name=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))")

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

command=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))")
exit_code=$(echo "$input" | python3 -c "import sys,json; r=json.load(sys.stdin).get('tool_response',{}); print(r if isinstance(r,int) else r.get('exitCode',0))" 2>/dev/null || echo "0")

if [[ "$exit_code" != "0" ]] && echo "$command" | grep -qF 'echo "---"'; then
  echo 'The command failed because echo "---" can cause issues. Use echo --- (without quotes around ---) instead.'
  exit 2
fi
