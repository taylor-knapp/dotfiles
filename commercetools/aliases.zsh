####
# Kubegen provides a `multi-token-helper` that will keep a token for all vault envs.
# To enable it, set the token_helper in your ~/.vault file to the path of the binary (which multi-token-helper), e.g.
# token_helper = "/opt/homebrew/bin/multi-token-helper"
# Then the following script will help you switch between vault environments, only logging in if the token is expired.
####

# Default vault to staging
export VAULT_ADDR="https://vault.sre.europe-west1.gcp.commercetools.com"

set_vault_production() {
  export VAULT_ADDR="https://vault.services.europe-west1.gcp.commercetools.com"
  login_if_necessary
}

set_vault_staging() {
  export VAULT_ADDR="https://vault.sre.europe-west1.gcp.commercetools.com"
  login_if_necessary
}

login_if_necessary() {
  # If we can list paths, we are authenticated.
  vault kv list kv2/repositories/audit-log &>/dev/null
  if [ $? -ne 0 ]; then
    vault login -method=oidc -path=oidc/gsuite
  else
    echo "There is an existing valid token."
  fi
}