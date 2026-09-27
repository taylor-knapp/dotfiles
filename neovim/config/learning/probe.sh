#!/usr/bin/env bash
# Feed raw bytes to Neovim's terminal input parser and print what it decoded.
#
#   ./probe.sh 1b 5b 31 3b 39 44        # ESC [ 1;9 D  -> <D-Left>
#   ./probe.sh 1b 5b 39 37 3b 39 75     # ESC [ 97;9 u -> <D-a>
#
# Separate multiple keypresses with the literal word 'then':
#   ./probe.sh 01 then 05               # -> <C-A> | <C-E>
#
# CAVEAT: this Neovim runs inside tmux with no real terminal answering its kitty
# protocol query, so negotiation never completes. Results prove what Neovim's parser
# ACCEPTS, not what iTerm2 SENDS. For end-to-end truth use, in a real iTerm2 window:
#   :lua vim.on_key(function(k) vim.notify(vim.fn.keytrans(k)) end)
#
# Requires tmux (used only as a byte injector, not as part of your normal setup).

set -euo pipefail

[ $# -eq 0 ] && { sed -n '2,16p' "$0"; exit 1; }
command -v tmux >/dev/null || { echo "probe.sh needs tmux (as a byte injector)"; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(mktemp -t nvim-probe)"
WIN="probe-$$"

tmux new-session -d -s "$WIN" \
  "NVIM_PROBE_OUT=$OUT nvim --clean -u $DIR/probe.lua"
sleep 1

group=()
flush() {
  [ ${#group[@]} -eq 0 ] && return
  tmux send-keys -t "$WIN" -H "${group[@]}"
  sleep 0.2
  group=()
}

for tok in "$@"; do
  if [ "$tok" = "then" ]; then flush; else group+=("$tok"); fi
done
flush

sleep 3
echo "decoded: $(cat "$OUT")"

tmux kill-session -t "$WIN" 2>/dev/null || true
rm -f "$OUT"
