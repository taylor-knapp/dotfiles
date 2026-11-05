#!/bin/bash
# setup-claude-gpg.sh — Create a dedicated GPG signing key for Claude Code
#
# Run this OUTSIDE a Claude Code session — it invokes pinentry to set
# a passphrase during key generation.
#
# Creates an isolated GNUPGHOME at ~/.gnupg-claude with a passphrase-protected,
# signing-only ed25519 key. The sandbox launcher scripts (claude-sandboxed,
# claude-jailed) automatically pick up this key via the signing-key-id file.
# Passphrase is entered once after each machine restart via pinentry.

set -euo pipefail

GNUPG_CLAUDE="$HOME/.gnupg-claude"

# Already set up?
if [[ -d "$GNUPG_CLAUDE" ]] && gpg --homedir "$GNUPG_CLAUDE" --list-keys "Claude Code (bot)" &>/dev/null; then
    KEY_ID=$(cat "$GNUPG_CLAUDE/signing-key-id" 2>/dev/null || echo "unknown")
    echo "Claude GPG key already exists at $GNUPG_CLAUDE (key $KEY_ID)"
    echo "To regenerate, remove $GNUPG_CLAUDE and re-run."
    exit 0
fi

# Preflight
if ! command -v gpg &>/dev/null; then
    echo "ERROR: gpg not found. Install with: brew install gnupg" >&2
    exit 1
fi

EMAIL=$(git config user.email 2>/dev/null || echo "")
if [[ -z "$EMAIL" ]]; then
    echo "ERROR: No git user.email configured." >&2
    echo "  git config --global user.email you@example.com" >&2
    exit 1
fi

echo "=== Setting up Claude Code GPG signing key ==="
echo "GNUPGHOME: $GNUPG_CLAUDE"
echo "Email:     $EMAIL"
echo ""

# Create isolated GNUPGHOME
mkdir -p "$GNUPG_CLAUDE"
chmod 700 "$GNUPG_CLAUDE"

# Generate signing-only ed25519 key (prompts for passphrase)
echo "Generating ed25519 signing key..."
echo "You will be prompted to set a passphrase."
echo "This passphrase is required once after each machine restart."
echo ""
gpg --homedir "$GNUPG_CLAUDE" \
    --quick-gen-key "Claude Code (bot) <$EMAIL>" ed25519 sign 0

# Configure agent: cache passphrase effectively forever (until reboot clears agent)
PINENTRY_MAC=$(command -v pinentry-mac 2>/dev/null || echo "")
{
    echo "default-cache-ttl 31536000"
    echo "max-cache-ttl 31536000"
    [[ -n "$PINENTRY_MAC" ]] && echo "pinentry-program $PINENTRY_MAC"
} > "$GNUPG_CLAUDE/gpg-agent.conf"

# Make sure the agent is down so it restarts on the next session.
gpgconf --homedir "$GNUPG_CLAUDE" --kill gpg-agent

# Extract long key ID
KEY_ID=$(gpg --homedir "$GNUPG_CLAUDE" \
    --list-keys --keyid-format long --with-colons "Claude Code (bot)" \
    | awk -F: '/^pub:/{print $5}')

if [[ -z "$KEY_ID" ]]; then
    echo "ERROR: Failed to extract key ID" >&2
    exit 1
fi

# Store key ID for launcher scripts to read at startup
echo -n "$KEY_ID" > "$GNUPG_CLAUDE/signing-key-id"

# Export public key for GitHub
PUB_FILE="$GNUPG_CLAUDE/claude-bot.pub"
gpg --homedir "$GNUPG_CLAUDE" --armor --export "Claude Code (bot)" > "$PUB_FILE"

# Import public key into user's default keyring so git log can verify signatures
echo "Importing Claude bot key into default keyring for signature verification..."
gpg --import "$PUB_FILE"

# Mark the key ultimately trusted in the default keyring. Without this, git log
# outside the sandbox shows %G? = U (signed, unknown validity) instead of G.
# It's your own bot key, so ultimate (6) is correct.
FPR=$(gpg --homedir "$GNUPG_CLAUDE" --with-colons --fingerprint "Claude Code (bot)" \
    | awk -F: '/^fpr:/{print $10; exit}')
if [[ -n "$FPR" ]]; then
    echo "${FPR}:6:" | gpg --import-ownertrust
else
    echo "WARNING: could not resolve fingerprint; skipping ownertrust (git log will show U not G)" >&2
fi

echo ""
echo "=== Done ==="
echo "Key ID:     $KEY_ID"
echo "Public key: $PUB_FILE"
echo ""
echo "Next steps:"
echo "  1. Copy the public key to clipboard:"
echo "       cat $PUB_FILE | pbcopy"
echo "  2. Add to GitHub: Settings > SSH and GPG keys > New GPG key"
echo "  3. Start a Claude Code session — signing is automatic."
echo ""
echo "--- Public key ---"
cat "$PUB_FILE"
