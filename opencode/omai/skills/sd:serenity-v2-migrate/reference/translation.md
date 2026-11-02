# Translation reference

Lookup tables for `serenity-v2-migrate`. Nothing here is a step; the process
lives in `SKILL.md`.

---

## A. `serenity.yaml` v1 to v2 (rewritten in place)

| v1 | V2 (single-file layout) |
| --- | --- |
| `chart` | `chart`, written once |
| `name` | `name`, written once. Must equal the Catalog App `metadata.name` |
| `development:` / `staging:` / `production:` | nothing in the file. The environment is whichever clusters `--target-filter` selects at run time |
| `<env>.clusters[].name` | the cluster set in that environment's `--target-filter`, in the pipeline |
| `<env>.clusters[].valuesFile` | one `config_layers` entry whose `target` names that one cluster |
| `<env>.autoMerge: true` | nothing. There is no PR to merge. The absence of an approval job is the equivalent |
| `<env>.autoMerge` absent (production) | a `type: approval` job before that environment's deploy job |
| (no v1 equivalent) | `values_files`, for values shared by every matched cluster. A translated v1 config almost never needs it |
| (no v1 equivalent) | `target_filter` in the file. Deliberately omitted in this layout |

Keys the V2 schema accepts but a translation should not emit: `set` (the image
tag belongs on the command line), `namespace` (the server resolves it from the
Space and rejects a disagreeing value), `server` (the default is correct in CI),
`context` (defaults to the working directory, which is the repo root in CI),
`skip_wait` (waiting is the point), `conditions` (add later if the workload has
its own readiness definition, e.g. Argo Rollouts canary analysis).

---

## B. `serenity/sync` parameters

Every parameter of the v1 ORB job, and where it goes. Defaults are the ORB's.

| Parameter | Default | V2 |
| --- | --- | --- |
| `config_file` | `serenity.yaml` | `--config serenity.yaml` |
| `image_tag` | `$CIRCLE_SHA1` | the value half of `--set <path>=<tag>` |
| `image_tag_value_path` | `imageTag` | the key half of `--set <path>=<tag>`. **Read the actual value**: the ORB default is `imageTag`, not the `image.tag` most charts use. Translating the default blindly writes the tag to the wrong key |
| `dev` | `false` | when true, the target filter is the `development` section's clusters |
| `sideload` | `false` | when true, the target filter is the `staging` section's clusters |
| neither `dev` nor `sideload` | - | the target filter is `staging` **and** `production` clusters. V2 has to split this into two jobs, and how they are gated is the owner's decision: **stop and ask** (SKILL.md Step 2) |
| `wait` | `false` | no equivalent and none needed: V2 always waits unless `--skip-wait` |
| `warn_only` | `false` | no flag. An Application whose auto-sync a human disabled produces a warning and skips the convergence watch, which is the behaviour `warn_only` was reaching for |
| `wait_timeout` | `5m` | **no client flag.** The ceiling is server-side. Carry the intent to `no_output_timeout` on the run step |
| `no_output_timeout` | `15m` | set it on the `run` step yourself; there is no job wrapper to set it for you |
| `resource_class` | `commercetools/serenity` | `resource_class: commercetools/serenity` on the job. Still required |
| `validate` | `ignore` | **no equivalent.** Report it |
| `extra_flags` | `""` | read what is actually in there and map each flag individually. Never drop it silently |

## `serenity/approve` parameters

| Parameter | Default | V2 |
| --- | --- | --- |
| `config_file` | required | the same `--config serenity.yaml` on the gated deploy job |
| `environment` | `production` | that section's clusters in the gated job's `--target-filter` |
| `wait` | `true` | always waits |
| `warn_only` | `false` | see above |
| `wait_timeout` | `5m` | see above |
| `no_output_timeout` | `15m` | set on the run step |
| `resource_class` | `commercetools/serenity` | unchanged |
| `extra_flags` | `""` | map individually |

---

## C. No equivalent

Put every applicable line in the final report. Do not invent a mapping.

- **`validate: strict`.** The render happens server-side and there is no client
  validate flag. If a team relied on it to catch bad manifests before a deploy,
  their nearest option today is a `helm template` step in the build job.
- **No `--timeout` flag.** The wait ceiling is set on the server
  (`--argocd-wait-timeout`). The deploy continues asynchronously past it; the
  timeout only bounds the streamed result. Note that the published docs and the
  flag default currently disagree on the number (docs say 10 minutes, the flag
  defaults to 5 and the chart does not override it), so do not quote a figure at
  the user. Tell them to keep `no_output_timeout` comfortably above whatever the
  server uses.
- **No `serenity/deploy` ORB job.** V2 is a plain `run` step. `serenity/install`
  is the only ORB command still involved.
- **Jira and GitHub Deployment reporting** still come from the old commands.
  Unifying them is follow-up work. A team that depends on deploy markers should
  know before they cut over.
- **`autoMerge`.** Nothing merges, so nothing to configure. Ordering is the
  pipeline's job.
- **Remote charts from a private registry.** The deploy CLI fetches `oci://`,
  `https://`, and `helm://` charts without credentials, so our own Artifact
  Registry will fail to pull. Package from a local directory in the CI checkout.
  If the v1 setup pulled a chart from a private registry, this is a blocker, not
  a note.
- **Hosted runners.** `resource_class: commercetools/serenity` is required
  today.

---

## D. Target filters during a migration

The grammar is CEL over one bound object, `cluster`, with `name`, `labels`, and
`annotations`. The expression must return a boolean.

For a migration, use `cluster.name` and nothing else:

```
cluster.name == "stg-gcp-eu-west1-v1"
cluster.name in ["prd-aws-eu-central1-v1", "prd-gcp-eu-west1-v1"]
```

Label filters are correct V2 style and wrong migration style. The reason is
coverage, not syntax: a migration must match exactly the clusters that have
GitOps directories today, and a label filter is defined by what the platform
labels rather than by what the app already deploys to. Two concrete ways it
bites:

- `cluster.labels["environment"] == "production"` matches every labelled
  production cluster, including any the app has never deployed to. That is not
  an adoption, it is a new deployment into a namespace that may not be ready.
- The same expression does **not** match `prd-gcp-eu-west1-sre-services`, the
  playground clusters, or the Vault clusters, because none of them carry an
  `environment` label. Indexing a missing label is a non-match, not an error, so
  an app that deploys to `sre-services` silently gets nothing.

Moving to label filters is a good follow-up once V2 owns the Applications and
the coverage question is settled. Say that in the report rather than leaving the
impression that name filters are the end state.

Cluster names carry no labels worth relying on for: `prd-gcp-eu-west1-sre-services`,
`prd-gcp-eu-west1-ct-vault`, `stg-gcp-eu-west1-ct-vault`, and the `plg-*`
playground clusters. Target those by name always.

One open question to raise rather than answer: whether
`plg-gcp-eu-west1-v1` is ready for OCI delivery. `serenity-test-source` deploys
development there on V2, but the mupuske migration deliberately pointed branch
builds at a staging cluster instead, with a comment saying the playground was
not set up for OCI yet. If the service's v1 `development` section targets `plg`,
ask in #special-delivery before assuming a one-to-one mapping.

---

## E. Worked examples

### E1. Minimal: two environments, no per-cluster values

`sd-onsite-demo`, before:

```yaml
chart: ./chart
name: sd-onsite-demo
development:
  clusters:
  - name: plg-gcp-eu-west1-v1
staging:
  autoMerge: true
  clusters:
  - name: stg-gcp-eu-west1-v1
```

After. No `valuesFile` anywhere, so no `config_layers`. No shared values file, so
no `values_files`. The whole config is three lines:

```yaml
# serenity.yaml (rewritten)
version: 2
chart: ./chart
name: sd-onsite-demo
```

```yaml
      - deploy:
          name: dev
          target: 'cluster.name == "plg-gcp-eu-west1-v1"'
          requires: [build]
          filters: { branches: { ignore: [main] } }
      - deploy:
          name: stage
          target: 'cluster.name == "stg-gcp-eu-west1-v1"'
          requires: [build]
          filters: { branches: { only: [main] } }
```

No production section, so no approval job. `autoMerge: true` on staging means it
was ungated, and an ungated job is the translation.

### E2. Real: monorepo, six production clusters

`commercetools/mupuske` migrated under SD-2401 (repo PR #48, Catalog commit
`f45877a`). Two components, each with its own `serenity.yaml`, each production
cluster carrying its own `valuesFile`. It is the best available reference for
what a non-trivial translation looks like on disk.

Two things to copy from it:

**Per-cluster values become one layer per cluster**, named exactly:

```yaml
version: 2
chart: mupuske-core/chart
name: mupuske
config_layers:
  - target: 'cluster.name == "prd-gcp-eu-west1-perf"'
    values:
      - mupuske-core/values/prd-gcp-eu-west1-perf.yaml
  - target: 'cluster.name == "prd-aws-eu-central1-v1"'
    values:
      - mupuske-core/values/prd-aws-eu-central1-v1.yaml
  # ... one per cluster
```

Note the paths: the config lives under `mupuske-core/`, and every path inside it
is still repo-root-relative, because they resolve against `--context`, which
defaults to the working directory.

**The component DAG survives.** v1 chained core before runner with `requires`;
V2 keeps the same chain, one `deploy` job per (component, environment):

```yaml
      - deploy: { name: prod-core,   config: mupuske-core/serenity.yaml,   target: '...', requires: [hold-production] }
      - deploy: { name: prod-runner, config: mupuske-runner/serenity.yaml, target: '...', requires: [prod-core] }
```

Mupuske shipped new files at `<component>/deploy/<env>.yaml`, one per
(component, environment), and left `<component>/serenity.yaml` in place. This
skill does neither: it rewrites each component's existing `serenity.yaml` and
passes `--target-filter` per run. Use mupuske for the `config_layers` shape and
the DAG, not for the file layout.

---

## F. Facts worth not re-deriving

Each verified against the source; cite these rather than the published docs where
they disagree.

| Fact | Where |
| --- | --- |
| Application name is `<name>-<cluster>`, matching what the v1 composition generated. This is why adoption is in place | `pkg/serenityv1alpha/deploy/apply.go` |
| V2 sets `prune: true`, `selfHeal: false`. v1's ApplicationSet set `prune: false` | `apply.go` |
| No `resources-finalizer` on the Application, so deleting it does not tear down the workload. Same on the v1 side via `preserveResourcesOnDeletion` | `apply.go` |
| The deploy server never reads `App.spec.delivery`. Nothing prevents deploying against a `gitops` App | no reference in `pkg/serenityv1alpha/deploy` or `pkg/app` |
| Orphan-on-disconnect needs `applicationsSync: create-update` **and** an ApplicationSet resources-finalizer. Either alone leaves children owned | k8s-gitops #10191, merged 2026-07-23 |
| The config schema accepts a `set:` key, undocumented | `pkg/serenityv1alpha/deploy/config.go` |
| Server wait ceiling comes from `--argocd-wait-timeout`, flag default 5m, max 45m, and the chart does not override it | `cmd/serenity/serve.go`, `chart/templates/deployment.yaml` |
| Status lines are emitted about every 30s to keep the stream alive | `--deploy-status-interval`, `cmd/serenity/serve.go` |
| The Catalog repo is `commercetools/catalog` (renamed from `ct-apps`). The Kubernetes **namespace** is still `ct-apps` | serenity `3a462fa`; `chart/values.yaml` |
| The AppProject gets the OCI source repo added automatically once `delivery: oci`, one entry per cluster | Space composition, k8s-gitops |
| `conditions` CEL binds `status` with `sync`, `health`, `resources[]`, `operation`, `conditions[]`, `summary`. Resource entries expose `kind`, `name`, `sync_status`, `health_status` | `pkg/serenityv1alpha/deploy/deploy.proto` |

---

## G. Verification commands

`$SRE` is the resolved sre-services kubectl context (SKILL.md Step 1), **not** the
Argo cluster name `prd-gcp-eu-west1-sre-services`.

Checklist step 5, after the delivery flip:

```sh
kubectl --context $SRE -n argocd-infra get applicationset <app>

kubectl --context $SRE -n argocd-infra \
  get application <app>-<cluster> -o jsonpath='{.metadata.ownerReferences}{"\n"}'
```

Populated `ownerReferences` naming the ApplicationSet before the flip, empty
after. Empty is the orphan and the go/no-go signal. It works because the Catalog
composition sets `applicationsSync: create-update` together with a
resources-finalizer on the ApplicationSet (k8s-gitops #10191, merged
2026-07-23); either alone still leaves the children owned and collected.

Checklist step 7, after the first V2 deploy:

```sh
kubectl --context $SRE -n argocd-infra \
  get application <app>-<cluster> \
  -o jsonpath='{.spec.source.repoURL}{"\t"}{.spec.source.targetRevision}{"\n"}'

kubectl --context <cluster> -n <space> get pods \
  -o custom-columns=NAME:.metadata.name,UID:.metadata.uid,RESTARTS:.status.containerStatuses[0].restartCount
```

Expect an `oci://` repoURL pinned to a digest, and pod UIDs identical to the
snapshot taken before step 4.
