#!/bin/bash
# Wrapper script to source credentials and run commercetools-essentials MCP

# Default to nico-test-project if CT_PROJECT_CONFIG is not set
CT_CONFIG="${CT_PROJECT_CONFIG:-gcp-eu-nico-test-project}"

# Source the credentials
source "$(dirname "$0")/clients/${CT_CONFIG}.sh"

# Tell Node to respect HTTP_PROXY/HTTPS_PROXY env vars (requires Node >= 22)
export NODE_USE_ENV_PROXY=1

# Run the MCP server (globally installed, no npx/registry needed)
commerce-mcp \
  --tools=all.read \
  --authType=client_credentials \
  --isAdmin=true \
  --clientId="$CLIENT_ID" \
  --clientSecret="$CLIENT_SECRET" \
  --projectKey="$PROJECT_KEY" \
  --authUrl="$AUTH_URL" \
  --apiUrl="$API_URL" \
  --dynamicToolLoadingThreshold=10
