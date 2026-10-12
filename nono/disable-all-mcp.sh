#!/usr/bin/env bash
#
# Disable every MCP server by default for a project.
#
# Invoked by nono/claude-nono (copied from claudie hooks/) BEFORE `claude` launches (NOT a hook):
# MCP servers connect at startup before SessionStart hooks fire, so a hook
# write lands too late. The wrapper runs first, outside the sandbox, so the
# disable list is in place when claude reads ~/.claude.json.
#
# Writes the full list of configured user-scope MCP servers (the `mcpServers`
# keys in ~/.claude.json) into the target project's `disabledMcpServers` array.
# Result: servers start disabled; enable one for the session via /mcp. The
# choice does NOT persist — next launch re-disables everything.
#
# `disabledMcpServers` (per-project, in ~/.claude.json) is the only key that
# disables user-scope servers. `disabledMcpjsonServers` only affects .mcp.json
# project servers, so it is NOT used here.
#
# Receives JSON on stdin: { "cwd": "...", ... }

set -euo pipefail

input=$(cat)

CLAUDE_JSON="$HOME/.claude.json"
[[ -f "$CLAUDE_JSON" ]] || exit 0

CLAUDE_JSON="$CLAUDE_JSON" HOOK_INPUT="$input" python3 - <<'PY'
import json, os, sys, tempfile

path = os.environ["CLAUDE_JSON"]

try:
    cwd = json.loads(os.environ.get("HOOK_INPUT") or "{}").get("cwd")
except json.JSONDecodeError:
    cwd = None
cwd = cwd or os.getcwd()

with open(path) as f:
    data = json.load(f)

names = sorted((data.get("mcpServers") or {}).keys())
if not names:
    sys.exit(0)

proj = data.setdefault("projects", {}).setdefault(cwd, {})
if proj.get("disabledMcpServers") == names:
    sys.exit(0)  # already in desired state, skip write
proj["disabledMcpServers"] = names

# Atomic write in the same dir so os.replace stays on one filesystem.
d = os.path.dirname(path)
fd, tmp = tempfile.mkstemp(dir=d, prefix=".claude.json.", suffix=".tmp")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
except BaseException:
    os.path.exists(tmp) and os.unlink(tmp)
    raise

print(f"MCP: disabled {len(names)} server(s) by default for this session", file=sys.stderr)
PY
