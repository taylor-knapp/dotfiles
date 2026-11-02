---
name: sd:serenity-v2-migrate
description: 'Use this skill when a service already deploying through Serenity v1 needs to move to Serenity V2, or when someone asks to translate a serenity.yaml and .circleci/config.yml into the `serenity alpha deploy` setup. Rewrites each serenity.yaml in place into the v2 schema (no target_filter in the file, environment chosen per run via --target-filter), rewrites the CircleCI workflow onto a parameterised deploy job, and emits the one-line Catalog patch, a cluster-coverage proof, a parity check, and the ordered cutover checklist. Pauses to ask the owner when a v1 job''s promotion gating has no single correct translation. Writes files on a branch and stops: it merges nothing, flips no delivery field, and runs no deploy.'
---

# Serenity v1 to V2 Migration

## Purpose

Turn a working v1 setup into a working V2 setup without a downtime window and
without losing a cluster on the way.

v1 describes a service as one `serenity.yaml` with `development` / `staging` /
`production` sections, driven by the `serenity/sync` and `serenity/approve` ORB
jobs. V2 has no environments key and no ORB job: one config file, one `run` step,
and a CEL filter that picks the clusters per invocation.

The translation is mechanical, and the mechanical parts are where it goes wrong.
Three mistakes account for nearly all of it: a per-cluster `valuesFile` put into
`values_files`, where it applies to every cluster; a target filter that does not
cover exactly the clusters holding GitOps directories today, which strands an
Application on Git or creates a new deployment; and `prune: true` silently
deleting a resource v1 left alone. This skill exists to catch all three.

## Invocation

```text
/serenity-v2-migrate [path-to-repo]
```

No argument means the current working directory. With no `serenity.yaml`
anywhere in the tree, print exactly this and stop:

```text
Usage: /serenity-v2-migrate [path-to-repo]

No serenity.yaml found under <path>. This service is not on v1.
For a service that has never deployed through Serenity, follow
docs/.../serenity-v2/onboarding.mdx instead.
```

## Hard rules

Violating any of these produces a migration that looks right and is not.

1. **Read-only outside the working tree.** Allowed: reading files, `git log`,
   `gh api`, `helm template`, `kubectl get`/`describe`. Forbidden: `git push`,
   `gh pr create`, `gh pr merge`, `kubectl apply`/`patch`/`delete`, and running
   `serenity alpha deploy`. The skill writes files on a local branch and hands
   the user a checklist.

2. **Never run `serenity alpha deploy` as a dry run.** The deploy server does not
   read `App.spec.delivery` (`pkg/serenityv1alpha/deploy` contains no reference
   to it). A deploy against a still-`gitops` App succeeds and puts the
   ApplicationSet and the deploy server in contention over the same Application.
   That is the one state the whole cutover sequence exists to avoid.

3. **A v1 `clusters[].valuesFile` becomes a `config_layers` entry. Never
   `values_files`.** `values_files` is global: it applies to every cluster the
   run matches. A per-cluster file placed there silently leaks into every other
   cluster in the same environment.

4. **Never add the chart's own `values.yaml` to `values_files`.** Helm already
   loads `<chart>/values.yaml`. Listing it again is at best a no-op and at worst
   reorders the merge stack. v1 had no global values concept, so the correct
   default for a translated config is **no `values_files` key at all**.

5. **Target filters for a migration are `cluster.name` only.** Never emit a
   `cluster.labels[...]` filter during a migration, however tempting. The filter
   must match exactly the clusters that have GitOps directories today. A label
   filter can pick up a cluster that has no directory, and that is not an
   adoption, it is a new deployment. Label filters are a fine thing to move to
   later, once V2 owns the Applications.

6. **Every v1 cluster appears in exactly one target filter.** Prove it with the
   coverage table in Step 5. A cluster in zero filters stays orphaned on Git
   forever. A cluster in two filters gets deployed twice per pipeline run.

7. **Rewrite `serenity.yaml` in place. One file per component, never one per
   environment.** No new `deploy.yaml`; the path the team already knows keeps
   working. The single-file layout is the point: `chart` and `name` written once,
   `target_filter` omitted from the file and supplied per run. A monorepo with N
   `serenity.yaml` files rewrites all N, each still covering every environment
   that component deploys to.

8. **State what has no equivalent.** Do not silently drop a v1 flag. Every
   `serenity/sync` and `serenity/approve` parameter either maps to something or
   appears in the "no equivalent" list in the final report.

---

## Step 1: Inventory, before writing anything

Read. Do not edit yet.

```sh
find . -name serenity.yaml -not -path './.git/*'
cat .circleci/config.yml
```

From each `serenity.yaml` record: `chart`, `name`, and for each of
`development` / `staging` / `production` the cluster names, each cluster's
`valuesFile` if present, and whether `autoMerge` is set.

From `.circleci/config.yml` record every `serenity/sync` and `serenity/approve`
job and, for each: `config_file`, `dev`, `sideload`, `environment`, `image_tag`,
`image_tag_value_path`, `wait`, `wait_timeout`, `warn_only`, `validate`,
`extra_flags`, `requires`, and branch `filters`. Also the orb version, the
executor image, and any non-Serenity job the deploy jobs depend on.

Then read the chart to find the key the image tag is actually written to:

```sh
grep -rn '\.Values\.image' <chart>/templates/
```

`image_tag_value_path` names a key; the chart is what proves the key exists.
Confirm they agree before translating, because a tag written to the wrong key
still deploys green with a stale image.

Then confirm the config matches reality: the config is a claim, the cluster is
the fact. Resolve the kubectl context first, because **local context names are
not Argo cluster names.** `kubectl config get-contexts -o name` and pick the
sre-services one (usually `gke_ct-services_europe-west1_sre-services` or
`ctp_production_sre-services_gcp_europe-west1_v1`, never
`prd-gcp-eu-west1-sre-services`).

```sh
SRE=<resolved-context>
kubectl --context $SRE -n argocd-infra \
  get applications -l ct_service=<app> \
  -o custom-columns=NAME:.metadata.name,DEST:.spec.destination.name,SYNC:.status.sync.status,REPO:.spec.source.repoURL
```

Those Application names are `<app>-<cluster>`, which is the exact name V2
computes. That is why the first V2 deploy adopts them in place rather than
creating duplicates. If a cluster appears here that is not in `serenity.yaml`, or
the other way round, stop and resolve it before translating: the discrepancy is
the migration risk, not the YAML.

Finally, confirm this app's ApplicationSet will orphan rather than delete its
children when Crossplane drops it. This is per-app observable and it is the
difference between an adoption and an outage:

```sh
kubectl --context $SRE -n argocd-infra get applicationset <app> \
  -o jsonpath='{.metadata.finalizers}{"\n"}{.spec.syncPolicy}{"\n"}'
```

Both must be present: `resources-finalizer.argocd.argoproj.io` in the finalizers,
and `applicationsSync: create-update` in the sync policy. Either one alone still
leaves the children owned and garbage-collected. If both are there, say so in the
report as a passed pre-flight. If either is missing, that is a blocker for
Special Delivery, not something the service team can fix.

Emit the inventory as a table before proceeding. See
[reference/translation.md](reference/translation.md) for the full parameter
inventory to check against.

## Step 2: Resolve the environment-to-cluster mapping

v1 encodes the environment in the ORB job flags, not only in the config file:

| On the `serenity/sync` job | Clusters it targets |
| --- | --- |
| `dev: true` | the `development` section |
| `sideload: true` | the `staging` section |
| neither | `staging` **and** `production` |
| `serenity/approve` with `environment: production` | the `production` section, behind the merge gate |

Resolve every deploy job to a concrete cluster list. This mapping, not the
section names, is what becomes the target filters.

Job names in v1 frequently lie. A job called `sync-dev` carrying `sideload: true`
targets staging, not development. Name the V2 jobs after the clusters they
actually reach and note the rename in the report.

### Stop and ask: the bare `serenity/sync` split

A bare `serenity/sync` job (no `dev`, no `sideload`) wrote to staging **and**
production in one go. V2 has no equivalent shape, so it has to become two jobs,
and how they are gated is the owner's decision, not yours.

**Ask before writing the pipeline. Do not assume, and do not write the files and
mention it afterwards.** Getting this wrong either removes a production gate the
team relies on, or adds a manual step to a pipeline that was deliberately
automatic. Both are the owner's call to make with their release process in mind.

Work out the `autoMerge` state first, because it decides which recommendation you
give:

| `staging.autoMerge` | `production.autoMerge` | Splitting with an approval hold is |
| --- | --- | --- |
| `true` | absent | **behaviour-preserving.** Staging already deployed on merge; production sat in an unmerged PR until `serenity/approve`. Recommend it |
| `true` | `true` | **a behaviour change.** Production used to deploy without a human. Recommend the hold anyway, but say plainly that it adds a step |
| absent | absent | **a behaviour change.** Both used to wait for an `approve` run. A single hold in front of production loses the staging gate |

Then put the question to the user, naming the actual clusters and the `autoMerge`
state you found, with a recommendation. Offer the realistic shapes: staging then
an approval hold then production (the default); one job deploying both clusters
at once (stays fully automatic, loses the gate); or staging only, with production
promoted by a separate trigger.

Build whatever they choose. Do not re-litigate it in the report; record it as the
owner's decision.

## Step 3: Rewrite `serenity.yaml` in place

**Overwrite the existing `serenity.yaml`. Do not create a new file.** The path
already exists, CI already points at it, and the team already knows it. A
monorepo rewrites each component's own `serenity.yaml` where it sits.

It is also the safer option, because a half-migrated repo then fails loudly in
both directions. The schemas are mutually unparseable: V2 requires `version: 2`
and rejects a file without it (`deploy config is missing the required 'version'
field`), and a v1 `serenity sync` reading the rewritten file finds no
`development` / `staging` / `production` sections. A leftover `sync` job cannot
quietly keep working against the old shape.

Show the user a before-and-after diff, not just the result.

```yaml
version: 2
chart: ./chart
name: <App metadata.name>
config_layers:
  - target: 'cluster.name == "stg-gcp-eu-west1-v1"'
    values:
      - ./chart/values/stg-gcp-eu-west1-v1.yaml
  - target: 'cluster.name == "prd-gcp-eu-west1-sre-services"'
    values:
      - ./chart/values/prd-gcp-eu-west1-sre-services.yaml
```

Rules for the emitted file:

- **No `target_filter` key.** It comes from `--target-filter` per run. That is
  what makes one file drive every environment.
- **One `config_layers` entry per v1 cluster that had a `valuesFile`**, targeting
  that cluster by exact name, in `development` -> `staging` -> `production`
  order. A cluster with no `valuesFile` gets no layer.
- **No `values_files`** unless a file is genuinely shared by every cluster of
  every environment. Translating v1 almost never produces one (rule 4).
- **`name` must equal the Catalog App `metadata.name`**, not the repo name and
  not the chart name. Read it out of `catalog/<team>/apps/<app>.yaml` rather than
  guessing.
- **Paths resolve against `--context`, which defaults to the working directory.**
  In CI that is the repo root. So in a monorepo, `mupuske-core/serenity.yaml`
  still writes `chart: mupuske-core/chart`, repo-root-relative, even though the
  file sits one directory down. Getting this wrong is a "chart not found" on the
  first run. This is unchanged from v1, where the same paths were repo-root
  relative too.

Do not add a `set:` key. It is supported by the schema
(`pkg/serenityv1alpha/deploy/config.go`) but undocumented, and the image tag is
the one value that legitimately changes per run, so it belongs on the command
line.

## Step 4: Rewrite the pipeline

One parameterised job, one workflow entry per environment, promotion as CircleCI
ordering.

```yaml
version: 2.1
orbs:
  serenity: commercetools/serenity@50

jobs:
  deploy:
    docker:
      - image: cimg/base:2026.04
    resource_class: commercetools/serenity
    parameters:
      target:
        type: string
    steps:
      - serenity/install
      - checkout
      - run:
          name: serenity alpha deploy
          command: |
            serenity alpha deploy --config serenity.yaml \
              --target-filter '<< parameters.target >>' \
              --set image.tag=<<pipeline.git.revision>>

workflows:
  build-and-deploy:
    jobs:
      - build
      - deploy: { name: dev,   target: 'cluster.name == "plg-gcp-eu-west1-v1"', requires: [build], filters: { branches: { ignore: [main] } } }
      - deploy: { name: stage, target: 'cluster.name == "stg-gcp-eu-west1-v1"', requires: [build], filters: { branches: { only: [main] } } }
      - hold-production:
          type: approval
          requires: [stage]
          filters: { branches: { only: [main] } }
      - deploy:
          name: prod
          target: 'cluster.name in ["prd-aws-eu-central1-v1", "prd-gcp-eu-west1-v1"]'
          requires: [hold-production]
          filters: { branches: { only: [main] } }
```

Emit workflow entries expanded; the flow-mapped `dev`/`stage` lines above are
compact only to keep this reference short.

Carry across from the v1 pipeline, unchanged: the `requires` DAG between deploy
jobs, every branch filter, and the build job the deploys depend on. Preserving
the DAG matters in a monorepo where one component must deploy before another.

Non-negotiable in the emitted job:

- `resource_class: commercetools/serenity`. The CLI reaches the Serenity API at
  an in-cluster address, so the job has to run on the in-cluster runner. It is a
  container runner, hence the `docker:` image alongside it.
- `serenity/install` before `checkout`. The ORB is still needed; there is no
  `serenity/deploy` job, V2 is a plain `run` step.
- No `--token` and no `--server`. Both default correctly inside CircleCI.

**Orb version is a blocker, not a preference.** `serenity/install` pins the CLI
to the orb's own version, so an orb predating `alpha deploy` installs a binary
without the subcommand and the job dies on the first run. Read what the repo pins
today; if it is old, bump it and say so in the report. Pin to a published
version - **`commercetools/serenity@50`** is the current default. Never emit
`@volatile`: it floats to the latest build, so the installed CLI can change
without a commit, which is the wrong property for the run that adopts your
Applications.

**Validate against the org.** The orb is private, so a bare
`circleci config validate` cannot resolve it and reports
`Cannot find commercetools/serenity@<v> in the orb registry` even for the config
running in production today:

```sh
circleci config validate .circleci/config.yml --org gh/commercetools
```

Only if the CLI is unavailable, fall back to a structural check: copy the config,
delete the `orbs:` block, stub `serenity/install` with a `run` step, validate
that.

**`no_output_timeout`** is the one decision to hand back. V2 waits by default and
prints status roughly every 30s, so a normal deploy keeps the step alive. If the
v1 job raised `wait_timeout`, carry the intent over as `no_output_timeout` on the
run step: there is no client-side deploy timeout to raise (see
[reference/translation.md](reference/translation.md)).

## Step 5: Prove cluster coverage

Emit this table. It is the single most useful artifact in the report, and the
migration is not ready until every row is accounted for.

| v1 cluster | v1 section | Live Application | V2 job | In filter | `environment` label |
| --- | --- | --- | --- | --- | --- |
| `plg-gcp-eu-west1-v1` | development | `<app>-plg-gcp-eu-west1-v1` | `dev` | yes | **none** |
| `stg-gcp-eu-west1-v1` | staging | `<app>-stg-gcp-eu-west1-v1` | `stage` | yes | `staging` |
| `prd-gcp-eu-west1-v1` | production | `<app>-prd-gcp-eu-west1-v1` | `prod` | yes | `production` |

Any `no`, any cluster appearing in two jobs, or any live Application with no v1
section is a blocker. Report it as one and do not proceed to the cutover
checklist.

### Say the unlabelled clusters out loud

The last column is not decoration. **Whenever a target cluster carries no
`environment` label, tell the user explicitly and by name.** Not implied by the
table, not folded into a general warning about labels. Name the cluster and the
consequence:

> `prd-gcp-eu-west1-sre-services` carries **no labels at all** and can only be
> targeted by `cluster.name`. `cluster.labels["environment"] == "production"`
> matches nothing for it and fails the deploy with "no clusters matched" rather
> than erroring on the expression, so the mistake reads as a config problem
> rather than a targeting one.

Known unlabelled: `prd-gcp-eu-west1-sre-services`, the Vault clusters
`prd-gcp-eu-west1-ct-vault` and `stg-gcp-eu-west1-ct-vault`, and every `plg-*`
playground cluster. The registry is the source of truth and changes, so check
rather than trust the list, and treat any empty label lookup the same way.

The emitted filters are name-based (rule 5), so the deploy works regardless. The
point is the next person to edit this pipeline: they will reach for a label
filter, and if nobody told them, their change deploys nowhere and passes review.

## Step 6: Flag the parity risk

Do not skip this and do not soften it. V2's Application sets `prune: true`
(`pkg/serenityv1alpha/deploy/apply.go`); the v1 ApplicationSet set
`prune: false`. A resource that the Git-rendered set has and the OCI-rendered set
omits is therefore **deleted** on the first V2 deploy, where v1 would have left
it alone.

A local render approximates the server, but it catches what matters:
resource-level absence rather than field churn.

```sh
helm template <name> ./chart --namespace <space> \
  -f ./chart/values/<cluster>.yaml \
  --set image.tag=$(git rev-parse HEAD) \
  | grep -E '^(kind|  name):' > /tmp/v2-resources.txt

# compare against what the team GitOps repo serves for that cluster today
grep -E '^(kind|  name):' <gitops-repo>/<cluster>/<space>/<app>/*.yaml \
  > /tmp/v1-resources.txt

diff /tmp/v1-resources.txt /tmp/v2-resources.txt
```

Report every kind/name present on the v1 side and missing on the V2 side as a
blocker with the resource named. Field-level differences re-converge on the next
sync and can be listed as notes. One legitimate source of difference: V2 injects
a reserved `_serenity` values key at render time, so a chart reading
`.Values._serenity` will differ by design.

### Then check the live cluster, which the render cannot see

The diff above is desired-vs-desired. It cannot catch a resource that Argo
**tracks** but neither side renders, and that is the likelier prune victim:
under `prune: false` such a resource sits `OutOfSync` forever, so it accumulates
silently. The tell is an Application that is `OutOfSync` while `Healthy`.

```sh
kubectl --context $SRE -n argocd-infra get application <app>-<cluster> \
  -o jsonpath='{range .status.resources[*]}{.kind}/{.name}{"\t"}{.status}{"\n"}{end}'
```

Anything `OutOfSync` that your render does not produce is tracked-but-undesired,
and `prune: true` deletes it on the first V2 deploy. Confirm via the object's
`argocd.argoproj.io/tracking-id`, find where it came from (a sideloaded feature
branch is the common source), and **ask the owner**: let it be pruned, remove it
deliberately first, or land the change that makes it desired again.

Knock-on worth reporting: after migration, branch builds sideloading to a shared
staging cluster prune rather than accumulate. That is what stops this class of
leftover, but branch and main builds contending over one cluster become
destructive instead of additive.

## Step 7: Output

Emit, in this order:

1. **Inventory table** (Step 1), including the live Applications.
2. **The files**: each rewritten `serenity.yaml` shown as a before-and-after
   diff, the full rewritten `.circleci/config.yml`, and the Catalog patch:

   ```yaml
   # catalog/<team>/apps/<app>.yaml
   spec:
     # ...
     delivery: oci   # was gitops (or unset)
   ```

   Confirm while you are in there that the Space already lists the App in
   `spec.allowedApps.appRefs`. The consent gate is two-sided and a missing entry
   fails the deploy.
3. **Coverage table** (Step 5), including the `environment` label column and the
   unlabelled-cluster callout below it.
4. **Parity findings** (Step 6).
5. **No-equivalent list**: every v1 parameter that did not survive, with what to
   do instead. Draw it from
   [reference/translation.md](reference/translation.md); do not invent a mapping
   for something that has none.
6. **The cutover checklist**, exactly this order:

   ```text
   [ ] 1. Post in #special-delivery. Do this before anything else.
   [ ] 2. Open the service-repo PR with the rewritten serenity.yaml + pipeline. DO NOT MERGE.
   [ ] 3. Run the parity check (Step 6). Empty resource diff, or a diff you can explain.
   [ ] 4. Merge the Catalog PR flipping delivery: oci.
   [ ] 5. Wait 10-15 min. Then verify, all three:
            - the ApplicationSet is gone and not stuck Terminating
            - each <app>-<cluster> Application still exists with EMPTY ownerReferences
            - pods unchanged, no restarts
          Applications deleted instead of orphaned? STOP. Escalate. Do not deploy.
   [ ] 6. Merge the service-repo PR. The first run adopts each Application in place.
   [ ] 7. Verify: source is oci:// pinned to a digest, Synced/Healthy, pod UIDs unchanged.
   [ ] 8. Clean up: delete the app's directories from the team GitOps repo and
          remove any remaining sync/approve jobs. serenity.yaml stays: it is now
          the v2 config.
   ```

   Steps 4 and 6 are the ordering the whole migration rests on, and nothing
   enforces it (hard rule 2). Never reorder them in the emitted checklist.

Then stop. Do not merge, do not push, do not flip the delivery field.

Hand the user the verification commands for checklist steps 5 and 7 alongside
the checklist itself; they are in
[reference/translation.md](reference/translation.md) section G. Tell them to take
the pod snapshot **before** step 4 so step 7 is a diff rather than an impression.

## What this skill does not do

- **New services.** No `serenity.yaml`, nothing to translate: point at the
  onboarding guide.
- **Hand-written ApplicationSets.** Catalog-composed Applications only. A
  hand-rolled ApplicationSet in `k8s-gitops` has no `delivery` field to flip and
  needs Special Delivery in the room.
- **Namespace moves.** `targetSpaceRef` is immutable during a migration; move
  namespaces as a separate change, before or after, never folded into the flip.
- **Rollback rehearsal.** Flipping back to `gitops` re-emits the ApplicationSet,
  which re-adopts the same-named Application and resets its source. Workloads
  are not at risk either way, but that path is less exercised than the forward
  one. Say so rather than promising it.
