#!/bin/bash
# SessionStart hook. Injects every rtk subcommand from `rtk --help` into session context.
# Stdout is the injection channel, so keep messages on stdout here.

command -v rtk >/dev/null 2>&1 || exit 0

help_text=$(rtk --help 2>/dev/null) || exit 0
# Meta and admin subcommands that agents do not wrap.
skip="help init gain config pipeline methods plugins tasks cc-economics discover session telemetry llm-proxy learn trust untrust verify hook hook-audit rewrite recall pipe"

commands=$(printf '%s\n' "$help_text" | awk -v skip="$skip" '
  BEGIN { n = split(skip, a, " "); for (i = 1; i <= n; i++) s[a[i]] = 1 }
  /^Commands:/ { f = 1; next }
  /^Options:/ { f = 0 }
  f && NF && !($1 in s) { print $1 }
')

[ -z "$commands" ] && exit 0

wrapped=$(printf '%s\n' "$commands" | paste -sd, - | sed 's/,/, /g')

echo "Prefix each of these commands with rtk instead of running them directly: $wrapped"
