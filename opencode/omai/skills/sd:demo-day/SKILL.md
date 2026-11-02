---
name: sd:demo-day
description: Use this skill when a team is preparing for their end-of-sprint demo day. Gathers completed and in-progress sprint items from Jira grouped by assignee, then creates a Confluence meeting notes page with a structured demo schedule — including presenter @mentions and Jira ticket smart links — following the team's existing meeting notes format.
---

# Demo Day Prep

> **Requires:** access to Jira and Confluence via available tools.

## Purpose

Help a team prepare for their end-of-sprint demo day. The output is a Confluence meeting notes page with a demo schedule table, one row per presenter, populated from the active Jira sprint. Each demo entry includes Jira ticket smart links and proper @mentions so everyone is notified.

## Instructions

### Step 1: Intake

Check what is already known from the conversation. Ask only what is missing:

- **Jira project key**: Which project to pull the active sprint from (e.g. `SD`).
- **Confluence space key**: Which space holds the team's meeting notes (e.g. `SD`). Defaults to the same key as the Jira project.
- **Demo date**: Defaults to tomorrow. Confirm if the user specifies a different date.
- **Known additions**: Any demos the user wants to add manually (e.g. a guest presenter, a topic not tied to a Jira ticket)?

Collect all answers before proceeding.

### Step 2: Gather sprint data from Jira

1. Call `getAccessibleAtlassianResources` to obtain the `cloudId`.
2. Query Jira using JQL:
   ```
   project = <KEY> AND sprint in openSprints() ORDER BY assignee ASC
   ```
3. For each issue, collect: `key`, `summary`, `status`, `issuetype`, `assignee` (display name + account ID).
4. Group issues by assignee. Exclude unassigned issues from the demo schedule (note them separately if present).
5. For each assignee, identify their **primary demo items** — prefer closed/in-review tickets as completed work to showcase, and note any significant in-progress items as progress updates.

### Step 3: Find the meeting notes parent page

1. Search Confluence for a page titled "Meeting Notes" in the target space.
2. Retrieve the most recent child page to understand the team's format (structure, emoji headings, table layout).
3. Note the `pageId` of the "Meeting Notes" parent — the new page will be created as a child of it.

### Step 4: Resolve presenter account IDs

For each unique assignee found in Step 2, call `lookupJiraAccountId` to retrieve their Confluence-compatible account ID. These are needed to render proper `@mention` nodes in the Confluence ADF body.

### Step 5: Create the Confluence page

Create a new page as a child of the Meeting Notes parent page, using ADF (Atlassian Document Format) content. Follow the team's existing meeting notes structure exactly, adapting sections as needed for a demo day context.

**Page title**: `<YYYY-MM-DD>-<SPACE-KEY>-Demo-Day` (e.g. `2026-05-08-SD-Demo-Day`)

**Page structure** (ADF, remove any section that has no content):

1. **📅 Date** — the demo date
2. **👥 Participants** — bullet list of `mention` nodes for every presenter
3. **🎯 Goals** — one sentence: "Showcase completed sprint work. Each team member demos their key deliverables from the sprint."
4. **🗣️ Demo Schedule** — table with columns: **Presenter** | **Demo** | **Notes**
   - One row per assignee
   - Presenter cell: `mention` node using the resolved account ID
   - Demo cell: one paragraph per demo item, each starting with an `inlineCard` node pointing to the Jira ticket URL (`https://<atlassian-site>/browse/<KEY>`), followed by a short description
   - Notes cell: empty (for the team to fill in live)
   - Order: prioritise presenters with the most completed work first
5. **✅ Action items** — empty task list for the team to populate

**ADF node types to use:**
- `mention` with `attrs.id` set to the account ID for presenter references
- `inlineCard` with `attrs.url` set to the full Jira ticket URL for ticket references
- `taskList` / `taskItem` for action items
- `table` / `tableRow` / `tableHeader` / `tableCell` for the demo schedule

### Step 6: Report back

After creating the page, report:
- The page title and direct URL
- A plain-text summary of the demo schedule (presenter → demo topic) so the user can verify it looks right

Ask: "Would you like to adjust the order of presenters, add any manual entries, or update any demo descriptions?"
