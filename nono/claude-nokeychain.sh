#!/bin/sh
# Generate nono/profiles/claude-nokeychain.json from the nolabs-ai/claude
# pack profile, minus its ~/Library/Keychains allow + bypass_protection.
# Re-run after `nono update`.
set -e
pack="$HOME/.config/nono/packages/nolabs-ai/claude"
out="$HOME/.dotfiles/nono/profiles/claude-nokeychain.json"
jq --arg pack "$pack" '
  def nokc: map(select((.path? // .) != "$HOME/Library/Keychains"));
  .meta.name = "claude-nokeychain"
  | .meta.description = "nolabs-ai/claude minus Keychain access (generated)"
  | .filesystem.allow |= nokc
  | .filesystem.bypass_protection |= nokc
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
            "type": "keychain_json",
            "service": "Claude Code-credentials",
            "account_candidates": ["unknown", "$USER", "claude-code-user"],
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
