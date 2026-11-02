# Known-answer fixtures

Four repos with hand-verified answers. Use them to sanity-check a change to
`SKILL.md` — not during a normal run.

## `commercetools/audit-log`

Adopt-in-place. The report must contain, and must not contradict, the
[migration plan page](https://commercetools.atlassian.net/wiki/spaces/~62e0a3cf3aaeedcae756073b/pages/3542155288/):

- Chart consolidation: `packages-backend/k8s/audit-log-roles` (a `Role` and a
  `RoleBinding` split out only because personal credentials cannot write RBAC)
  folds into the main chart once ArgoCD applies everything. `TODO [audit-log team]`.
- AU namespace: Terraform-managed in `ctp-production-au` only, among the seven
  targets. Line must name the path and the stack `gcp/ctp-production-au/kubernetes`.
  `TODO — waits on SD-2678 [SRE]`. A run that emits
  `BLOCKED — waits on terraform state rm` here has applied the pre-SD-2678 rule.
- Vault: already at `kv2/repositories/audit-log` with k8s auth role `audit-log`.
  `DONE`, adopt, no import.
- Redis: StatefulSet plus 3 PVCs. `ASK [audit-log team]` — durable or rebuildable
  cache? `_redis-cluster.tpl` sets no `persistentVolumeClaimRetentionPolicy`, so
  `Retain` applies.
- Team of record: `users-access-audit`, agreed by CODEOWNERS and the live
  namespace owner label.
- Cluster targets: 7 (gcp staging, gcp prod eu/us/au, aws staging eu, aws prod
  eu, aws prod us), staging first.
- Check 12 — release identity: resources render as `{{ .Release.Name }}-<component>`
  (`_get-name.tpl`); the live release is `main` (`deploy-backend.sh:53`), not
  `audit-log`. `main-change-history-api` backs a public Ingress, a GCP
  `BackendConfig`, and an AWS private-link `HTTPRoute`. `BLOCKED — waits on a
  managed rename window [audit-log team]` — confirmed against `serenity`'s source
  that neither delivery mode can render under any name but the App resource's own.
  The StatefulSet (`redis`, no release prefix) is unaffected — cite it separately.

## `commercetools/mongodb-atlas-k8s-operator`

Must flag all four known problems:

- Check 5 — cluster-scoped resources: 2 CRDs plus `ValidatingAdmissionPolicy`
  and its Binding, all in `deployment/charts/operator/templates/_*.tpl` and
  `templates/crds/_*.tpl`. Plus a `ClusterRole`/`ClusterRoleBinding` in `_rbac.tpl`.
- Check 2 — shares the `mongodb` namespace with `check-mongodb-stats` and
  `atlas-api-identity-service`, so it needs a fresh dedicated Space, not
  adopt-in-place.
- Check 9 — `Api::all(k8s_client)` in `src/operator/atlascluster.rs:37` and
  `src/operator/vacs_reconciler.rs:52`, no leader election anywhere. No
  side-by-side run; one controlled switch.
- Check 7 — direct Helm from CircleCI via `kubegen/restore`.

Terraform enters at the identity layer, not the namespace: it owns the Workload
Identity binding keyed by namespace + ServiceAccount, so a new namespace needs a
new binding before cutover and removal of the old one after.

## `commercetools/reference_service`

The third-engineer repo (AC 10). Known facts:

- Catch-all CODEOWNERS is `@commercetools/extensibility-team` (`CODEOWNERS:1`).
- One chart, `deployment/charts/reference/`.
- Deploy is `helm upgrade --install --namespace=reference` inside the
  `helm_deploy` command in `.circleci/config.yml`; `serenity/install` is already
  present for `configure-docker` and `alpha auth github`, so the CLI is on the box.
- No `serenity.yaml`, no `catalog` entry.
- Eleven cluster targets, one values directory each under
  `deployment/charts/reference/values/`.
- No cluster-scoped resources, no StatefulSet — stateless, so side-by-side
  validation in one cluster is safe.
- No `ops-terraform` Vault entry, so check 8 is adopt-in-place.
- The `reference` namespace **is** Terraform-managed in `ctp-production-au`:
  it sits in that cluster's `kubernetes-namespaces` payload and
  `gcp/ctp-production-au/kubernetes/namespaces.tf:4` passes `create = true`. In
  `ctp-staging` the same name is absent from the literal `kubernetes_namespace`
  resources in `gke-native/main.tf`, so staging is clean. The AU line must read
  `TODO — waits on SD-2678 [SRE]` and must name the pinned module version — a run
  that reports the namespace unmanaged has skipped question two of check 3, and a
  run that reports it `BLOCKED` on a state removal has applied the pre-SD-2678
  rule.
- `att_production_aws_us-east-1_v1` has no entry in the CtTeam `$Clusters` list,
  so it is not a Catalog target today.

Even so, the work list must still carry the Team/Space/App XRs, the
`serenity.yaml`, the deploy-step switch, and the old-step retirement — those
`TODO`s appear no matter how clean the repo is.

## `commercetools/mongocostique`

The already-half-onboarded repo, and the fixture for the check-7 secrets trap.
Verified at `c795bf0`:

- All three Catalog XRs are **already merged** (`catalog/catalog/saypetabyte/`,
  commit `571d5f6`, SD-2422), so check 4 is `DONE` per file. The App omits
  `delivery`, so it defaults to `gitops` and composes an ApplicationSet scanning
  `commercetools/saypetabyte-gitops` for `*/mongocostique/mongocostique`. No such
  path exists on any branch, so it generates zero Applications — the XR is inert,
  not working. Flipping to `delivery: oci` is `TODO [Special Delivery]`.
- Check 7 secrets: the chart renders `MONGOCOSTIQUE_CLIENT_SECRET_<i>` and
  `CONFLUENCE_API_TOKEN` into `stringData` (`templates/secret.yaml:8-15`) from a
  `mktemp` values file that `.circleci/config.yml:145-174` fills with five
  `vault kv get` reads. A run that lists the deploy-step switch as a plain `TODO`
  has missed this: it must be
  `BLOCKED — waits on moving secrets out of chart values`, because
  `serenity alpha deploy` would publish those credentials to
  `europe-docker.pkg.dev`.
- Check 7 current mechanism: `NOTE`, not `DONE`. `helm upgrade --install --atomic
  --wait --timeout 300s` (`.circleci/config.yml:176-184`) after `kubegen/restore`.
  The line must call out that `--atomic`/`--wait` give rollback-on-failure that
  ArgoCD does not reproduce.
- Check 3 is a **zero-`BLOCKED`** case, unlike `reference_service`. The namespace
  is absent from every `namespaces.json` payload, and `mongocostique` appears
  nowhere in `ops-terraform` except two Vault tfvars. Those two create a Vault
  **k8s** auth role (`k8s_auth_role_configs` → `auth-k8s.tf:67`, stack
  `gcp/ctp-vault/vault/vault-config`); Catalog composes only a `jwt`
  `oidc/circleci` role, so there is no double owner and no `state rm`.
- That k8s auth role binds ServiceAccount `mongocostique`, which the chart never
  creates — the CronJob uses `envFrom.secretRef`. Dead config, `TODO [SRE]`,
  not blocking.
- Check 8 is fully `DONE`: CI already reads `kv2/repositories/mongocostique/common`
  and already uses role `crossplane_mongocostique`. No `legacyMountPath` needed.
- Check 9: no Kubernetes client anywhere in the Rust source, no StatefulSet, no
  PVC. The risk is release-name collision, not data — ArgoCD would render the same
  `mongocostique` release into the same namespace.
- Check 11: exactly one cluster, `ctp_staging_gcp_europe-west1_v1` →
  `stg-gcp-eu-west1-v1`, which is in `$Clusters`.
- Namespace `mongocostique` is Space-created, so it carries
  `platform.commercetools.com/space` (space `composition.yaml:225`) and the import
  guard at `composition.yaml:62` passes.
