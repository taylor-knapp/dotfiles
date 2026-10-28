#!/bin/sh
# Generate nono/profiles/claude-nokeychain.jsonc from the nolabs-ai/claude
# pack profile, minus its ~/Library/Keychains allow + bypass_protection.
# Re-run after `nono update`.
set -e
pack="$HOME/.config/nono/packages/nolabs-ai/claude"
out="$HOME/.dotfiles/nono/profiles/claude-nokeychain.jsonc"
jq --arg pack "$pack" '
  def nokc: map(select((.path? // .) != "$HOME/Library/Keychains"));
  {"$schema": "../profile.schema.json"} + .
  | .meta.name = "claude-nokeychain"
  | .meta.description = "nolabs-ai/claude, but without Keychain access (generated)"
  | del(.allow_launch_services, .rollback, .filesystem.bypass_protection)
  | .filesystem.allow |= nokc
  | .filesystem.suppress_save_prompt |= ["$HOME/Library/Keychains"]
  | .session_hooks.before.script |= sub("\\$PACK_DIR"; $pack)
  | del(.credential_providers, .credential_routes)
' "$pack/profiles/claude.json" > "$out"
