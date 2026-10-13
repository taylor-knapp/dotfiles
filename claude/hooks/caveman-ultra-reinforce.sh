#!/usr/bin/env bash
# UserPromptSubmit hook: when caveman flag == ultra, reinforce ultra mode.
# Every turn -> short reminder. Full abbreviation rules only if not injected
# in the last 10m (tracked per-session via a timestamp file in /tmp).
flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
[[ -f "$flag" ]] || exit 0
mode="$(tr -d '[:space:]' < "$flag")"
[[ "$mode" == "ultra" ]] || exit 0

input="$(cat)"
session="$(printf '%s' "$input" | node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{try{process.stdout.write((JSON.parse(s).session_id||"default"))}catch(e){process.stdout.write("default")}})')"

stamp="/tmp/claude-caveman-ultra-${session}.ts"
now=$(date +%s)
last=0
[[ -f "$stamp" ]] && last=$(cat "$stamp" 2>/dev/null || echo 0)

short="CAVEMAN ULTRA active. Keep ultra compression."
full="CAVEMAN ULTRA ENFORCEMENT. Abbreviate prose words (DB/auth/config/req/res/fn/impl). Strip conjunctions. Arrows for causality (X -> Y). One word when one word enough. Never abbreviate code symbols, function/API names, error strings. Code/commits/security: write normal."

if (( now - last > 600 )); then
  ctx="$full"
  echo "$now" > "$stamp"
else
  ctx="$short"
fi

CTX="$ctx" node -e '
  process.stdout.write(JSON.stringify({hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:process.env.CTX}}));'
