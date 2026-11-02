---
name: sd:2-2-prep
description: Use this skill when an engineering manager and product manager are preparing for their bi-weekly 2:2 meeting with their Head of Engineering and Head of Product. Gathers high-signal highlights, risks, and leadership asks from Jira, GitHub, and Confluence, then produces a concise markdown briefing ready to present.
---

# 2:2 Meeting Prep

> **Requires:** access to Jira, GitHub, and Confluence via available tools.

## Purpose

Help an Engineering Manager (EM) and Product Manager (PM) produce a concise briefing for their bi-weekly meeting with the Head of Engineering (HoE) and Head of Product (HoP). The output has three sections:

1. **Highlights** — highest-impact work completed or progressed since the last meeting
2. **Problems & Risks** — issues, blockers, or risks that leadership needs to be aware of
3. **Needs Help** — specific, actionable asks directed at the HoE or HoP

The briefing should be readable in under 2 minutes. Quality over quantity.

## Instructions

### Step 1: Intake

Before gathering data, check whether the scope is already clear from the conversation or workspace context (e.g. a Jira project key is visible, a GitHub org/repo is mentioned, or the user has given context). If it is, skip questions that are already answered.

Ask only what is missing from:

- **Jira**: Which project(s) or board(s) to include?
- **GitHub**: Which org/repos to include?
- **Confluence**: Which space(s) or team area(s) to include?
- **Lookback window**: Defaults to 14 days. Did the last 2:2 happen at a different cadence?
- **Known items**: Any highlights, risks, or asks the user already wants to include regardless of what the tools surface?

Collect all answers in a single exchange, then proceed — do not interrupt the data-gathering phase with further questions.

### Step 2: Gather signals

Using the confirmed scope and lookback window, gather signals from all three sources in parallel where possible.

**From Jira:**
- Stories/tasks moved to Done within the window
- Epics with meaningful progress (e.g. milestone reached, significant percentage increase)
- Tickets flagged as blocked, overdue, or stalled (no status change for 7+ days while in an active sprint)
- Items with risk, blocker, or escalation labels
- Dependencies on other teams or external parties that are at risk

**From GitHub:**
- First, use the topic filter (e.g. `org:commercetools topic:<team-topic>`) only to **discover the list of repositories** — do not attempt to filter PRs or commits directly via topic search, as it does not support those filters reliably.
- Then, for each active (non-archived) repository in that list, search for merged PRs and recent commits within the lookback window directly against each repo.
- For GitOps repositories (e.g. k8s-gitops), do not list individual commits or promotion PRs. Instead, report only the **count of promotion PRs merged** in the window as a single throughput metric (e.g. "420 promotion PRs merged via Telefonistka"). Surface individual non-promotion commits from GitOps repos only if they represent a meaningful infrastructure change.
- Focus on features, architectural changes, risk-reducing work — exclude routine chores and dependency bumps unless they materially reduced risk or unblocked delivery.
- Releases or version tags published
- Issues or PRs open significantly longer than normal (stale, or carrying a blocker/critical label)
- CI/CD pipeline failures or recurring flakiness if visible

**From Confluence:**
- Pages created or substantially updated within the window
- Decision records or ADRs published
- Documents indicating cross-team alignment, escalation, or a significant design change

If any source is unavailable, returns incomplete data, or is clearly noisy, note that explicitly before presenting findings — do not silently omit it.

### Step 3: Synthesise and prioritise

Before writing the briefing, apply these rules:

- **Synthesise across sources.** If a shipped feature appears in both a merged PR and a closed Jira epic, that is one highlight — not three.
- **Write highlights for a leadership audience who will re-present upward.** The HoE and HoP will use this briefing to impress their own stakeholders. Each highlight should be something they can repeat confidently in a non-technical context.
- **Lead with business or team impact**, not the technical mechanism. Ask "so what?" before writing. "Engineering teams can now deploy without storing long-lived secrets in CI" lands better than "serenity alpha auth github shipped".
- **Connect to strategic themes** — security posture, developer experience, platform reliability, team velocity, adoption at scale. Name the theme explicitly if it strengthens the bullet.
- **Quantify wherever possible** — how many teams are affected, what risk was eliminated, what toil or manual steps were removed, what was the before/after.
- **Put the impact first, the mechanism second.** Technical details (ticket refs, PR numbers) belong at the end in parentheses as supporting evidence, not in the headline.
- **Hyperlink all evidence references inline** — Jira tickets as `[SD-123](https://commercetools.atlassian.net/browse/SD-123)`, PRs as `[repo#456](https://github.com/commercetools/repo/pull/456)`, Confluence pages by title linked to their URL. Never include bare ticket or PR numbers.
- **Keep each bullet to one sentence, 20 words max.** It should be paste-ready into a doc or slide. If you need more than one sentence, split into two bullets or cut.
- **Hard limits**: present at most **5 highlights**, **3 risks**, and **3 asks**. If you have more candidates, pick the highest-signal ones. Do not present raw ticket or PR lists.

### Step 4: Format and output

Output the following to the terminal **inside a fenced code block** so the raw markdown is visible and copy-pasteable (not rendered):

```
# 2:2 Prep — [start date] → [end date]

## ✅ Highlights

- [Outcome-focused bullet. e.g. "Launched X, enabling Y — ahead of roadmap milestone ([ABC-123](https://commercetools.atlassian.net/browse/ABC-123), [repo#42](https://github.com/commercetools/repo/pull/42))"]
...

## ⚠️ Problems & Risks

- [One sentence: what the risk is and why it matters. ≤20 words.]
...

## 🙋 Needs Help From Leadership

- [One sentence: the specific ask and who it is directed at (HoE / HoP / both). ≤20 words.]
...
```

If a section has no items, say "Nothing to raise this cycle." — do not omit the section.

After the briefing, ask: "Is there anything you'd like to add, remove, or reframe before the meeting?"
