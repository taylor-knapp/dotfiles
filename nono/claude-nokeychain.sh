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
  # Keychain is denied, so nono proxy supplies the OAuth token: sandbox sees a
  # phantom, real token stays host-side. See nono docs: Sandboxed OAuth Logins.
  | . * {
      "credential_providers": {
        "claude_code": {
          "type": "oauth_capture",
          "token_endpoints": [{
            "host": "https://platform.claude.com",
            "path": "/v1/oauth/token",
            "response_fields": [
              { "path": "access_token",  "kind": "opaque", "format": "sk-ant-oat01-{}" },
              { "path": "refresh_token", "kind": "opaque" },
              { "path": "id_token",      "kind": "jwt" }
            ],
            "request_body": "auto",
            "request_nonce_fields": ["access_token", "refresh_token"]
          }],
          "api_hosts": ["https://api.anthropic.com"],
          "credential_store": {
            "type": "file_json",
            "path": "$HOME/.claude/.credentials.json",
            "phantom_fields": ["claudeAiOauth.accessToken", "claudeAiOauth.refreshToken"]
          },
          "helpers": {
            "status": ["claude", "auth", "status", "--json"],
            "login": ["claude", "auth", "login"],
            "logout": ["claude", "auth", "logout"]
          }
        }
      },
      "credential_routes": [{
        "name": "anthropic_oauth",
        "provider": "claude_code",
        "endpoint_policy": {
          "default": { "decision": "deny" },
          "allow": [{ "method": "POST", "path": "/v1/messages" }]
        }
      }]
    }
' "$pack/profiles/claude.json" > "$out"

