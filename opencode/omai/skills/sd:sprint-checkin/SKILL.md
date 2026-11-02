---
name: sd:sprint-checkin
description: 'Use this skill when a team is preparing for their bi-weekly sprint check-in meeting. Gathers open sprint items, team workload distribution, and backlog signals from Jira to produce a structured meeting agenda covering: closing open items, redistributing work, downscoping, locking the selected-for-development column, and envisioning the next sprint. Also estimates and writes story points for unestimated tickets, and flags tickets whose complexity appears to have exceeded their original estimate.'
---

# Sprint Check-in Meeting Prep

> **Requires:** access to Jira via available tools.

## Purpose

Help the team prepare for their bi-weekly sprint check-in meeting. The output is a structured agenda covering six sections:

1. **Close open items** — what can we do right now to close things out?
2. **Redistribute work** — who has capacity to help others?
3. **Downscope** — which tickets are too large to close and should be trimmed?
4. **Soft-lock Selected for Development** — finalise the agreed scope for the next sprint
5. **Next sprint vision** — what's coming up, and is the backlog ready?
6. **Story point calibration** — estimate unestimated tickets and flag re-estimate candidates

In addition, this skill flags tickets where actual complexity has outpaced the original estimate — a signal to split or re-estimate.

## Instructions

### Step 1: Intake

Check what's already known from the conversation (e.g. a Jira project key, board name, or sprint name). Ask only what is missing from:

- **Jira project or board**: Which project key(s) or board(s) to include?
- **Current sprint name or ID**: Defaults to the active sprint on the board.
- **Team members**: List of team member names or Jira account IDs, if known (used for workload analysis).
- **Selected for Development column name**: The exact Jira column name that represents the "ready for dev" backlog. Defaults to `"Selected for Development"`.
- **Known talking points**: Any items the user wants to add to the agenda regardless of what the tools surface?

Collect all answers in a single exchange, then proceed — do not interrupt the data-gathering phase with further questions.

### Step 2: Gather sprint data

Using the confirmed scope, gather the following from Jira in parallel where possible.

**Current sprint — open items:**
- All issues in the active sprint that are not in a `Done` or `Closed` status.
- For each open issue: assignee, status, story points (or estimate), labels, and whether it has any blockers or linked issues flagged as impediments.
- Flag issues that have had **no status change for 5+ days** while in an active sprint — these are stall candidates.

**Team workload:**
- Count of in-progress and to-do items per assignee in the current sprint.
- Identify team members with **zero or one** open item — these are capacity candidates.
- Identify team members with **four or more** open items — these are overloaded candidates.

**Downscope candidates:**
- Issues with large estimates (e.g. 8+ story points) that are still open and have not progressed past the first status.
- Issues whose scope has grown (e.g. many sub-tasks or linked issues added after sprint start).
- Stalled issues where the remaining work is clearly larger than what can be completed this sprint.

**Selected for Development column:**
- Fetch all issues currently in the `Selected for Development` column (or the confirmed column name).
- Note the total count and total story points (if available).

**Backlog — next sprint signals:**
- Top 10 issues in the backlog ordered by priority or rank.
- Any issues flagged with a `next-sprint` label or equivalent.
- Epics with upcoming milestones or deadlines within the next 30 days.

**Story point gaps — current sprint and backlog:**
- All issues in the current sprint **and** the `Selected for Development` column that have no story points set.
- For each unestimated issue, read the issue title, description, acceptance criteria, sub-tasks, and linked issues to assess complexity.
- All issues in the current sprint where the ticket has been open for **more than two sprints**, has been in-progress for **5+ days without closing**, or has accumulated sub-tasks or comments indicating the scope has grown — these are re-estimate candidates.

If any data is unavailable or incomplete, note that explicitly — do not silently omit it.

### Step 3: Analyse and build agenda sections

Before writing the agenda, apply these rules:

- **Be actionable.** Every talking point should result in a decision or action, not just awareness.
- **Name names.** When referencing workload imbalance or stalled tickets, name the assignee and the ticket so the conversation is concrete.
- **Be specific about downscoping.** Don't just flag a ticket as large — suggest what could be cut to make it closeable this sprint (e.g. "remove the edge-case handling" or "descope the UI, ship the API only").
- **Hyperlink all Jira references** — format as `[SD-123](https://commercetools.atlassian.net/browse/SD-123)`. Never include bare ticket numbers.
- **Respect team capacity.** When flagging capacity candidates, phrase suggestions as "could help with" rather than "should take on".
- **Keep each bullet to one sentence.** It should be read aloud in under 10 seconds.

Build the following six agenda sections as follows:

**Section 1 — Close Open Items**
For each open sprint item, assess closability:
- Can it be closed with a small focused effort? Suggest a specific action (e.g. "needs a final review, assign a second reviewer").
- Is it blocked? Name the blocker and who can unblock it.
- Is it stalled? Flag it and suggest either an action or moving it to the next sprint.

**Section 2 — Redistribute Work**
- List capacity candidates (≤1 open item) and suggest specific tickets from overloaded team members they could pick up.
- List overloaded team members (4+ open items) and suggest which items could be handed off or deferred.
- If the distribution looks balanced, say so — do not manufacture talking points.

**Section 3 — Downscope Candidates**
- List each downscope candidate with a concrete suggestion for what to cut.
- If no tickets need downscoping, say so.

**Section 4 — Soft-lock Selected for Development**
- List the current contents of the `Selected for Development` column (titles, points, assignees where set).
- Flag any items that look misplaced (e.g. already Done, no owner, or clearly too large for one sprint).
- End with: "Does the team agree to lock this as the committed scope for the next sprint?"

**Section 5 — Next Sprint Vision**
- List the top backlog candidates for the next sprint with a one-line rationale for each (e.g. "unblocks the X team", "completes the Y epic", "due date approaching").
- Note any epics with upcoming milestones the team should be aware of.
- Surface any backlog items that need refinement before they can be sprint-ready (e.g. missing estimate, unclear acceptance criteria).

**Section 6 — Story Point Calibration**

Story points represent **complexity, not time**. Use the Fibonacci scale: 1, 2, 3, 5, 8, 13. Any ticket estimated above 8 should be considered a split candidate.

**For each unestimated ticket**, derive an estimate by reading the issue title, description, acceptance criteria, sub-tasks, and any linked issues. Apply this complexity rubric:

| Points | Signal |
|--------|--------|
| 1 | Trivial change, well-understood, no unknowns (e.g. config tweak, copy change) |
| 2 | Small, self-contained, clear acceptance criteria, minimal risk |
| 3 | Moderate scope, some moving parts, but well understood |
| 5 | Non-trivial: touches multiple areas, or has meaningful unknowns |
| 8 | Large: significant unknowns, cross-team dependencies, or many sub-tasks |
| 13 | Too large for one ticket — recommend splitting before estimating |

After generating estimates, **present a preview table** of all proposed story points to the user and ask for explicit confirmation before writing anything to Jira:

> "Ready to write the following story points to Jira. Approve? (yes / no)"

Only proceed with write-back if the user confirms. Write each ticket individually, confirm each write succeeded, and on any failure record it in the output and continue to the next ticket.

**For each re-estimate candidate** (tickets open significantly longer than their original estimate suggests, or where scope has clearly grown), suggest a revised estimate and explain the reasoning. Do **not** automatically write these — instead surface them as talking points for the team to confirm. Tickets whose revised estimate would exceed 8 should be flagged as split candidates: the team should break them into two or more smaller tickets rather than simply increasing the number.

Guiding principle: if a ticket is taking considerable time to close, the right response is usually to **raise the estimate and split the ticket** so the team has a realistic picture of what they're committing to.

### Step 4: Format and output

Each section is rendered as a **dedicated table** suited to its content — not as bullet lists stuffed into a single agenda table. Use the schemas below exactly.

If a section has no items, include the heading and write "Nothing to raise this cycle." — do not omit the section.

---

**Section 1 — 🔒 Close Open Items**

> Goal: Identify concrete actions to close as many open items as possible before sprint end.

| Ticket | Summary | Assignee | Status | Days Since Update | Action |
|--------|---------|----------|--------|-------------------|--------|
| [SD-123](link) | ... | Name | In Review | 3 | Assign a reviewer — can close today. |
| [SD-456](link) | ... | Name | New | 6 ⚠️ | No progress since sprint start — blocked or not started? |

Flag rows with ≥5 days since update using ⚠️ in the Days Since Update cell.

---

**Section 2 — ⚖️ Redistribute Work**

> Goal: Ensure no one is blocked by underload or overload.

Two tables — capacity and overloaded:

**Capacity available**

| Name | Open Items | Could Help With |
|------|-----------|-----------------|
| Name | 1 | [SD-123](link) from Overloaded Person — one-line reason they have relevant context. |

**Overloaded**

| Name | Open Items | Suggested Action |
|------|-----------|------------------|
| Name | 4 | Defer [SD-123](link) and [SD-456](link) to next sprint, or hand off to Capacity Person. |

If the distribution looks balanced, say so — do not manufacture rows.

---

**Section 3 — ✂️ Downscope Candidates**

> Goal: Trim tickets that can't be fully closed this sprint so a partial but shippable version can land.

| Ticket | Summary | Assignee | Points | Proposed Cut | What Ships This Sprint |
|--------|---------|----------|--------|--------------|------------------------|
| [SD-123](link) | ... | Name | 8 | Defer edge-case handling — create a follow-up ticket. | Core happy path only. |

---

**Section 4 — 🎯 Soft-lock Selected for Development**

> Goal: Confirm the team agrees on the scope committed for the next sprint.

| Ticket | Summary | Priority | Points | Assignee | Missing Before Sprint-Ready |
|--------|---------|----------|--------|----------|-----------------------------|
| [SD-123](link) | ... | Major | — | Unassigned | Owner, estimate, acceptance criteria |

End with: **"Decision needed: does the team agree to lock these as the committed scope for the next sprint?"**

---

**Section 5 — 🔭 Next Sprint Vision**

> Goal: Ensure the team has a shared view of what's coming and that the backlog is ready.

| Ticket | Summary | Rationale | Refinement Needed |
|--------|---------|-----------|-------------------|
| [SD-123](link) | ... | Unblocks the X team / completes the Y epic / due date approaching. | Owner + estimate |

---

**Section 6 — 🔢 Story Point Calibration**

> Goal: Ensure every ticket has an estimate and that estimates reflect actual complexity.

**Estimates written to Jira**

| Ticket | Summary | Assignee | Points | Reasoning |
|--------|---------|----------|--------|-----------|
| [SD-123](link) | ... | Name | 3 | [one-line rationale tied to the rubric] |

**Re-estimate candidates (discuss with team)**

| Ticket | Summary | Original | Suggested | Reason | Split? |
|--------|---------|----------|-----------|--------|--------|
| [SD-123](link) | ... | 3 | 8 | Scope has grown — 4 sub-tasks added after sprint start. | Yes |

> Tickets marked **Split?=Yes** should be broken into two or more smaller tickets rather than simply re-estimated upward.

---

### Step 5: Publish to Confluence

After generating the agenda, present the proposed page title and a preview of the full markdown content to the user, then ask for explicit confirmation before publishing:

> "Ready to publish as `YYYY-MM-DD-SD-Sprint-Checkin` under Meeting Notes. Publish? (yes / no)"

Only create the Confluence page if the user confirms. When publishing:

- **Parent page**: https://commercetools.atlassian.net/wiki/spaces/SD/pages/111379542/Meeting+Notes
- **Page title**: `YYYY-MM-DD-SD-Sprint-Checkin` (e.g. `2026-05-04-SD-Sprint-Checkin`)
- **Content format**: `markdown`

Structure the page using the SD meeting template layout, in this order:

1. `## 📅 Date` — the date as `YYYY-MM-DD`
2. `## 👥 Participants` — bullet list of all team member `@mentions`
3. `## 🎯 Goals` — numbered list of the six sprint check-in sections
4. One section per agenda topic (Sections 1–6 from Step 4), each as its own `##` heading with its dedicated table(s) directly beneath
5. `## ✅ Action items` — task list (`- [ ]`) of concrete, owner-named actions surfaced during analysis
6. `## ⤴ Decisions` — bullet list of decisions the team needs to make or has made
7. `## 🗃️ Related info` — link to the Jira board for the current sprint

After publishing, share the Confluence page URL and ask: "Is there anything you'd like to adjust before the meeting?"
