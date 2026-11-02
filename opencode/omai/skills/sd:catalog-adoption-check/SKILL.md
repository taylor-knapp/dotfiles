---
name: sd:catalog-adoption-check
description: 'Use this skill to assess whether one GitHub repository is ready to onboard onto Catalog / Serenity V2. Takes an owner/repo and emits a numbered readiness checklist covering ownership, namespace strategy, Terraform-owned prerequisites in ops-terraform, the Catalog XRs to author, cluster-scoped resources, chart source, CI/delivery, Vault secrets, parallel-run safety, namespace-coupled dependencies, cluster targets, and release identity — each line carrying a DONE/TODO/BLOCKED/ASK/NOTE verdict, an actor, and a pointer to the evidence. Closes with a Jira subtask manifest rendering the work list one block per action, with parent, actor, and blocked-by. Read-only: it opens no PRs, files no Jira issues, and mutates no cluster, Vault, or Terraform state.'
---

# Catalog Adoption Check

> **Requires:** the `gh` CLI authenticated against the commercetools org, read access to commercetools/ops-terraform, commercetools/catalog, and commercetools/k8s-gitops, and (optionally) `kubectl` contexts for the target clusters. Every command it runs is read-only.

## Purpose

Answer, for one GitHub repository, **"what does it take to onboard this onto
Catalog / Serenity V2, and what is already done?"** The output is a numbered
checklist plus a work list — the facts an engineer would otherwise spend a day
assembling from the chart, `.circleci/config.yml`, `CODEOWNERS`, `ops-terraform`,
`catalog`, and the live cluster.

The costliest question is **who creates this resource today**. Catalog creates a
namespace, a Vault kv2 mount, auth roles, and RBAC for every onboarded app.
Where Terraform already creates the same resource, onboarding must adopt it,
import it, or remove it from state first. Getting that wrong leaves two owners
fighting over one live resource.

## Invocation

```text
/sd:catalog-adoption-check <owner/repo | https://github.com/owner/repo> [parent Jira key]
```

The optional second argument is the story the subtask manifest hangs off (Step 5).
Omit it and the manifest still renders, with the parent left as an `ASK`.

Called with no argument, print exactly this and stop:

```text
Usage: /sd:catalog-adoption-check <owner/repo | URL> [parent Jira key]

Emits a Catalog/Serenity V2 readiness report for one repository, plus a
subtask manifest for the work list.
Read-only: no PRs, no commits, no Jira issues, no cluster or Vault writes.

Examples:
  /sd:catalog-adoption-check commercetools/audit-log
  /sd:catalog-adoption-check commercetools/audit-log SD-2532
  /sd:catalog-adoption-check https://github.com/commercetools/mongodb-atlas-k8s-operator
```

## Hard rules

1. **Read-only.** Allowed: `gh api`/`gh repo view`, `git clone --depth 1`,
   `grep`, `kubectl get`/`describe`, `vault read`, and read-only Jira reads.
   Forbidden: `gh pr create`, `git push`, `git commit`,
   `kubectl apply`/`create`/`delete`/`patch`, `terraform apply`/`state rm`,
   `vault write`, and every Jira write — `createJiraIssue`, `createIssueLink`,
   `editJiraIssue`, `transitionJiraIssue`. Step 5 renders a subtask manifest as
   text; it never files a ticket.
2. **No unevidenced verdicts.** Every line names a file path, a line number, a
   cluster, or a command whose output backs it.
3. **No prose.** One line per finding. No paragraphs anywhere in the report.
4. **All twelve groups appear**, in order, in every report. A group you cannot
   evaluate emits an `ASK` naming the missing input. Never drop a group.
5. **No human input during the run, with one exception.** Questions become
   `ASK` lines; they do not pause the run. The exception is a Vault/kubectl
   session handoff (see *Vault and cluster sessions* in Step 1) — pause once
   to get the user to log in or switch environments, because that turns an
   `ASK` into a real verdict instead of a guess. Target ≤ 10 minutes
   wall-clock plus any session handoffs.

## Verdict grammar

| Verdict | Meaning | Required suffix |
| --- | --- | --- |
| `DONE` | Already satisfied, nothing to do | evidence pointer |
| `TODO` | Work required, can start today | `[<actor>]` |
| `BLOCKED` | Work required, waits on something else | `— waits on <thing>` then `[<actor>]` |
| `ASK` | A human must answer before a verdict exists | `[<who answers>]` |
| `NOTE` | Baseline fact the reader needs; carries no work either way | evidence pointer |

Actors are `[<app> team]`, `[SRE]`, or `[Special Delivery]`. A fact you could
not check is `ASK`, never `DONE`.

`NOTE` exists because some lines describe the world rather than judge it — most
often "here is what deploys this today". Do not spend `DONE` on those. `DONE`
promises the reader nothing remains to do, so putting it on a mechanism that a
later line schedules for deletion tells them the opposite of the truth. `NOTE`
never enters the work list.

---

## Report voice

Each line is a finding, not a sentence about a finding. Four rules govern every
line you write.

### Name the actor, then the actions it gets

A mechanism never acts. RBAC does not *reach* a workload — a Kubernetes group
gets verbs on objects. A whitelist does not *cover* a namespace — an ArgoCD
Application may create, update, and prune kinds in it. When a mechanism turns up
as the subject of an active verb, find the group, ServiceAccount, controller, or
binary that holds the access, put that in the subject position, and name the
verbs it gets.

```text
# Bad:
# "its RBAC reaches" — no subject holds the access and no verbs are named, so the
# reader cannot tell whether this is a grant to humans or an ArgoCD sync scope.
2.4 TODO  Dedicated Space for atlas-autoscaler. A Space composes one Namespace and one
          AppProject, so its RBAC reaches atlas-keys-rotator
```

```text
# Good:
# The Space creates a named RoleBinding; members of a named group get named verbs
# on named objects. The fact the argument rests on is an absence, so it is stated
# in prose: a RoleBinding cannot exclude objects inside its namespace.
2.4 TODO  Give atlas-autoscaler a dedicated Space. The Space creates RoleBinding
          space-editors naming ClusterRole edit, subject vault:<ownerVaultGroup>
          (space/templates/composition.yaml:359-379). A RoleBinding cannot exclude
          objects inside its namespace, so members of saypetabyte's Vault group get
          edit verbs on atlas-keys-rotator's CronJob and Jobs
```

Common swaps:

| Reach for | Write instead |
| --- | --- |
| X's RBAC reaches Y | members of group G get `<verbs>` on Y |
| the whitelist covers / grants | any Application in the project may create, update, prune |
| the guard fails | the composition's calls fail with `<message>` |
| `prevent_destroy` rules out X | Terraform refuses to destroy the mount, so X fails the plan |
| merging the XR fires the claim | CtRepositoryController creates the claim on merge |
| nothing takes a lock | neither instance takes a lock |
| `.Files.Glob` matches nothing | helm expands `.Files.Glob` to nothing, so helm renders only X |
| the cluster renders the AppProject | Crossplane on `<cluster>` renders the AppProject |
| `--atomic` rolls back a release | under `--atomic` helm rolls back a release |
| the app is deployed by | CircleCI runs `<command>` at `<file:line>` |

### One idea per line

Split a line that joins two mechanisms with *and* or *so* into two sub-numbered
lines carrying their own verdicts. A namespace RoleBinding and an AppProject sync
scope are two mechanisms with two actors, so they are two lines — not one line
with a conjunction.

### Verb-first on work

Open every `TODO` with the imperative naming the action: *Author
`spaces/<app>.yaml`*, *Repoint the 3 Vault k8s auth roles*, *Retire the helm
upgrade step*. A `TODO` opening with a noun phrase — *Vault role rename* — hides
who does what to which object.

A `BLOCKED` line takes the other shape, because its `— waits on <thing>` suffix
already names the action. Open it with the obstruction stated actor-first, so the
reader learns who creates the contended object:

```text
# Bad:
# Passive, so no actor: "is Terraform-managed" leaves the reader to guess whether
# a module, a literal resource, or a human made the mount. Repeating the
# action up front would also duplicate the waits-on clause.
3.2 BLOCKED  kv2/repositories/audit-log is Terraform-managed (secret-kv2.tf:36)
             — waits on terraform state rm  [SRE]
```

```text
# Good:
# Terraform is the subject and creates is the verb, so ownership is explicit. The
# action stays in the waits-on clause, named exactly once.
3.2 BLOCKED  Terraform creates the kv2/repositories/audit-log mount (secret-kv2.tf:36
             iterates repository_mappings), stack ctp-vault/vault/vault-config
             — waits on terraform state rm  [SRE]
```

Work-list entries are verb-first regardless of verdict — that list is a list of
actions, so `BLOCKED` reads *Remove the audit-log kv2 mount from Terraform state*.

### No closing prose

Hard rule 3 covers the sections after the report too. A "what makes this hard" or
"summary" section written as paragraphs breaks it. The eleven groups and the work
list already carry the reasoning; a closing point worth making is worth one line.

---

## Step 1 — Resolve inputs

Normalize the argument to `owner/repo`. You need four working copies: the target
repo, `ops-terraform`, `catalog` (renamed from `ct-apps`; the old name still
appears in this doc's earlier revisions and in some teams' local clone
directories — that is the same repo), and `k8s-gitops`. Prefer an existing local
clone under `~/github.com/<owner>/<repo>`; otherwise
`gh repo clone <r> <dir> -- --depth 1 --filter=blob:none` into a scratch
directory. `ops-terraform` and `k8s-gitops` are large, so `--filter=blob:none`
matters.

Check an existing clone before you read it.
`git -C <dir> remote get-url origin` must name the repo you were asked about,
and `git -C <dir> status --porcelain --branch` must report the default branch
with no modified files. A clone sitting on a feature branch with local edits
makes you cite a SHA no reviewer can look up. When any of those three fail,
clone fresh into the scratch directory rather than repairing the local copy.

Prefer a local `ops-terraform` for a second reason: it may carry
`.terraform/modules/`, which a fresh clone never does (see check 3). If a clone
fails, do not abort — emit `ASK` on every check that needed it, naming the repo
you could not read. Record the target repo's default branch and HEAD SHA; cite
line numbers against that SHA.

### Vault and cluster sessions

Production and staging are separate Vault clusters with separate addresses —
`https://vault.services.europe-west1.gcp.commercetools.com` (production) and
`https://vault.sre.europe-west1.gcp.commercetools.com` (staging) — and the
`vault` CLI and the `kubectl` exec-credential plugin share one on-disk
session. Logging into one environment invalidates the other, so only one is
ever live at a time.

Never gate on `vault token lookup` or `$VAULT_TOKEN`: the kubectl plugin's
OIDC session is independent of the vault CLI's token file, so a live kubectl
session can coexist with a `vault token lookup` 403. Probe with a direct
`kubectl` call against a reference cluster in the environment you need
instead — success proves the session is live, failure proves it is not:

```bash
kubectl --context ctp_production_sre-services_gcp_europe-west1_v1 get ns   # production
kubectl --context ctp_staging_gcp_europe-west1_v1 get ns                   # staging
```

The production reference cluster is also the Crossplane/Catalog
control-plane cluster check 11 reads for Argo host destinations, so a
successful probe there doubles as evidence for that check.

Assume production is the session already active when a run starts. Probe it
before the first check that reads it. If the probe fails, stop and ask the
user to log in to production Vault, naming the exact `VAULT_ADDR` above, then
re-probe — do not fall back to `ASK` on a check a login would answer.

Before any check needs a staging cluster or Vault read (namespace strategy
check 2, namespace-coupled dependencies check 10, cluster targets check 11),
stop and ask the user to confirm they have switched to the staging session,
naming its `VAULT_ADDR`. Do not attempt the switch yourself, and do not
assume the earlier production probe still holds afterward — re-probe with
the staging reference cluster before proceeding. This is the one exception
to hard rule 5: a session handoff is worth one pause, because it turns an
`ASK` into a real verdict.

Only emit `ASK` on the checks that needed the missing session when the user
declines to log in or switch.

---

## Step 2 — Run the twelve checks

Later checks reuse earlier answers, so a serial run is the safe reading order —
but eight of the twelve never touch a cluster, and running those one after
another is what pushes a run past hard rule 5's ten-minute target. Fan those
eight out across agents, then run the four cluster-dependent checks yourself.

### Fan out across agents

Split the work by **what the check reads**, not by check number. Checks 3, 4, 5,
6, 7, 8, 9, and 12 read files — the target repo, `ops-terraform`, `catalog`,
`k8s-gitops` — plus `gh api`. Five agents cover them:

| Agent | Checks | Reads | Why these travel together |
| --- | --- | --- | --- |
| `chart-shape` | 5, 6, 12 | `<chart>`, `.circleci/config.yml`, `deployment/scripts/*.sh` | All three walk the same chart templates, and 6's merge-timing branch and 12's release-name comparison both read the current `helm upgrade` command |
| `ci-secrets` | 7, 8 | `.circleci/config.yml`, `<chart>`, `ops-terraform/gcp/ctp-vault/vault/vault-config/` | 7's secrets sub-line must name the `kv2/repositories/<name>` mount that 8 resolves, so splitting them makes 7 cite a mount it never read |
| `terraform` | 3 | `ops-terraform`, `gh api repos/commercetools/terraform-modules` | The largest single check; its two-halves namespace hunt reads nothing another check needs |
| `catalog-xrs` | 4, and the CODEOWNERS and claim-grep sub-lines of 1 | `.github/CODEOWNERS`, `catalog/catalog`, `gh api repos/commercetools/<team>-gitops` | Check 4's file paths are keyed to the owning team that check 1 resolves from CODEOWNERS |
| `parallel-run` | 9 | target repo application source, `<chart>` | The only check that reads Go/Rust/Java source, so it opens files nothing else does |

Give every agent, in its prompt:

1. **Hard rules 1–4 verbatim.** An agent that has not read them will `gh pr
   create` or `git commit`. Rule 1's forbidden list is the part that matters.
2. **The full text of its checks**, copied from this file — not a summary, and
   not "run check 7". The checks carry the traps (indented `kind:`, the
   `for_each` payload, the vendored-subchart `-r` gap) that a paraphrase drops.
3. **The resolved inputs from Step 1**: `owner/repo`, the local clone path for
   each of the four repos, the target repo's default branch and HEAD SHA, the
   chart directory, and the namespace. An agent that resolves its own clone
   picks a different SHA and cites line numbers no reviewer can look up.
4. **The return format below.**

Each agent returns exactly two things:

- **Its report lines, already in final format** — group heading, sub-numbers,
  verdict, evidence pointer, actor. You concatenate these; you do not rewrite
  them. An agent returning prose findings for you to format is an agent whose
  work you have to redo.
- **A `needs-session` list**: every sub-line it could not settle because the
  answer requires a live `kubectl` or `vault` read. Each entry names the
  sub-number, the cluster or Vault path, and the command that would settle it.

Four rules bind the agents:

1. **No agent pauses for input.** Hard rule 5's one exception — the Vault/kubectl
   session handoff — belongs to the main thread alone, because only the main
   thread can ask the user. An agent that blocks on a login just stalls.
2. **No agent emits `ASK` for a missing cluster read.** `ASK` means *a human must
   answer*; a cluster read the main thread can perform is a `needs-session`
   entry. Spending `ASK` on it turns a real verdict into a question.
3. **No agent clones.** Step 1 resolves and validates the four working copies
   before any agent starts.
4. **No agent writes.** Hard rule 1 applies per-agent, and five agents make five
   chances to break it.

Where you cannot spawn agents, run all twelve serially in numeric order. The
report is identical; only the wall-clock changes.

### Run the cluster-dependent checks yourself

Checks 2, 10, and 11, and check 1's live namespace-label sub-line, need a session
— see *Vault and cluster sessions* in Step 1. Run them in the main thread, in
that order, because the session is a singleton: logging into staging invalidates
production, so every staging read has to happen inside one window. Start them
while the agents are still working; they read different things.

### Reconcile before printing

Five agents cannot see each other's answers, so five cross-check references
arrive unresolved. Settle each one after the fan-out returns:

| What arrives unresolved | What settles it |
| --- | --- |
| `needs-session` entries from every agent | Run the named command in the live session and turn each entry into a verdict. An entry left unrun is `ASK`, never `DONE` |
| Check 5's second `BLOCKED` line, on a shared namespace granting the GVK to neighbour apps | Check 2's conclusion. `chart-shape` never learned whether the namespace is shared, so add or drop the line here |
| Check 6's two merge-timing branches — same change as the ArgoCD adoption, or before it | Check 2 and check 7's retirement line. Only one branch survives; `chart-shape` returns both |
| Check 10, which applies only when the namespace changes | Check 2's conclusion. Unchanged namespace → one `DONE` line, per check 10 |
| Check 7's secrets replacement, naming the mount onboarding creates | Check 8's mount sub-line from the same agent — verify the path matches rather than assuming it |
| Check 3's namespace sub-line and check 2.2 citing one Terraform fact | The `terraform` agent produced the fact; make both lines cite the same file, line, and stack, and have 3 point at 2.2 |

### 1. Ownership

**Question:** which single team owns this app, and do all sources agree?

Read the catch-all (`*`) entry and any carve-out covering the chart or
`.circleci/` paths. Only one CODEOWNERS file applies: GitHub takes the first
that exists of `.github/CODEOWNERS`, root `CODEOWNERS`, `docs/CODEOWNERS`, and
ignores the rest, so a stale copy naming a different team is not a conflict to
report. Within that file GitHub applies **last match wins**, so a later, more
specific line silently overrides `*` for the paths it covers — and those are
exactly the paths onboarding modifies. Read every line, not just the first.

Then corroborate against the other two sources. Read the live owner label with
`kubectl --context <ctx> get ns <ns> -o jsonpath='{.metadata.labels}'`. Search
for an existing claim with `grep -rn "$REPO" catalog/catalog`. (The repo is
`commercetools/catalog`, formerly `ct-apps`; its own legacy `coco/` claims
directory no longer exists — do not search a path that is not there.)

`DONE` when the catch-all resolves to exactly one team and the namespace label
agrees. `ASK [<candidate teams>]` when the authoritative CODEOWNERS and the
namespace label disagree, when the catch-all lists more than one team, or when a
deploy-path carve-out names a different team.

### 2. Namespace strategy

**Question:** adopt the existing namespace in place, or create a fresh Space?

List what else runs there with
`kubectl --context <ctx> get deploy,sts,ds -n <ns>`, and cross-check
`k8s-gitops` and `catalog` for other apps targeting the same namespace. A Space
composes exactly one Namespace and one ArgoCD `AppProject`, both named after the
Space, and creates two `RoleBinding`s in that namespace: `space-editors` naming
`ClusterRole edit` with the owner team's Vault group as subject, and
`space-allowed-apps` naming `ClusterRole admin` with each `allowedApps` repo's
Vault group as subject
(`k8s-gitops/workspace/special-delivery/crossplane-compositions/catalog/charts/space/templates/composition.yaml:359-379,399-416`).
A `RoleBinding` cannot exclude objects inside its namespace, so those group
members get those verbs on **every** workload already there. Name the groups and
the verbs on the sub-line; do not write that RBAC "applies to" the namespace.

- Dedicated namespace → **adopt-in-place**. `DONE` on the isolation sub-line;
  authoring the Space XR belongs to check 4.
- Shared namespace → **new dedicated Space**. `TODO [<app> team]` for the new
  namespace, and check 10 now applies.

**Adopting a namespace that already exists.** The Space composition refuses to
adopt one silently. It reads the live namespace and fails unless the annotation
`platform.commercetools.com/space` already equals the Space name:

```bash
grep -n -A3 'platform.commercetools.com/space' \
  k8s-gitops/workspace/special-delivery/crossplane-compositions/catalog/charts/space/templates/composition.yaml
# -> :62 fails with "namespace %q already exists; to import it via a Space,
#    annotate it with platform.commercetools.com/space: <space>"
# -> :225 a Space-created namespace gets that annotation stamped on it
```

A namespace the Space created itself carries the annotation and reconciles. One
that helm, `kubegen`, or a human created does not, so the Space XR fails until
someone annotates it — `TODO [SRE]`. Cannot read the live namespace → `ASK [SRE]`,
never `DONE`.

### 3. Terraform-owned prerequisites (`ops-terraform`)

**Question:** for every resource Catalog would create, does Terraform already
create it — and if so, from which file, under which Spacelift stack?

Cover at minimum these four, each as its own sub-line:

| Resource | Where to search in `ops-terraform` |
| --- | --- |
| Namespace, per target cluster | `<cloud>/<project>/kubernetes/namespaces.tf`, and the `kubernetes-namespaces` module's `namespaces.json` (see below) |
| Vault kv2 mount, policies, k8s/CircleCI auth roles | `gcp/ctp-vault/vault/vault-config/` — `locals-repositories.tf`, `policies-repositories.tf`, `auth-k8s.tf`, `auth-oidc-circleci.tf`, `team-*.tf` |
| Workload Identity / IAM bindings keyed by namespace + ServiceAccount | `*/workload-identity/`, `*/iam/`, `vault_sa.tf` |
| RBAC, ServiceAccounts, DNS/ingress created outside the chart | `*/dns/`, `k8s-gitops/workspace/*` RBAC configs |

The namespace is the trap, and settling it takes three questions. Most clusters create
namespaces through the `kubernetes-namespaces` module, not a literal
`resource "kubernetes_namespace"`, so grepping the app name across `*.tf`
returns nothing — `namespaces.tf` is four lines (`module "ns"`, `source`,
`version`, `create = true`) and never names your app.

**Question one — is the name in the module payload?** The list lives in the module's
own `namespaces.json`, downloaded into each cluster directory:

```bash
find ops-terraform -name namespaces.json -print0 | xargs -0 grep -ln "\"$NAME\""
```

**Question two — does that directory actually create them?** The module iterates the
whole payload under `for_each = var.create ? jsondecode(file(...)) : {}` with no
per-cluster filter, so one payload is shipped to every cluster and only `create`
decides. A name in the JSON proves nothing on its own:

```bash
grep -rn -A4 'kubernetes-namespaces' <cluster-dir>/*.tf   # look for create = true
```

`audit-log` appears in 11 copies of `namespaces.json` but is Terraform-created
only where a reachable `create = true` sits — for its seven target clusters,
that is `ctp-production-au` alone. Report Terraform-managed only when **both** of
those hold.

**Question three — does the pinned module version carry the destroy guard?** A
Terraform-created namespace does not need handing over, because Terraform and the
Space composition can hold the same Namespace object at once. Three facts keep
them from fighting:

1. The module sets `lifecycle { ignore_changes = [metadata[0].labels] }` on
   `kubernetes_namespace.ns`, so Terraform stops reverting the labels the Space
   composition stamps.
2. [SD-2678](https://commercetools.atlassian.net/browse/SD-2678) adds
   `metadata[0].annotations["platform.commercetools.com/space"]` to the same
   `ignore_changes` list. Do not reason that the module leaves the annotation
   alone because its config never sets one — the provider manages
   `metadata.annotations` as a whole map, so a config that sets none plans every
   out-of-band annotation away:

   ```text
   ~ metadata {
       ~ annotations = {
           - "platform.commercetools.com/space" = "mongodb" -> null
         }
     }
   ```

   That plan strips the key the import guard reads, undoing the adoption on the
   next apply. The entry names the one key on purpose; a wildcard over all
   annotations would hide real drift.
3. The same ticket adds `prevent_destroy = true` to that `lifecycle` block, so
   Terraform refuses to destroy the namespace when a name leaves the
   `namespaces.json` payload or a consumer's `create` flips to false.
   `ignore_changes` does not cover that case: it suppresses field-level drift, not
   resource-existence changes.

So a Terraform-created namespace reads `TODO — waits on SD-2678 [SRE]`, never
`BLOCKED — waits on terraform state rm`. Name the module version each cluster
pins and say whether it already carries the guard: both guards ship in
`kubernetes-namespaces` 1.34.2, and a `~> 1.34.0` constraint accepts a patch, so
a cluster on that pin picks them up on its next apply with no constraint bump.
Check the pin anyway — a cluster stuck on an older minor, or on a wrapper whose
own pin is older, does need a bump. One change inside the module covers every
consumer, which is why per-cluster state surgery is the wrong shape of work for
namespaces.

Read the version from both levels when a wrapper is in play. A cluster directory
pinning `gcp-gke-environment ~> 2.1.0` says nothing about the namespace module:
that wrapper carries its own `kubernetes-namespaces` constraint in
`services/gcp/gke-environment/namespaces.tf`, and the wrapper's pin is the one
that decides. Cite both.

That also settles the transitive case. Where the module is pulled in transitively
(the AWS `eks` wrapper passes it down, so no `create` appears in the cluster
directory), you cannot read the effective value from the files — but the guard
lives inside the module and reaches every consumer, so the unread value gates
nothing. Report `NOTE`, naming the wrapper and the variable, rather than
`ASK [SRE]`.

If `.terraform/modules/` is absent — true of any fresh clone, since it is a
`terraform init` artifact — read the payload from the module source instead:
`gh api repos/commercetools/terraform-modules/contents/kubernetes/kubernetes-namespaces/namespaces.json`.
Note the version each cluster pins; the payloads drift between versions.

**Naming the owning stack.** The Spacelift stack for a Terraform directory is
the `stack_configs` entry whose `project_root` equals that directory:

```bash
grep -rn "project_root *= *\"gcp/ctp-production-au/kubernetes\"" ops-terraform --include='*.tf'
# -> gcp/spacelift/local-production.tf:29, inside local.production_expanded,
#    consumed by the spacelift-stack module -> stack "gcp/ctp-production-au/kubernetes"
```

**A grep hit is not proof of ownership.** Terraform files reference names
Crossplane owns. A `crossplane_`-prefixed Vault policy in a tfvars `policies = [
… ]` list is a *reference* to a policy `CtSecretStoreVault` composes, not a
policy Terraform creates. Trace the variable to the resource that consumes it
before calling anything Terraform-managed:

```bash
grep -rn "$NAME" ops-terraform/gcp/ctp-vault/vault/vault-config/environments/*.tfvars
# a hit inside k8s_auth_role_configs means Terraform creates a *k8s auth role*
# (auth-k8s.tf:67) that binds to a policy Crossplane created — two different owners
```

Catalog composes no Kubernetes auth role; `CtSecretStoreVault`'s only
`AuthBackendRole` is the `jwt` one on backend `oidc/circleci`. So a Terraform k8s
auth role is `DONE` — Terraform keeps it, no state surgery — while the mount and
policy it points at belong to Crossplane. Say which owner holds which object.

Verdict per sub-line:

- Not Terraform-managed → `DONE`, naming the search that came up empty.
- A Namespace the module creates → `TODO — waits on SD-2678 [SRE]`, carrying
  **both** the `ops-terraform` path and the stack name. The module guard in
  question three, not a state removal, is what makes the two writers safe.
- Any other object Catalog creates under the same name →
  `BLOCKED — waits on terraform state rm [SRE]`, carrying **both** the
  `ops-terraform` path and the stack name. Vault mounts and identity group
  aliases land here: nothing guards them, and Vault permits one alias per
  `(name, mount_accessor)`.
- Managed, but Catalog adopts rather than recreates → `TODO [SRE]`, `adopt` or
  `import`.
- Could not determine → `ASK [SRE]`. Never `DONE`.

### 4. Catalog resources to author

**Question:** which XRs land in `catalog`, and in which mode?

Files live at `catalog/catalog/<team>/{team.yaml,spaces/<app>.yaml,apps/<app>.yaml}`
(repo `commercetools/catalog`, formerly `ct-apps`; the repo carries a top-level
`catalog/` directory of its own, so the doubled segment is not a typo). Shapes
to match:

```yaml
# all three carry apiVersion: platform.commercetools.com/v1alpha1
# team.yaml
kind: Team
metadata: {name: <team>}
spec: {githubTeam: <team>, oktaGroup: <okta group>, gsuiteGroup: <team>@commercetools.com}
# spaces/<app>.yaml
kind: Space
metadata: {name: <space>, labels: {ct_owner: <team>}}
spec: {ownerTeamRef: <team>, allowedApps: {appRefs: [<app>]}}
# apps/<app>.yaml
kind: App
metadata: {name: <app>, labels: {ct_owner: <team>}}
spec:
  githubFullName: <owner/repo>
  circleciProjectUUID: <uuid>
  ownerTeamRef: <team>
  targetSpaceRef: <space>
  delivery: oci     # omit for the default gitops ApplicationSet mode
```

`delivery: oci` composes **no** ApplicationSet — `serenity alpha deploy` owns the
per-cluster ArgoCD `Application` directly. That is the V2 target mode; pick it
unless the app stays on the `serenity/sync` GitOps orb. `circleciProjectUUID` is
the CircleCI project UUID, not the GitHub repo id; if you cannot read it,
`ASK [<app> team]`.

**A merged App XR can still deliver nothing.** In `gitops` mode the composition
emits an ApplicationSet whose git generators scan
`commercetools/<ownerTeamRef>-gitops` for directories matching
`<cluster>/<targetSpaceRef>/<appName>` on the `development/live`, `staging/live`,
and `production/live` branches. No matching directory means zero Applications, so
the XR reconciles cleanly while deploying nothing. Check the paths rather than
inferring from the merge:

```bash
gh api 'repos/commercetools/<team>-gitops/git/trees/staging%2Flive?recursive=1' \
  --jq '.tree[].path' | grep '<space>/<app>'
```

Report an App merged in `gitops` mode with no matching path as `TODO`, not
`DONE` — the file exists, the delivery does not.

This group **always** emits at least one `TODO`, whether that is authoring a
missing XR, flipping `delivery`, or wiring up a mode that currently generates
nothing. Per-file `DONE` is correct for each XR that exists; it never makes the
group's `TODO` disappear.

### 5. Cluster-scoped resources

**Question:** does the chart install anything outside a namespace?

```bash
grep -rnE '^[[:space:]]*kind:[[:space:]]*(CustomResourceDefinition|ClusterRole|ClusterRoleBinding|ValidatingAdmissionPolicy|ValidatingAdmissionPolicyBinding|ValidatingWebhookConfiguration|MutatingWebhookConfiguration|PodSecurityPolicy|Namespace|StorageClass|PriorityClass)[[:space:]]*$' \
  <chart>/templates <chart>/crds crds 2>/dev/null
```

Do not anchor `kind:` to column 0 and do not restrict to `*.yaml`. Chart
templates indent, and named templates live in `_*.tpl` files —
`mongodb-atlas-k8s-operator` keeps every cluster-scoped object in
`deployment/charts/operator/templates/_*.tpl` and `templates/crds/_*.tpl`. The
trailing `[[:space:]]*$` drops `roleRef.kind: ClusterRole`, a reference rather
than a resource. Also read any top-level `crds/` directory and any
`crds.install` / `createClusterRoles` values flag: an upstream subchart can
install CRDs with no template in your repo.

None found → `DONE`. Any found → list each GVK, then judge them against the Space
`AppProject` whitelist. The Space composition sets
`namespaceResourceWhitelist: [{*,*}]` and never sets `clusterResourceWhitelist`,
so ArgoCD refuses to sync a cluster-scoped resource today. Confirm that is still
true before citing it:

```bash
grep -rn 'clusterResourceWhitelist' \
  k8s-gitops/workspace/special-delivery/crossplane-compositions/catalog/charts/space/templates/composition.yaml
```

No match means the composition still sets no `clusterResourceWhitelist`, so every
GVK you listed is `BLOCKED — waits on SD-2559 [Special Delivery]`. A match means
the gap moved rather than closed: read the entries. `group: '*'` paired with
`kind: '*'` covers everything, making those GVKs `DONE`; a narrower list leaves
`BLOCKED` on only the GVKs it omits.

Add a second `BLOCKED` line when the app both needs cluster-scoped resources and
shares its namespace (check 2): the whitelist is a property of the `AppProject`,
so it would grant the same GVK to every neighbour app. The only isolation is a
dedicated Space.

### 6. Chart source

**Question:** where does the chart come from, and is there more than one?

`serenity alpha deploy`'s `loadChart()` accepts four forms — all shipped:

| Form | Example |
| --- | --- |
| local directory | `./chart`, `packages-backend/k8s/audit-log` |
| OCI | `oci://<registry>/<repo>/<chart>:<version>` |
| direct `.tgz` | `https://host/path/chart-1.2.3.tgz` (plain `http` rejected) |
| classic index-based repo | `helm://<host>/<repo-path>?chart=<name>&version=<version>` |

Classic Helm repo support landed in SD-2558 (`chart_load.go`, `resolveHelmRepoChart`);
it is **no longer** a blocker. Private/authenticated repos and version ranges are
still unsupported — those are `ASK [Special Delivery]`.

Find every chart:

```bash
find <repo> -name Chart.yaml -not -path '*/.git/*' | grep -v '/charts/[^/]*/charts/'
```

Exclude only vendored subcharts (`<chart>/charts/<sub>/Chart.yaml`), not every
path containing `charts/` — both fixtures keep their chart under
`deployment/charts/<name>/`, so a blanket `-not -path '*/charts/*'` finds
nothing. More than one chart for one app means either consolidation work
(`TODO [<app> team]`) or a monorepo with one `serenity.yaml` per app (`DONE`).
Decide by checking whether the charts deploy to the same namespace and whether
one exists only to work around a CI-credentials split.

**Consolidating two already-live releases is an ownership transfer, not a file
move.** Helm stamps `meta.helm.sh/release-name` and `release-namespace` onto every
object a release owns. Folding a second chart's templates into the first and
running `helm upgrade <target-release>` over objects still stamped with the
donor release's name fails with *"invalid ownership metadata"* — Helm refuses to
adopt an object it does not already own. Confirm the annotation before
recommending a same-pipeline merge:

```bash
kubectl --context <ctx> get <kind> <name> -n <ns> -o jsonpath='{.metadata.annotations}'
```

- Merge lands **in the same change ArgoCD adopts the namespace** → `TODO
  [<app> team]`, no ownership conflict: ArgoCD applies from git directly and
  never checks Helm release ownership, so ownership friction never arises.
- Merge lands **before** that, while the app is still on direct-Helm CI → `TODO
  [<app> team]`, but the line must also name the annotation-patch step
  (`kubectl annotate --overwrite meta.helm.sh/release-name=<target>
  meta.helm.sh/release-namespace=<ns> <kind>/<name> ...` on every object being
  adopted) needed to avoid the ownership error. `helm uninstall <donor-release>`
  is **not** a substitute for that patch — it deletes by the donor release's
  stored manifest, not by annotation, and would take the live objects with it.

### 7. CI / delivery

**Question:** what deploys this today, and what replaces it?

```bash
grep -nE 'helm (upgrade|install)|release-chart|kubegen|serenity/(sync|approve|install)|serenity alpha deploy' \
  .circleci/config.yml deployment/scripts/*.sh 2>/dev/null
```

Emit these sub-lines, always:

- Current mechanism — `NOTE`, never `DONE`: the later "old step retired" line
  deletes this very mechanism, so `DONE` would tell the reader CI needs no work.
  Cite the file and lines, and call out any flag carrying behavior ArgoCD does
  not reproduce — `--atomic` rolls back a failed release and `--wait` blocks
  until healthy, so the app loses both at cutover.
- Secrets in chart values → do they survive OCI delivery? `serenity alpha deploy`
  renders the chart and publishes the **rendered** manifests as an OCI artifact.
  Any secret helm interpolates at deploy time is therefore baked into that
  artifact, and registries retain artifacts. Trace every Secret template back to
  where its values come from:

  ```bash
  grep -rn '^[[:space:]]*kind:[[:space:]]*Secret[[:space:]]*$' <chart>
  grep -rnE '\.Files\.Get|lookup[[:space:]]' <chart>
  grep -nE 'helm .*(--set|-f )|vault (kv )?(get|read)' .circleci/config.yml deployment/scripts/*.sh
  ```

  Search `<chart>`, not `<chart>/templates`: `-r` never descends into
  `<chart>/charts/<subchart>/templates`, so a vendored subchart's Secret stays
  invisible — the same trap check 5 warns about for CRDs. Then open each file
  that matched and read its whole `data`/`stringData` block. Any fixed `-A`
  window truncates a Secret with more keys than you guessed. Where the templating
  is too dynamic to read by eye, `helm template` with the tier's values file
  settles it — but `lookup` renders empty there, so rendering never replaces
  reading.

  A `stringData`/`data` key reading `.Values.<x>` that CI fills from Vault is
  `BLOCKED — waits on moving secrets out of chart values [<app> team]`. Name the
  replacement: an `ExternalSecret` against the `kv2/repositories/<name>` mount
  from check 8, which onboarding already creates. `mongocostique` renders
  `MONGOCOSTIQUE_CLIENT_SECRET_<i>` and `CONFLUENCE_API_TOKEN` into `stringData`
  (`templates/secret.yaml:8-15`) from a `mktemp` values file its deploy step
  fills with five `vault kv get` reads — swapping the deploy command without
  moving those first publishes live credentials to `europe-docker.pkg.dev`.
  `DONE` requires every `stringData`/`data` key to trace to something that is
  not a credential in the artifact — an `ExternalSecret`, or a value that is not
  secret. A hardcoded literal, `.Files.Get`, or `lookup` reading an existing
  cluster Secret bakes a credential in without ever touching `.Values`, so the
  absence of `.Values` proves nothing by itself. A key whose source you cannot
  determine is `ASK [<app> team]`, never `DONE`.
- `serenity.yaml` presence. Absent → `TODO [<app> team]`, naming the target
  cluster list from check 11.
- Deploy step switched to `serenity alpha deploy` → `TODO [<app> team]`. This
  waits on the secrets sub-line above whenever that one is `BLOCKED`; the switch
  is not a command swap while credentials still arrive through chart values.
- Old step retired → `TODO [<app> team]`; it must land in the same change ArgoCD
  takes over, so no window has two pipelines writing the same resources.
- In-cluster runner and `CIRCLE_OIDC_TOKEN`: grep the config for a
  `resource_class` naming a self-hosted runner and for `OIDC`.

Two config shapes exist; name which one the app should author.

```yaml
# serenity.yaml — read by the serenity/sync GitOps orb, per-tier cluster lists
chart: ./chart
name: <app>
staging:   {autoMerge: true, clusters: [{name: stg-gcp-eu-west1-v1, valuesFile: ./values/stg.yaml}]}
production: {clusters: [{name: prd-gcp-eu-west1-v1}]}
---
# serenity alpha deploy --config — version 2, snake_case, CEL target filter
version: 2
chart: ./chart
name: <app>
target_filter: cluster.name == "stg-gcp-eu-west1-v1"
```

The V2 target is `delivery: oci` plus the version-2 config. `target_filter`
restricting to one cluster is what makes a single-cluster pilot possible while
the old pipeline keeps deploying everywhere else.

### 8. Vault / secrets

**Question:** does the app's existing mount already match what Catalog creates?

For repo `<name>`, `CtSecretStoreVault` composes a kv2 mount at
`kv2/repositories/<name>`, a policy `crossplane_<name>_kv2-repository`, and a
CircleCI JWT auth role `crossplane_<name>`. `CtRepositoryController` creates
that claim for every `App`/`CtApp` unless the repo sits in `spec.unmanaged` —
onboarding triggers it whether or not anyone asked.

```bash
grep -rn "$NAME" ops-terraform/gcp/ctp-vault/vault/vault-config/locals-repositories.tf \
                 ops-terraform/gcp/ctp-vault/vault/vault-config/policies-*.tf
grep -rn 'vault_role\|VAULT_ROLE\|vault-role' .circleci/config.yml
```

- No entry at all → `DONE`, nothing to migrate. `CtSecretStoreVault` creates
  `kv2/repositories/<name>` fresh, and greps finding nothing means Terraform
  owns no mount to contend with — no `state rm`. Where Terraform *does* own the
  mount, `state rm` is the answer, because no module guard covers a Vault mount
  the way SD-2678 covers a namespace in check 3. The new mount starts empty, so
  wherever check 7 found the app's
  secrets arriving from today, populating it belongs to that line's work.
- Existing path is already `kv2/repositories/<name>` → `DONE`, adopt in place,
  no data migration. Cross-reference check 3 for who owns it in Terraform.
- Existing path differs (e.g. `secret/<name>`) → `BLOCKED — waits on the
  CtSecretStoreVault legacyMountPath override [Special Delivery]`. That field is
  designed in the SD-2459 page but **not built and not yet ticketed**; say so on
  the line rather than linking a ticket that does not exist. Without it, the new
  mount is created empty and the old one is dead weight after CI moves.
- CircleCI role not yet `crossplane_<name>` → `TODO [<app> team]`, noting it is a
  deliberate separate PR after the new mount is populated.

**The grep above only sees CI-time secrets.** If check 7 found the chart injects
secrets via an in-pod Vault Agent (annotations reading
`vault.hashicorp.com/agent-inject*`, or a values field like `authRole`/
`secretsPathPrefix` templated into an agent config map), that path is what the
*running pod* authenticates with — a separate credential from whatever CircleCI's
own `vault-role` fetches for CI-time secrets. Check it independently:

```bash
grep -rn 'authRole\|secretsPathPrefix\|vault\.hashicorp\.com/agent' <chart>/values.yaml <chart>/templates
```

Both must resolve to the `kv2/repositories/<name>` convention on their own; one
matching does not imply the other does. `audit-log`'s pod-side `authRole: audit-log`
(`values.yaml:100`) already matches — cite it as its own sub-line, `DONE`, distinct
from the CircleCI-role sub-line above.

### 9. Parallel-run safety

**Question:** can the old and new stacks run side by side, or is it one switch?

```bash
grep -rniE 'leader.?elect|LeaderElection|lease' --include='*.go' --include='*.rs' --include='*.java' <repo>
grep -rnE 'Api::all|NewControllerManagedBy|informers\.' <repo>
grep -rnE '^[[:space:]]*kind:[[:space:]]*StatefulSet' <chart>   # then read volumeClaimTemplates
```

- Stateless horizontally-scalable service → `DONE`, side-by-side validation in
  one cluster is safe.
- Controller/operator watching cluster-wide with no leader election →
  `BLOCKED — waits on a single-switch cutover window [SRE + <app> team]`. Two live
  instances would reconcile the same custom resources with no coordination.
- Same release name into the same namespace → `TODO [<app> team]`. ArgoCD renders
  the chart under the app name, and the old `helm upgrade --install` used that
  same name, so both write the same objects until the old step is gone. This is
  ownership, not data: it applies even to a stateless app that passed every check
  above. Sequence it with the check-7 switch and retirement as one change.
- StatefulSet with PVCs → `ASK [<app> team]`: is the data durable, or a
  rebuildable cache? Note on the line that `volumeClaimTemplates` is immutable,
  so a mismatch is fixed by changing the chart, never by deleting and recreating
  the StatefulSet. Check `persistentVolumeClaimRetentionPolicy`: unset means
  Kubernetes' `Retain` default, which lowers the risk either way.
- Bare `kind: Job` template (not `CronJob`) → `TODO [<app> team]`, naming the Job.
  A Job's spec is immutable, which Helm's imperative `upgrade --install` tolerates
  silently (it just skips a Job that already matches) but ArgoCD's declarative
  sync does not — any change to a `kind: Job` resource's spec (image, env, node
  count) is a hard sync failure, not a rollout. Recommend converting it to an
  ArgoCD `PostSync` hook with `hook-delete-policy: BeforeHookCreation`, which
  deletes the previous run before creating the next one and also fixes any Helm
  ordering the Job relied on (e.g. running only after a StatefulSet's pods exist).

  ```bash
  grep -rnE '^[[:space:]]*kind:[[:space:]]*Job[[:space:]]*$' <chart>/templates
  ```

### 10. Namespace-coupled dependencies

Applies **only** when check 2 concluded the namespace changes. When it does not,
emit one `DONE` line: the namespace is unchanged, so nothing is coupled. When it
does, emit six sub-lines, each with its own verdict:

```bash
grep -rn "$OLDNS\.svc" .                              # in-cluster DNS callers
grep -rnE '^[[:space:]]*kind:[[:space:]]*(Ingress|BackendConfig)' <chart>  # ingress / LB / DNS
grep -rn 'namespaceSelector\|namespace:' <chart>/templates/*networkpolicy*
grep -rn 'namespaceSelector' <chart>/templates/*monitor*   # Prometheus selectors
grep -rn "$OLDNS" ops-terraform --include='*.tf'      # Vault k8s auth role binding
grep -rn "\"$OLDNS\"\|: $OLDNS" <chart>/templates     # hardcoded namespace strings
```

The last one matters most: a literal namespace where `{{ .Release.Namespace }}`
belongs fails quietly only after the app is deployed into the new namespace.

### 11. Cluster targets

**Question:** where does it deploy today, and which clusters go into the first
`serenity.yaml`?

Read today's targets from the CircleCI deploy jobs and from k8s-gitops. Translate
kubectl/Terraform cluster names into Serenity cluster names with this table — the
authoritative list is the `$Clusters` literal in
`k8s-gitops/workspace/special-delivery/crossplane-compositions/ctteam-composition/charts/ctteam-composition/templates/composition.yaml`;
re-read it rather than trusting this copy if a name is missing.

| Terraform / kubectl name | Serenity cluster name | Tier |
| --- | --- | --- |
| `ctp-playground` | `plg-gcp-eu-west1-v1` | development |
| `ctp-staging` | `stg-gcp-eu-west1-v1` | staging |
| `ctp-aws-staging-eu` | `stg-aws-eu-central1-v1` | staging |
| `ctp-production-eu` | `prd-gcp-eu-west1-v1` | production |
| `ctp-production-us` | `prd-gcp-us-central1-v1` | production |
| `ctp-production-au` | `prd-gcp-au-southeast1-v1` | production |
| `ctp-aws-production-fra` | `prd-aws-eu-central1-v1` | production |
| `ctp-aws-production-ohio` | `prd-aws-us-east2-v1` | production |
| `ctp-gcp-performance-test` | `prd-gcp-eu-west1-perf` | production |
| `vw_staging_aws_eu-central-1_v1` | `stg-aws-eu-central1-vw` | staging |
| `vw_production_aws_eu-central-1_v1` | `prd-aws-eu-central1-vw` | production |
| `sre-services` | `prd-gcp-eu-west1-sre-services` | production |

A cluster the app deploys to today that has **no** row in `$Clusters` is not a
Catalog target at all — `reference_service` ships to
`att_production_aws_us-east-1_v1`, which is absent. Emit
`BLOCKED — waits on adding the cluster to the CtTeam cluster list [Special Delivery]`,
not a silent omission.

Recommend the first `serenity.yaml` cover exactly one low-risk cluster (staging
if it exists), and name which clusters follow in the batch. The SRE Services
cluster is not an available Catalog target yet — targeting it is
`BLOCKED — waits on SD-2555 [Special Delivery]`.

**A row in `$Clusters` is necessary, not sufficient.** The Space `AppProject`'s
`destinations` come from the `managed-clusters-by-argo` EnvironmentConfig of
whichever Argo host renders that Space, and the hosts carry different lists:

```bash
grep -rn -A15 'managedClustersByArgo:' \
  k8s-gitops/workspace/special-delivery/crossplane/crossplane-environment-configs/values-cluster-*.yaml
# sre-services  -> all 13 clusters
# staging-gcp   -> plg-gcp-eu-west1-v1, plg-aws-eu-central1-v1 only
```

ArgoCD rejects a sync to a cluster absent from `destinations`, so name which host
renders the Space and confirm the target cluster appears in that host's list.
Cannot determine which host → `ASK [Special Delivery]`.

### 12. Release identity

**Question:** does the chart bake the Helm release name into any resource's
identity, and if so, does Serenity render under the same name that's live today?

Neither delivery mode lets the release name diverge from the App resource's own
name — there is no override, not a missing confirmation:

- `serenity.yaml`'s `name:` becomes the release name directly:
  `client.ReleaseName = r.config.Name` (`serenity` repo, `pkg/render/render.go`).
- `serenity alpha deploy --name`'s own help text requires it: *"Argo CD
  Application name (required; or 'name' in --config). Must match the App resource
  name or the CtApp claim name onboarded for this service."* That same value flows
  unchanged into the render (`pkg/serenityv1alpha/deploy/cmd.go`,
  `orchestrator.go`, `render.go`: `ReleaseName: releaseName`).

So whatever the App XR is named — the repo/app name, by check 4's own shape — is
the release name Serenity renders with, in both modes, always.

```bash
grep -rn '{{[[:space:]]*\.Release\.Name' <chart>/templates
```

None found → `DONE`. Nothing in the chart is keyed to the release name, so a
different one changes nothing.

Any found → compare against what actually deploys it today:

```bash
grep -nE 'helm (upgrade|install)' .circleci/config.yml deployment/scripts/*.sh
```

- Current release name already equals the app/repo name → `DONE`, Serenity's
  forced name matches what's live; nothing renames at cutover.
- Current release name is a fixed string unrelated to the repo name (e.g. `main`)
  → `BLOCKED — waits on a managed rename window [<app> team]`. Kubernetes has no
  in-place rename: every `.Release.Name`-templated resource gets a new identity
  the first time ArgoCD syncs — the old one pruned, a new one created, not
  updated. Name each such resource that is also externally addressed (an Ingress
  backend, a `BackendConfig`, a private-link route, anything an external DNS/LB
  config references by name) — those carry the real availability risk during the
  swap; a resource referenced only from inside the same chart re-wires itself
  automatically and is lower-risk. Recommend the ArgoCD sync option
  `PruneLast=true` so new objects go healthy before the old ones are pruned,
  closing the gap for anything Ingress-fronted. `audit-log`'s
  `main-change-history-api` Service — backing a public Ingress, a GCP
  `BackendConfig`, and an AWS private-link `HTTPRoute` — is exactly this case;
  `deploy-backend.sh:53` hardcodes release name `main`, unrelated to the repo name.
- A resource with a hardcoded literal name (no `.Release.Name` at all — e.g. a
  StatefulSet named `redis`) survives a release rename untouched regardless of the
  verdict above — cite it on its own `DONE` line so the rename's blast radius
  isn't overstated to include everything in the chart.

---

## Step 3 — Emit the report

Print the twelve groups in order. Each heading carries the number and, where one
exists, the conclusion (`2. Namespace strategy: adopt-in-place`). Sub-number
(`2.1`, `2.2`) only when the group needs more than one independent task. Align
verdicts in a column.

```text
1. Ownership
   DONE     CODEOWNERS catch-all resolves to one team: users-access-audit (.github/CODEOWNERS:3)
2. Namespace strategy: adopt-in-place
   2.1 DONE     audit-log namespace holds no other app's workloads (kubectl get deploy,sts -n audit-log)
   2.2 TODO     Terraform creates the ctp-production-au namespace (namespaces.tf:4 sets
                create = true, name in module ns payload namespaces.json:118), stack
                gcp/ctp-production-au/kubernetes — waits on SD-2678  [SRE]
3. Terraform-owned prerequisites
   3.1 DONE     Vault kv2 mount: no Terraform resource creates it — grep over
                vault-config/locals-repositories.tf and policies-repositories.tf returns
                nothing; the path is already kv2/repositories/audit-log
   3.2 TODO     Terraform creates the ctp-production-au namespace (namespaces.tf:4 sets
                create = true), stack gcp/ctp-production-au/kubernetes; the directory
                pins ~> 1.34.0, which accepts the 1.34.2 guards once released, and the
                Space composition manages the same object — see 2.2
                — waits on SD-2678  [SRE]
   ...
```

## Step 4 — Work list

Close with every `TODO`, `BLOCKED`, and `ASK` line, in dependency order — a line
appears after everything it waits on. `DONE` and `NOTE` lines stay out: neither
carries work. Keep the group number so the reader can jump back, and keep the
actor.

```text
Work list
 1. ASK      [audit-log team]      Redis data: durable or rebuildable cache?              (9)
 2. ASK      [audit-log team]      Confirm users-access-audit as team of record           (1)
 3. TODO     [audit-log team]      Fold audit-log-roles RBAC into the main chart          (6.2)
 4. TODO     [audit-log team]      Author serenity.yaml, staging cluster only             (7.2)
 5. TODO     [Special Delivery]    Author Team/Space/App XRs in catalog/catalog/uaa/       (4)
 6. TODO     [SRE]                 Land SD-2678, the prevent_destroy guard on the AU ns   (2.2)
 7. TODO     [audit-log team]      Switch deploy step to serenity alpha deploy            (7.3)
 8. TODO     [audit-log team]      Retire the helm upgrade step, same change as 7         (7.4)
```

Then a **platform dependencies** block — only the rows the report cites:

| Dependency | Status | Reference |
| --- | --- | --- |
| `clusterResourceWhitelist` on the Space `AppProject` | not built | [SD-2559](https://commercetools.atlassian.net/browse/SD-2559), [SD-2533](https://commercetools.atlassian.net/browse/SD-2533) |
| Catalog workloads on the SRE Services cluster | not built | [SD-2555](https://commercetools.atlassian.net/browse/SD-2555) |
| Classic Helm repo support in `loadChart()` | **shipped** | [SD-2558](https://commercetools.atlassian.net/browse/SD-2558) |
| `CtSecretStoreVault.spec.legacyMountPath` | designed, not built, **no ticket filed** | [SD-2459 page](https://commercetools.atlassian.net/wiki/spaces/~62e0a3cf3aaeedcae756073b/pages/3516956695/) |
| `prevent_destroy` plus the scoped annotation ignore on the `kubernetes-namespaces` module | filed, not merged | [SD-2678](https://commercetools.atlassian.net/browse/SD-2678) |

---

## Step 5 — Subtask manifest

The work list is already one action per row, dependency-ordered, with an actor —
which is the shape a Jira subtask list wants. Render it as a manifest so nobody
retypes seventeen rows into Jira by hand.

**The manifest creates nothing.** Hard rule 1 holds: no `createJiraIssue`, no
`createIssueLink`, no `editJiraIssue`. The manifest is text for a human to paste
or for a separate create-skill to consume. A skill that files tickets from a
report it just generated gives the reader no chance to reject a row first.

One block per work-list row, in work-list order:

```text
Subtask 6
  summary:     Land SD-2678 so Terraform stops threatening the ctp-production-au namespace
  parent:      SD-2532
  actor:       SRE
  blocked by:  SD-2678
  blocks:      7, 8
  source:      2.2, 3.2
  description:
    Terraform creates the ctp-production-au namespace: namespaces.tf:4 sets
    create = true, and the name appears in the module ns payload
    namespaces.json:118. Stack gcp/ctp-production-au/kubernetes.

    The Space composition manages the same Namespace object, so two writers hold
    it. Module 1.34.2 makes them coexist: ignore_changes covers metadata[0].labels
    and the one annotation key platform.commercetools.com/space, which the
    provider would otherwise plan to null and strip the adoption; prevent_destroy
    stops any plan deleting the namespace. No state removal. The directory pins
    ~> 1.34.0, which accepts 1.34.2, so no constraint bump is needed — but the
    annotation in subtask 3 only survives once that release has applied here.
```

### Field rules

- **`summary`** — the work-list entry's own text, imperative and verb-first,
  under 255 characters. An `ASK` row is a question in the report and an action
  here: *Redis data: durable or rebuildable cache?* becomes *Confirm whether
  Redis data is durable or a rebuildable cache*. A summary that opens with a noun
  phrase makes a Jira board unreadable.
- **`parent`** — the Jira key passed as the invocation's second argument. Without
  one, write `parent: <story key — ASK [requester]>` and keep going; the manifest
  is still valid, it just cannot be pasted yet.
- **`actor`** — the actor bracket verbatim: `<app> team`, `SRE`, or
  `Special Delivery`. Name the team, never a person. The skill reads CODEOWNERS,
  which names teams, so inventing an assignee guesses.
- **`blocked by`** / **`blocks`** — row numbers, not ticket keys, because no
  ticket exists yet. Every `BLOCKED` row carries at least one `blocked by` entry:
  either a row number, when the thing it waits on is another row, or a platform
  ticket from the dependencies table (`blocked by: SD-2559`) when it is not.
  A `— waits on` clause naming something with no ticket — the
  `CtSecretStoreVault.spec.legacyMountPath` field, a cutover window — reads
  `blocked by: (untracked) <thing>`, so nobody mistakes it for scheduled work.
- **`source`** — every group sub-number that produced the row. Two sub-numbers
  appear when the reconcile step merged one fact reported twice, as checks 2.2
  and 3.2 do on the Terraform namespace. One subtask per action, never one per
  citation.
- **`description`** — the report line's evidence pointer first, then why the
  action is what it is. Paragraphs are allowed **here only**: hard rule 3 governs
  the report, and a Jira description a reader opens cold needs more than a
  verdict line. Keep it to two short paragraphs.

### What does not become a subtask

`DONE` and `NOTE` lines carry no work, so they stay out — same rule as the work
list. Do not emit a subtask per check group either: a group holds sub-lines with
different actors and different blockers, so one subtask per group would assign
work to the wrong team and lose the ordering.

Close the manifest with the row count and a one-line statement that nothing was
created, so a reader skimming the tail knows the state of the world:

```text
17 subtasks, none created. Parent SD-2532.
```

---

## Self-check before printing

- [ ] All twelve groups present, in order.
- [ ] Every line carries exactly one of `DONE` / `TODO` / `BLOCKED` / `ASK` / `NOTE`.
- [ ] Check 7's current-mechanism line is `NOTE`, not `DONE`.
- [ ] Check 7 traced every Secret template to the source of its values, and said
      whether OCI delivery would publish them.
- [ ] Every `TODO` and `ASK` names an actor; every `BLOCKED` names what it waits on.
- [ ] Every check-3 sub-line says Terraform-managed or not; managed ones name the
      file path **and** the Spacelift stack **and** one of adopt / import /
      remove-from-state. No `DONE` on an unknown.
- [ ] At least one `TODO` for the Catalog XRs, one for `serenity.yaml`, one for
      retiring the old deploy step — even on a clean repo.
- [ ] Every Terraform grep hit names which owner creates the object, not just
      which file mentions it.
- [ ] A merged App XR in `gitops` mode was checked against the owner's gitops
      repo for a matching path, not assumed to be delivering.
- [ ] Check 11 named the Argo host rendering the Space and confirmed the target
      cluster sits in that host's `managedClustersByArgo`.
- [ ] Check 12 checked every `.Release.Name`-templated resource against the
      release name the current deploy step actually uses, not just whether the
      chart happens to template it.
- [ ] No paragraph anywhere in the report.
- [ ] Work list is in dependency order and every entry traces back to a group number.
- [ ] Nothing was written: no PR, no commit, no cluster/Vault/Terraform mutation —
      by the main thread or by any agent.
- [ ] Every `needs-session` entry the agents returned was run in a live session,
      not carried into the report as `ASK`.
- [ ] Every row of the reconcile table in Step 2 was settled: checks 5, 6, and 10
      reflect check 2's conclusion, and checks 3 and 2.2 cite the same Terraform
      file, line, and stack.
- [ ] The subtask manifest has one block per work-list row and no more — no `DONE`
      or `NOTE` line became a subtask, and no group became one subtask covering
      sub-lines with different actors.
- [ ] Every manifest `summary` is imperative and verb-first, including the ones
      built from `ASK` rows.
- [ ] Every `BLOCKED` row's manifest block carries a `blocked by` entry: a row
      number, a platform ticket key, or `(untracked)` naming the thing.
- [ ] The manifest closes with the row count and states that nothing was created.

## References

- `reference/checklist.md` in this directory — every check above as a one-line
  checkbox, grouped the same way, plus pre-flight and pre-print gates. Work
  through it during a run; this file explains *why* each check exists, that one
  states *what* to check.

- `fixtures.md` in this directory — hand-verified expected answers for
  `audit-log`, `mongodb-atlas-k8s-operator`, `reference_service`, and
  `mongocostique`. Read it when changing this skill, not during a normal run.

- [SD-2459: Onboarding Non-Catalog Infra/Product Apps to Serenity](https://commercetools.atlassian.net/wiki/spaces/~62e0a3cf3aaeedcae756073b/pages/3516956695/) — source of the original eleven check groups.
- [Migration Plan: commercetools/audit-log → Catalog](https://commercetools.atlassian.net/wiki/spaces/~62e0a3cf3aaeedcae756073b/pages/3542155288/) — the audit-log fixture.
- `commercetools/serenity` — `pkg/render/render.go`, `pkg/config/config.go`, and
  `pkg/serenityv1alpha/deploy/{cmd,orchestrator,render}.go` are the source for
  check 12: the release name is always the App/Application name, in both
  delivery modes, with no override field.
- [Serenity configuration](https://sd.commercetools.com/getting-started/service-delivery-platform/serenity/configuration) and [monorepo](https://sd.commercetools.com/getting-started/service-delivery-platform/serenity/monorepo) docs.
- `commercetools/ops-terraform` `AGENTS.md` — directory layout and module conventions.
