---
name: sd:circle-hook-onboarding-triage
description: Use this skill for the daily morning onboarding triage of the circle-hook service. Pulls circle-hook Cloud Run logs, runs the onboarding-report tool to classify which registered repositories are firing CircleCI deploy webhooks but NOT producing GitHub Deployments, and walks a decision tree to onboard each repo to a parser strategy (promote to the default convention, write/extend a strategy, or record a conscious exception). Produces the code changes, tests, and a PR.
---

# circle-hook Onboarding Triage

> **Requires:** gcloud (auth to project ctp-playground) and a Go toolchain. Optionally Jira access for SD-2279 subtasks.

## Purpose

`circle-hook` converts CircleCI deploy webhooks into GitHub Deployments using the
SD-2334 convention (`deploy-<app>-<cluster>`). A repo is **registered** when the
webhook is plumbed to it (it appears in `cmd/circle-hook/deploy/projects.txt`).
A repo is **onboarded** only when a parser *strategy* actually understands its
deploy job names. Registered ≠ onboarded.

When a registered repo fires a webhook we can't parse, circle-hook logs an
ERROR (`not_onboarded`) and returns 200. The morning job is to clear that ERROR
backlog: for each repo, decide *how* it should be onboarded, make the change,
prove it with tests, and open a PR.

This skill is **strict by design**: onboarding is an explicit allowlist
(`defaultStrategyRepositories`), not zero-config. That is deliberate "until we
gain confidence." Don't loosen it without the user's say-so.

## Key files

| Path | Role |
|------|------|
| `cmd/circle-hook/cmd/onboarding-report/` | The triage report generator (reuses the real parser). |
| `cmd/circle-hook/internal/sd2334/onboarding.go` | `defaultStrategyRepositories` allowlist — **promote repos here**. |
| `cmd/circle-hook/internal/sd2334/clusters.go` | Cluster registry. Add a cluster when a deploy targets an unknown one. |
| `cmd/circle-hook/internal/sd2334/strategy_mc_applications.go` | Example of a per-group strategy (`sd2365Repos`). |
| `cmd/circle-hook/internal/sd2334/strategies.go` | `parserStrategies` registry + `defaultStrategy`. |
| `cmd/circle-hook/deploy/projects.txt` | Registered repos (plumbing only). |
| `cmd/circle-hook/deploy/onboarding-exceptions.yaml` | Consciously-accepted skips. |

## Step 1 — Pull the logs

The durable production signals are `reported` (INFO) and `not_onboarded`
(ERROR). Skips are DEBUG and invisible in prod, so the report cannot see
partial-coverage gaps unless DEBUG is temporarily enabled (see Step 5).

```bash
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="circle-hook"' \
  --project ctp-playground --freshness=1d --limit=2000 --format=json > /tmp/circle-hook-logs.json
```

Widen `--freshness` (e.g. `2d`, `7d`) if the overnight window is quiet. Raise
`--limit` if you suspect truncation.

## Step 2 — Run the report

```bash
# Run from the repo root and pass explicit paths, or cd cmd/circle-hook and use defaults.
go run ./cmd/circle-hook/cmd/onboarding-report \
  -input /tmp/circle-hook-logs.json \
  -projects cmd/circle-hook/deploy/projects.txt \
  -exceptions cmd/circle-hook/deploy/onboarding-exceptions.yaml \
  -window "last 24h"
```

Add `-json` for a machine-readable snapshot you can diff day-over-day.

The report sorts repos into buckets:

- **🔴 Not onboarded** — firing ERROR `not_onboarded` events. **This is the worklist.**
- **🟢 Healthy** — onboarded and reporting. A `⚠️ partial coverage` flag means
  the repo also has `not_onboarded` events for *some* jobs.
- **⬛ Silent registered** — in projects.txt but no traffic. No deploys, or the
  webhook isn't firing — spot-check one occasionally.
- **⚪ Other** — only non-deploy jobs seen (or fully excepted).

Each 🔴 repo carries a **grounded** per-job verdict computed by the *real*
parser: `would default-parse` and `deploy-looking`, plus a recommendation.

## Step 3 — Decision tree (per 🔴 repo)

Use the recommendation as a starting point, then confirm:

1. **`would default-parse` = ✅  → PROMOTE.**
   The job already matches `deploy-<app>-<cluster>` against a known cluster.
   Add `"owner/repo"` to `defaultStrategyRepositories` in `onboarding.go`
   (keep the slice sorted; one entry per line).

2. **deploy-looking but does NOT parse → ASSESS the reason:**
   - *Unknown cluster* (job is `deploy-<app>-<something>` but `<something>`
     isn't in `clusters.go`): if it's a real, legitimate cluster, add it to the
     `clusters` registry in `clusters.go`, then PROMOTE the repo. If it's a
     vanity/typo name, the job should be renamed in the repo's CircleCI config
     (raise that with the repo owner) — don't bend the parser to a typo.
   - *Different naming scheme entirely* (a whole group of repos shares a
     non-default convention, like the mc-applications orb): write a new
     strategy modeled on `strategy_mc_applications.go`, register it in
     `parserStrategies`, and key it to that group's repos.

3. **Only non-deploy jobs (build/test/infra) → EXCEPTION or de-register.**
   If the repo genuinely has no SD-2334 deploys, either remove it from
   projects.txt (stop the webhook noise) or, if specific jobs recur, add a rule
   to `onboarding-exceptions.yaml` with a clear `reason`.

> A repo can need more than one action (e.g. promote it AND except one perf
> shard). After promotion, that repo's non-matching jobs become DEBUG skips —
> they won't ERROR anymore.

## Step 4 — Make the change, prove it

Edit the appropriate file(s), then keep the onboarding invariants green:

```bash
go build ./cmd/circle-hook/... \
  && go vet ./cmd/circle-hook/... \
  && go test ./cmd/circle-hook/...
```

The tests in `internal/sd2334` enforce that onboarded repos are a subset of
projects.txt and that strategy assignments are disjoint. If you promote a repo
that isn't in projects.txt, register the webhook for it first (or the test will
fail — that failure is the system telling you registration and onboarding are
out of step).

When adding a cluster or a strategy, add a parser test case alongside the
existing ones so the new shape is locked in.

## Step 5 — (Optional) partial-coverage deep dive

To catch jobs that are skipped *within* an onboarded repo (DEBUG, invisible in
prod), temporarily raise the service log level, collect a window, and rerun the
report. Look for 🟢 repos flagged `⚠️ partial coverage`. Revert the log level
afterwards.

## Step 6 — Open the PR

Keep it on the SD-2279 branch (or a child branch) so it folds into the
onboarding effort. PR description: brief and clear — what repos changed bucket
and why, one line each. Include the standard co-author trailer.

```text
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Worked example

Report shows:

```text
### commercetools/some-service
**PROMOTE: add "commercetools/some-service" to defaultStrategyRepositories ...**
| job | count | deploy-looking | would default-parse | excepted |
| deploy-some-service-prd-gcp-europe-west1-v1 | 4 | ✅ | ✅ | — |
```

Action:

1. Confirm `some-service` is in `projects.txt` (it is — it's firing webhooks).
2. Add `"commercetools/some-service"` to `defaultStrategyRepositories` in
   `onboarding.go`, sorted.
3. `go test ./cmd/circle-hook/...` → green.
4. Commit on SD-2279, push; the repo moves 🔴 → 🟢 on tomorrow's report.

## Guardrails

- Don't conflate registered with onboarded. Promotion requires *evidence* (a
  `would default-parse` ✅ job, or a strategy you've written and tested).
- Don't relax the strict allowlist model without explicit user approval.
- Don't add a cluster or strategy to accommodate a typo'd job name — fix the
  job at the source.
- Every exception needs a human-readable `reason`.
