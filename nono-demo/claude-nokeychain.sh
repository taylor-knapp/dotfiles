#!/bin/sh
# Prints the nolabs-ai/claude pack profile as JSON on stdout, minus its ~/Library/Keychains
# allow + bypass_protection. 
set -e
nono profile show nolabs-ai/claude --json | jq '
  def nokc: map(select((.path? // .) != "$HOME/Library/Keychains"));
  {"$schema": "../profile.schema.json", "meta": {"name": "nolabs-ai-claude", "description": "nolabs-ai/claude, but without Keychain access (generated)"}}
  + (del(.name, .description, .allow_launch_services, .rollback, .filesystem.bypass_protection)
    | .filesystem.allow |= nokc
    | .filesystem.suppress_save_prompt |= ["$HOME/Library/Keychains"]
    | del(.credential_providers, .credential_routes))
'
