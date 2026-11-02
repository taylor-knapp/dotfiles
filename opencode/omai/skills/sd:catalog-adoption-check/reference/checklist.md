# Adoption check — what to check

One line per check. Where a second sentence appears, it is either the place to
look or the command to run and what its output should tell you.

Verdicts: `DONE` satisfied · `TODO` work, can start now · `BLOCKED` work, waits
on something · `ASK` a human must answer · `NOTE` baseline fact, no work.

Voice: name the actor and the verbs it gets, one idea per line, imperative on
anything that carries work. See *Report voice* in `SKILL.md` for the swap table.

Substitute `$NAME` for the repo name, `$REPO` for `owner/repo`, `<ns>` for the
namespace, `<ctx>` for the kubectl context, and `<chart>` for the chart directory.

---

## Before you start

- [ ] Confirm every command you plan to run only reads, never `gh pr create`, `git push`, `git commit`, `kubectl apply|create|delete|patch`, `terraform apply|state rm`, or `vault write`.
- [ ] Obtain working copies of the target repo, `ops-terraform`, `catalog` (`commercetools/catalog`, renamed from `ct-apps`), and `k8s-gitops`, preferring an existing clone under `~/github.com/<owner>/<repo>`.
- [ ] Prefer a local `ops-terraform` clone, because a fresh clone never carries the `.terraform/modules/` payloads that check 3 needs.
- [ ] Record the target repo's default branch and HEAD SHA, and cite every line number against that SHA.
- [ ] Emit `ASK` on each check that needed a repo you could not clone, naming that repo, rather than aborting the run.
- [ ] Probe which Vault/kubectl session is live with a direct `kubectl get ns` against a reference cluster (production: `ctp_production_sre-services_gcp_europe-west1_v1`; staging: `ctp_staging_gcp_europe-west1_v1`) — never `vault token lookup`/`$VAULT_TOKEN`, which can 403 even while the kubectl session is live.
- [ ] Ask the user to log in to production Vault when the probe above fails, and to switch to the staging Vault/kubectl session before checks 2, 10, or 11 need it — naming the exact `VAULT_ADDR` either way, rather than parking straight into `ASK`. This is the one pause hard rule 5 allows.

## Fan out the checks

- [ ] Dispatch the eight file-based checks as five agents — `chart-shape` (5, 6, 12), `ci-secrets` (7, 8), `terraform` (3), `catalog-xrs` (4 plus check 1's CODEOWNERS and claim-grep sub-lines), `parallel-run` (9). See *Fan out across agents* in `SKILL.md` for why each bundle travels together.
- [ ] Give every agent hard rules 1–4 verbatim, the full copied text of its checks, and Step 1's resolved inputs: `owner/repo`, the four clone paths, the default branch and HEAD SHA, the chart directory, and the namespace.
- [ ] Require each agent to return report lines already in final format plus a `needs-session` list, and nothing else.
- [ ] Confirm no agent pauses for input, emits `ASK` for a cluster read the main thread could perform, clones a repo, or writes anything.
- [ ] Run checks 2, 10, 11, and check 1's live namespace-label sub-line yourself, in that order, since one Vault/kubectl session is live at a time and only the main thread can ask the user to switch.
- [ ] Run all twelve serially in numeric order when agents are unavailable — the report is identical, only the wall-clock changes.
- [ ] Settle every row of the reconcile table in `SKILL.md` once the agents return: `needs-session` entries, check 5's shared-namespace line, check 6's merge-timing branch, whether check 10 applies, check 7's mount reference, and check 3 against check 2.2.

## 1. Ownership

- [ ] Confirm the catch-all `*` entry resolves to exactly one team, reading only the file GitHub applies: the first that exists of `.github/CODEOWNERS`, root `CODEOWNERS`, `docs/CODEOWNERS`. GitHub ignores the others outright, so a stale copy naming a different team is not a conflict.
- [ ] Check CODEOWNERS for a line more specific than `*` that assigns the chart or `.circleci/` paths to a different team, since GitHub applies last-match-wins and that line owns the paths onboarding touches.
- [ ] Confirm the live namespace owner label agrees with CODEOWNERS. `kubectl --context <ctx> get ns <ns> -o jsonpath='{.metadata.labels}'` — compare the owner label against the CODEOWNERS team.
- [ ] Search for an existing Catalog claim on this repo. `grep -rn "$REPO" catalog/catalog` — any hit means part of the onboarding already landed. (`catalog`'s legacy `coco/` claims directory no longer exists; do not search it.)
- [ ] Emit `ASK` naming the candidate teams when the authoritative CODEOWNERS and the live namespace owner label disagree, when the catch-all lists more than one team, or when a deploy-path carve-out names a different team.

## 2. Namespace strategy

- [ ] List every other workload running in the namespace. `kubectl --context <ctx> get deploy,sts,ds -n <ns>` — look for workloads belonging to a different app.
- [ ] Cross-check `k8s-gitops` and `catalog` for other apps targeting the same namespace, since the live cluster may lag the repos.
- [ ] Conclude **adopt-in-place** for a dedicated namespace or a **new dedicated Space** for a shared one, remembering that Space-level RBAC reaches every workload already in the namespace.
- [ ] Confirm check 10 applies whenever this group concluded the namespace changes.
- [ ] Check whether the namespace already carries `platform.commercetools.com/space` when a Space XR exists, because the Space composition fails on a pre-existing namespace without it. See the guard at `k8s-gitops/workspace/special-delivery/crossplane-compositions/catalog/charts/space/templates/composition.yaml:62`.

## 3. Terraform-owned prerequisites (`ops-terraform`)

- [ ] Check whether the namespace name appears in any `kubernetes-namespaces` module payload. `find ops-terraform -name namespaces.json -print0 | xargs -0 grep -ln "\"$NAME\""` — a hit proves only that the name sits in the payload.
- [ ] Check whether each matching cluster directory actually creates namespaces. `grep -rn -A4 'kubernetes-namespaces' <cluster-dir>/*.tf` — look for `create = true`.
- [ ] Report the namespace as Terraform-managed only when both of those hold, because one payload ships to every cluster and only `create` decides.
- [ ] Check for a literal `resource "kubernetes_namespace"` in the cluster directory, since some clusters skip the module entirely.
- [ ] Check whether the version each cluster pins carries the two guards, because they ship in `kubernetes-namespaces` 1.34.2 ([SD-2678](https://commercetools.atlassian.net/browse/SD-2678)) and a `~> 1.34.0` pin accepts that patch without a bump, while an older minor does need one.
- [ ] Read the pin at both levels where a wrapper is in play, because a cluster pinning `gcp-gke-environment ~> 2.1.0` or `aws-eks-environment ~> 4.12.0` gets its namespace-module version from that wrapper's own constraint in `services/<cloud>/<x>-environment/namespaces.tf`, not from the cluster directory.
- [ ] Emit `TODO — waits on SD-2678 [SRE]` for a namespace the module creates, never `BLOCKED — waits on terraform state rm`, because a guarded module lets Terraform and the Space composition hold the same object: it ignores label drift, ignores the one annotation key `platform.commercetools.com/space`, and refuses to destroy the namespace.
- [ ] Never argue that Terraform leaves the adoption annotation alone because the module sets no annotations — the provider manages `metadata.annotations` as a whole map and plans an out-of-band annotation to `null`, which is why the scoped `ignore_changes` entry exists.
- [ ] Emit `NOTE` rather than `ASK [SRE]` where the module arrives transitively with no `create` in the cluster directory, as happens when the AWS `eks` wrapper passes it down, because the guard sits inside the module and reaches every consumer whatever the unread value is.
- [ ] Read the payload from the module source when `.terraform/modules/` is absent. `gh api repos/commercetools/terraform-modules/contents/kubernetes/kubernetes-namespaces/namespaces.json` — note the version each cluster pins, because payloads drift between versions.
- [ ] Check whether Terraform creates the Vault kv2 mount, policies, or auth roles. Grep `gcp/ctp-vault/vault/vault-config/` across `locals-repositories.tf`, `policies-repositories.tf`, `auth-k8s.tf`, `auth-oidc-circleci.tf`, and `team-*.tf`.
- [ ] Distinguish a Vault policy Terraform creates from one it merely references by name, because a `crossplane_`-prefixed policy belongs to Crossplane.
- [ ] Check whether Terraform creates Workload Identity or IAM bindings keyed by namespace plus ServiceAccount. Search `*/workload-identity/`, `*/iam/`, and `vault_sa.tf`.
- [ ] Check whether RBAC, ServiceAccounts, or DNS and ingress are created outside the chart. Search `*/dns/` and the `k8s-gitops/workspace/*` RBAC configs.
- [ ] Name the Spacelift stack owning every Terraform directory you cite. `grep -rn 'project_root *= *"<dir>"' ops-terraform --include='*.tf'` — the stack is the `stack_configs` entry whose `project_root` equals that directory.
- [ ] Give every sub-line one of `DONE` for not-managed, `TODO — waits on SD-2678 [SRE]` for a module-created Namespace, `BLOCKED — waits on terraform state rm` for any other same-object-same-name collision such as a Vault mount or identity group alias, `TODO [SRE]` for adopt-or-import, or `ASK [SRE]` for undetermined.
- [ ] Confirm no sub-line says `DONE` about a resource you could not settle from the files.

## 4. Catalog resources to author

- [ ] Check whether `catalog/catalog/<team>/team.yaml` exists carrying `githubTeam`, `oktaGroup`, and `gsuiteGroup` (repo `commercetools/catalog`, formerly `ct-apps`).
- [ ] Check whether `catalog/catalog/<team>/spaces/<app>.yaml` exists carrying `ownerTeamRef` and this app in `spec.allowedApps.appRefs`.
- [ ] Check whether `catalog/catalog/<team>/apps/<app>.yaml` exists carrying `githubFullName`, `circleciProjectUUID`, `ownerTeamRef`, and `targetSpaceRef`.
- [ ] Confirm `circleciProjectUUID` holds the CircleCI project UUID rather than the GitHub repo id, and emit `ASK [<app> team]` when you cannot read it.
- [ ] Check whether the App sets `delivery: oci`, the V2 target mode that composes no ApplicationSet.
- [ ] Pick `delivery: oci` unless the app stays on the `serenity/sync` GitOps orb.
- [ ] Check where a gitops-mode App's ApplicationSet actually points, because a merged App can still generate nothing. `gh api 'repos/commercetools/<team>-gitops/git/trees/staging%2Flive?recursive=1' --jq '.tree[].path'` — look for a `<cluster>/<space>/<app>` path.
- [ ] Confirm this group emits at least one `TODO`, even when all three XRs are already merged.

## 5. Cluster-scoped resources

- [ ] Grep the chart for cluster-scoped kinds without anchoring `kind:` to column 0 and without restricting to `*.yaml`, because named templates live in indented `_*.tpl` files.
- [ ] Include `<chart>/templates`, `<chart>/crds`, and any top-level `crds/` directory in that grep.
- [ ] End the grep pattern with `[[:space:]]*$` so `roleRef.kind: ClusterRole` cannot match, since that is a reference rather than a resource.
- [ ] Check for a `crds.install` or `createClusterRoles` values flag, because an upstream subchart can install CRDs with no template in this repo.
- [ ] Confirm the ArgoCD whitelist gap is still open before citing it. `grep -rn 'clusterResourceWhitelist' k8s-gitops/workspace/special-delivery/crossplane-compositions/catalog/charts/space/templates/composition.yaml` — no match means the Space `AppProject` refuses every cluster-scoped sync, so each GVK is `BLOCKED — waits on SD-2559`.
- [ ] Judge each GVK against the whitelist entries when the grep does match, since the gap may have moved rather than closed. `group: '*'` paired with `kind: '*'` covers everything (`DONE`); a narrower list leaves `BLOCKED` on only the GVKs it omits.
- [ ] Emit a second `BLOCKED` when the app needs cluster-scoped resources and also shares its namespace, because the whitelist belongs to the `AppProject` and would reach every neighbor app.

## 6. Chart source

- [ ] Find every chart in the repo. `find <repo> -name Chart.yaml -not -path '*/.git/*' | grep -v '/charts/[^/]*/charts/'` — exclude vendored subcharts only, never every path containing `charts/`.
- [ ] Identify which of `loadChart()`'s four forms the chart uses: local directory, `oci://`, direct `.tgz`, or `helm://` index-based repo.
- [ ] Treat classic Helm repo support as shipped rather than blocking. See `resolveHelmRepoChart` in `chart_load.go`, landed under SD-2558.
- [ ] Emit `ASK [Special Delivery]` for a private or authenticated Helm repo, or for a version range, since neither is supported.
- [ ] Decide whether more than one chart means consolidation work or a monorepo, by checking whether the charts deploy to the same namespace and whether one exists only to work around a CI-credentials split.
- [ ] Before recommending a same-pipeline chart merge, check whether the objects being adopted already carry `meta.helm.sh/release-name` for a different release. `kubectl --context <ctx> get <kind> <name> -n <ns> -o jsonpath='{.metadata.annotations}'` — a mismatch fails the merge with "invalid ownership metadata" unless the merge lands in the same change ArgoCD adopts the namespace, or the annotation is patched first.
- [ ] Never suggest `helm uninstall <donor-release>` as a way to clear that conflict — it deletes by the donor's stored manifest, not by annotation, and removes the live objects.

## 7. CI / delivery

- [ ] Identify what deploys the app today. `grep -nE 'helm (upgrade|install)|release-chart|kubegen|serenity/(sync|approve|install)|serenity alpha deploy' .circleci/config.yml deployment/scripts/*.sh` — cite the file and lines.
- [ ] Mark the current mechanism `NOTE` and never `DONE`, because a later sub-line schedules that same mechanism for deletion.
- [ ] Call out any deploy flag carrying behavior ArgoCD does not reproduce, such as `--atomic` rolling back a failed release or `--wait` blocking until healthy.
- [ ] Trace every Secret key back to its source. `grep -rn '^[[:space:]]*kind:[[:space:]]*Secret[[:space:]]*$' <chart>` — search `<chart>` rather than `<chart>/templates`, since `-r` never descends into a vendored subchart's templates, then open each match and read its whole `data`/`stringData` block rather than trusting a fixed `-A` window.
- [ ] Check the sources that bypass `.Values` entirely. `grep -rnE '\.Files\.Get|lookup[[:space:]]' <chart>` — a hardcoded literal, `.Files.Get`, or `lookup` against an existing cluster Secret bakes a credential into the artifact without touching `.Values`.
- [ ] Check whether CI fills those values from Vault at deploy time. `grep -nE 'helm .*(--set|-f )|vault (kv )?(get|read)' .circleci/config.yml deployment/scripts/*.sh` — a temp values file fed by `vault kv get` is the signal.
- [ ] Emit `BLOCKED — waits on moving secrets out of chart values [<app> team]` when both hold, because `serenity alpha deploy` publishes rendered manifests as an OCI artifact and registries retain artifacts.
- [ ] Name the replacement whenever you block on secrets: an `ExternalSecret` against the `kv2/repositories/$NAME` mount that onboarding already creates.
- [ ] Emit `ASK [<app> team]` rather than `DONE` for any Secret key whose source you could not determine, since the absence of `.Values` alone does not prove safe delivery.
- [ ] Check whether `serenity.yaml` exists, and emit `TODO [<app> team]` naming the target cluster list from check 11 when it does not.
- [ ] Name which config shape the app should author: the `serenity/sync` orb's per-tier cluster lists, or the version-2 snake_case config with a CEL `target_filter`.
- [ ] Emit `TODO [<app> team]` for switching the deploy step to `serenity alpha deploy`, waiting on the secrets sub-line whenever that one is `BLOCKED`.
- [ ] Emit `TODO [<app> team]` for retiring the old deploy step in the same change ArgoCD takes over, so no window has two pipelines writing the same resources.
- [ ] Check for an in-cluster runner and `CIRCLE_OIDC_TOKEN`. Grep `.circleci/config.yml` for a `resource_class` naming a self-hosted runner and for `OIDC`.

## 8. Vault / secrets

- [ ] Check whether the app's existing mount path is already `kv2/repositories/$NAME`. `grep -rn 'vault_role\|VAULT_ROLE\|vault-role\|kv2/repositories' .circleci/config.yml` — compare the path CI reads against what `CtSecretStoreVault` composes.
- [ ] Emit `DONE` and adopt in place when the path already matches, since no data migration is needed.
- [ ] Emit `BLOCKED — waits on the CtSecretStoreVault legacyMountPath override [Special Delivery]` when the path differs, saying on the line that the field is designed, unbuilt, and has no ticket filed.
- [ ] Check whether the CircleCI JWT auth role is already named `crossplane_$NAME`, and emit `TODO [<app> team]` when it is not.
- [ ] Note on that line that renaming the CircleCI role is a deliberate separate PR after the new mount is populated.
- [ ] Confirm the repo is absent from `CtRepositoryController`'s `spec.unmanaged`, since the claim is created for every `App` not listed there. See `k8s-gitops/workspace/special-delivery/crossplane-compositions/ctrepositorycontroller-composition/charts/ctrepositorycontroller-composition/templates/claim.yaml`.
- [ ] Cross-reference check 3 for who owns the mount and the policy in Terraform.
- [ ] Check the chart's own Vault Agent config separately from CircleCI's vault-role. `grep -rn 'authRole\|secretsPathPrefix\|vault\.hashicorp\.com/agent' <chart>/values.yaml <chart>/templates` — this is what the *running pod* authenticates with, not what CI fetches, and it must independently match `kv2/repositories/$NAME`.

## 9. Parallel-run safety

- [ ] Check for leader election in the app source. `grep -rniE 'leader.?elect|LeaderElection|lease' --include='*.go' --include='*.rs' --include='*.java' <repo>` — no match alongside a cluster-wide watch means two instances would collide.
- [ ] Check whether the app watches cluster-wide. `grep -rnE 'Api::all|NewControllerManagedBy|informers\.' <repo>` — any match names a controller rather than a plain service.
- [ ] Emit `BLOCKED — waits on a single-switch cutover window [SRE + <app> team]` for a controller watching cluster-wide with no leader election.
- [ ] Emit `DONE` for a stateless horizontally-scalable service, because side-by-side validation in one cluster is safe.
- [ ] Check for a StatefulSet and read its `volumeClaimTemplates`. `grep -rnE '^[[:space:]]*kind:[[:space:]]*StatefulSet' <chart>` — any match makes durability an `ASK [<app> team]`.
- [ ] Note on that line that `volumeClaimTemplates` is immutable, so a mismatch is fixed by changing the chart and never by deleting the StatefulSet.
- [ ] Check `persistentVolumeClaimRetentionPolicy`, where unset means Kubernetes' `Retain` default and lowers the risk either way.
- [ ] Check whether the new ArgoCD Application would render the same release name into the same namespace, because both owners would then write the same objects.
- [ ] Check for a bare `kind: Job` template (not `CronJob`). `grep -rnE '^[[:space:]]*kind:[[:space:]]*Job[[:space:]]*$' <chart>` — a Job's spec is immutable, so any change to it is a hard ArgoCD sync failure, not a rollout, where Helm's imperative apply tolerated it silently.
- [ ] Recommend converting a found Job to an ArgoCD `PostSync` hook with `hook-delete-policy: BeforeHookCreation`, which also preserves any Helm-install ordering the Job relied on.

## 10. Namespace-coupled dependencies

- [ ] Emit one `DONE` line and skip the rest of this group when check 2 concluded the namespace does not change.
- [ ] Find in-cluster DNS callers of the old namespace. `grep -rn "$OLDNS\.svc" .` — match the namespace suffix, not `$NAME`, so a Service named something other than the repo is still found.
- [ ] Find ingress, load balancer, and DNS objects in the chart. `grep -rnE '^[[:space:]]*kind:[[:space:]]*(Ingress|BackendConfig)' <chart>`
- [ ] Find NetworkPolicy namespace selectors. `grep -rn 'namespaceSelector\|namespace:' <chart>/templates/*networkpolicy*`
- [ ] Find Prometheus namespace selectors. `grep -rn 'namespaceSelector' <chart>/templates/*monitor*`
- [ ] Find Vault k8s auth roles bound to the old namespace. `grep -rn "$OLDNS" ops-terraform --include='*.tf'`
- [ ] Find hardcoded namespace strings in the templates, which fail quietly only after the app deploys into the new namespace. `grep -rn "\"$OLDNS\"\|: $OLDNS" <chart>/templates` — look for a literal where `{{ .Release.Namespace }}` belongs.

## 11. Cluster targets

- [ ] Read today's deploy targets from the CircleCI deploy jobs and from `k8s-gitops`.
- [ ] Translate each kubectl or Terraform cluster name into its Serenity name. Re-read the `$Clusters` literal in `k8s-gitops/workspace/special-delivery/crossplane-compositions/ctteam-composition/charts/ctteam-composition/templates/composition.yaml` rather than trusting a copied table.
- [ ] Emit `BLOCKED — waits on adding the cluster to the CtTeam cluster list [Special Delivery]` for any current target with no row in `$Clusters`, never a silent omission.
- [ ] Recommend the first `serenity.yaml` cover exactly one low-risk cluster, staging where one exists, and name which clusters follow in the batch.
- [ ] Emit `BLOCKED — waits on SD-2555 [Special Delivery]` for anything targeting the SRE Services cluster, which is not an available Catalog target yet.
- [ ] Check that the Argo host rendering this Space lists the target cluster as a destination. Grep `managedClustersByArgo` across `k8s-gitops/workspace/special-delivery/crossplane/crossplane-environment-configs/values-cluster-*.yaml` — hosts differ, and the staging-gcp host lists playground clusters only.

## 12. Release identity

- [ ] Grep the chart for `.Release.Name` templated into any resource. `grep -rn '{{[[:space:]]*\.Release\.Name' <chart>/templates` — none found means a release-name change at cutover is a no-op, `DONE`.
- [ ] When found, check what release name the current deploy step actually passes. `grep -nE 'helm (upgrade|install)' .circleci/config.yml deployment/scripts/*.sh` — compare it against the app/repo name, since that is the only name Serenity can render with in either delivery mode (no override field exists in `serenity.yaml`'s `name:` or `serenity alpha deploy --name`).
- [ ] Emit `BLOCKED — waits on a managed rename window [<app> team]` when the current release name differs from the app name, naming every release-name-templated resource that is also externally addressed (Ingress backend, `BackendConfig`, private-link route, or anything an external DNS/LB config references by name) — those carry the real availability risk during the swap.
- [ ] Recommend the ArgoCD sync option `PruneLast=true` for a forced rename, so new objects go healthy before the old ones are pruned.
- [ ] Cite a hardcoded-name resource (no `.Release.Name` at all, e.g. a StatefulSet with a literal name) as its own `DONE` line, so the rename's blast radius isn't overstated to include it.

## Subtask manifest

- [ ] Render one manifest block per work-list row, in work-list order, with `summary`, `parent`, `actor`, `blocked by`, `blocks`, `source`, and `description`.
- [ ] Create nothing: no `createJiraIssue`, `createIssueLink`, `editJiraIssue`, or `transitionJiraIssue`. The manifest is text for a human or a separate create-skill.
- [ ] Rewrite every `summary` as an imperative under 255 characters, turning an `ASK` row's question into an action ("Confirm whether Redis data is durable or a rebuildable cache").
- [ ] Take `parent` from the invocation's second argument, or write `parent: <story key — ASK [requester]>` and continue.
- [ ] Name a team in `actor` — `<app> team`, `SRE`, or `Special Delivery` — never a person, since CODEOWNERS names teams.
- [ ] Give every `BLOCKED` row a `blocked by` entry: a row number, a platform ticket key from the dependencies table, or `(untracked) <thing>` for a waits-on with no ticket.
- [ ] List every contributing group sub-number in `source`, so a fact the reconcile step merged (checks 2.2 and 3.2) yields one subtask rather than two.
- [ ] Keep `DONE` and `NOTE` lines out, and never collapse a whole check group into one subtask — its sub-lines carry different actors and blockers.
- [ ] Close with the row count and a statement that nothing was created.

## Before you print

- [ ] Confirm all twelve groups appear in order, each unevaluated group carrying an `ASK` that names the missing input.
- [ ] Confirm every line carries exactly one of `DONE`, `TODO`, `BLOCKED`, `ASK`, or `NOTE`.
- [ ] Confirm every `TODO` and `ASK` names an actor, and every `BLOCKED` names what it waits on.
- [ ] Confirm check 7's current-mechanism line reads `NOTE` and not `DONE`.
- [ ] Confirm every check-3 sub-line states Terraform-managed or not, and that managed ones name the file path, the Spacelift stack, and one of adopt, import, or remove-from-state.
- [ ] Confirm at least one `TODO` exists for the Catalog XRs, one for `serenity.yaml`, and one for retiring the old deploy step.
- [ ] Confirm no mechanism sits in the subject position of an active verb. Rewrite "X's RBAC reaches Y" as "members of group G get `<verbs>` on Y" — name the group, ServiceAccount, controller, or binary that holds the access, then the verbs it gets.
- [ ] Confirm every `TODO` opens with an imperative verb rather than a noun phrase, so the line names the action and not just the topic.
- [ ] Confirm every `BLOCKED` opens with the obstruction stated actor-first ("Terraform creates the namespace"), leaving the action to its `— waits on` clause so it is named once.
- [ ] Confirm work-list entries are verb-first whatever their verdict, since that list is a list of actions.
- [ ] Confirm no line joins two mechanisms with *and* or *so* where two sub-numbered lines belong, since two mechanisms have two actors and two verdicts.
- [ ] Confirm no paragraph appears anywhere in the report, including any closing summary section.
- [ ] Confirm the work list runs in dependency order, carries an actor and group number on every entry, and excludes `DONE` and `NOTE` lines.
- [ ] Confirm the platform-dependencies table lists only rows the report actually cites.
- [ ] Confirm every `needs-session` entry the agents returned was run in a live session rather than carried into the report as `ASK`.
- [ ] Confirm checks 5, 6, and 10 reflect check 2's conclusion, and that checks 3 and 2.2 cite the same Terraform file, line, and stack.
- [ ] Confirm the manifest holds one block per work-list row, every `summary` is verb-first, and every `BLOCKED` row carries a `blocked by` entry.
- [ ] Confirm nothing was written by the main thread or by any agent: no PR, no commit, no Jira issue, and no cluster, Vault, or Terraform mutation.
