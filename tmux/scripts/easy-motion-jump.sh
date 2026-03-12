#!/usr/bin/env bash
# Wrapper for root-table easy-motion binding.
# Gets the server PID from $TMUX at runtime (the plugin bakes it at init time,
# but root-table bindings need it resolved per-invocation).

SCRIPTS_DIR="$HOME/.tmux/plugins/tmux-easy-motion/scripts"
SERVER_PID="$(echo "$TMUX" | cut -d, -f2)"

exec "$SCRIPTS_DIR/easy_motion.sh" "$SERVER_PID" "$@"
