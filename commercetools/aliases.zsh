# Default vault to production
export VAULT_ADDR="https://vault.services.europe-west1.gcp.commercetools.com"

set_vault_production() {
  export VAULT_ADDR="https://vault.services.europe-west1.gcp.commercetools.com"
  vault login -method=oidc -path=oidc/gsuite
}
set_vault_staging() {
  export VAULT_ADDR="https://vault.sre.europe-west1.gcp.commercetools.com"
  vault login -method=oidc -path=oidc/gsuite
}