# Pull Request Creation: Full Reference

Complete documentation for PR creation workflow.

## Command Purpose

Create a pull request following the project's branch naming conventions and PR description standards. This command handles branch creation, committing changes, pushing to remote, and creating the PR via GitHub CLI.

## Prerequisites

Before executing, ensure:

- GitHub CLI (`gh`) is installed and authenticated (`gh auth status`)
- Current working directory is the repository root
- Changes are staged or ready to be committed
- User has push access to the repository

## Branch Naming Conventions

This repository enforces branch naming via pre-commit hooks (`.husky/pre-commit`).

### Valid Branch Formats

| Format       | Pattern                                  | When to Use                           |
| ------------ | ---------------------------------------- | ------------------------------------- |
| Jira ticket  | `{UAA\|DEVX}-{number}-{name}`            | Feature work linked to a ticket       |
| k8s + ticket | `k8s/{UAA\|DEVX}-{number}-{name}`        | Kubernetes config changes with ticket |
| k8s-config   | `k8s-config/{UAA\|DEVX}-{number}-{name}` | Kubernetes config changes with ticket |
| chore        | `chore/{name}`                           | Maintenance without ticket            |
| fld          | `fld/{name}`                             | On-call/emergent investigation        |
| preview      | `preview/{name}`                         | Feature preview/demo branches         |
| dependabot   | `dependabot/{name}`                      | Automated dependency updates          |
| renovate     | `renovate/{name}`                        | Automated dependency updates          |

### Determining Jira Project (UAA vs DEVX)

**IMPORTANT**: This repository serves multiple teams. Check AGENTS.md > Package to Project Mapping:

| Package                   | Jira Project | Team                  |
| ------------------------- | ------------ | --------------------- |
| `agent-gateway`           | UAA          | Users, Access & Audit |
| `mcp-config-service`      | UAA          | Users, Access & Audit |
| `multitenant-mcp-service` | DEVX         | Dev Tooling           |

**Workflow:**

1. Identify which package(s) the PR affects
2. Look up the corresponding Jira project
3. If changes span multiple packages with different projects, ask the user which project to use

## Execution Steps

### Step 1: Determine Branch Name and Jira Ticket

1. **Identify affected package(s)**: Review the changes to determine which package is being modified
   - If changes are in `packages/agent-gateway/` or `packages/mcp-config-service/` → UAA project
   - If changes are in `packages/multitenant-mcp-service/` → DEVX project
   - If ambiguous → Ask user which project

2. **Check for Jira ticket in request**: Look for ticket numbers (e.g., "UAA-4839", "DEVX-123")
   - If ticket found: Use ticket format and proceed to Step 2
   - If ticket not found AND not using exempt prefix: **Ask user with clean, focused prompt**:
     "Do you have a Jira ticket number for this PR? (If not, I'll use the `chore/` prefix)"
   - **CRITICAL**: **WAIT for user response before proceeding** - do not execute git commands until user responds

3. **Infer branch name from context**: Review conversation history to understand what work was done
   - If context is clear, create descriptive branch name
   - Use kebab-case, descriptive names (e.g., `fix-snapshot-storage`, `add-missing-versions-logging`)

### Step 2: Create Branch and Commit Changes

1. **Create and switch to branch**:

   ```bash
   git checkout -b <branch-name>
   ```

2. **Check git status** to see if changes need to be committed:

   ```bash
   git status
   ```

3. **If changes exist and are not committed**:
   - Stage changes: `git add .` (or specific files)
   - Commit changes: `git commit -m "<type>: <description>"`
   - **CRITICAL**: Commit messages MUST follow commitlint format (conventional commits)

4. **Push branch to remote**:

   ```bash
   git push -u origin <branch-name>
   ```

### Step 3: Create PR Description

Keep PR descriptions **concise**. Follow this structure:

**Include:**

- **What changed**: Brief summary of the changes
- **Why**: Reason for the change
- **Important considerations**: Any critical context, breaking changes, migration steps
- **AI attribution**: End with `(Co-authored by Claude Code)`

**Omit:**

- Implementation details (code changes are visible in the diff)
- Testing steps (assume standard testing practices)
- Benefits sections (focus on what and why)

**Example PR Description:**

```markdown
## Summary

Updated agent-gateway service to handle rate limits more gracefully by adding exponential backoff retry logic.

## Why

The service was failing silently when rate limits were hit, causing request failures that required manual intervention.

## Important Considerations

- Retry logic uses exponential backoff with max 3 attempts
- Failed requests are now logged with ERROR level for better observability
- No breaking changes - existing behavior preserved for successful cases

(Co-authored by Claude Code)
```

### Step 4: Create PR Using GitHub CLI

1. **Verify GitHub CLI authentication**:

   ```bash
   gh auth status
   ```

2. **Determine PR title**:
   - If Jira ticket exists: `{JIRA-TICKET}: {description}`
   - If no ticket: `chore: {description}`

3. **Create PR with GitHub CLI**:

   ```bash
   gh pr create \
     --title "<PR title>" \
     --body '## Summary

   <description>

   ## Why

   <reason>

   ## Important Considerations

   - <consideration 1>
   - <consideration 2>

   (Co-authored by Claude Code)' \
     --base main \
     --assignee @me
   ```

   **Critical flags:**
   - `--body '<content>'`: Pass body directly as single-quoted string
   - `--base main`: Target branch (defaults to main)
   - `--assignee @me`: Assigns PR to currently authenticated user

4. **Capture PR URL from command output**: Store the URL for display

### Step 5: Return PR URL to User

After successful PR creation:

1. **ALWAYS display the PR URL first and prominently**:
   - Format: `PR created: <URL>`
   - The URL is clickable and allows the user to view the PR immediately
   - Display this on its own line, clearly visible

## Critical Rules

- **ALWAYS** use a valid branch format - pre-commit hook will reject invalid names
- **ALWAYS** check AGENTS.md for package-to-project mapping when determining Jira project
- **ALWAYS** ask for Jira ticket if not provided and not using exempt prefix
- **CRITICAL**: **WAIT for user response about Jira ticket before creating branch**
- **ALWAYS** use commitlint format: `<type>: <description>`
- **ALWAYS** keep PR descriptions concise - focus on what and why
- **ALWAYS** use `gh pr create` with `--base main --assignee @me`
- **ALWAYS** display PR URL prominently and first after creation

## Example Workflows

### Example 1: PR with UAA Ticket

**User request**: "Create PR with UAA-4839 for fixing agent-gateway rate limiting"

**Execution**:

1. Changes affect `packages/agent-gateway/` → UAA project (matches ticket)
2. Ticket `UAA-4839` provided, inferred branch name `fix-rate-limiting`
3. Validated format: `UAA-4839-fix-rate-limiting`
4. Created branch, committed, pushed
5. Created PR with title "UAA-4839: Fix rate limiting"
6. Displayed PR URL: "PR created: https://github.com/{owner}/{repo}/pull/{number}"

### Example 2: PR with DEVX Ticket

**User request**: "Create PR for DEVX-456 adding multitenant support"

**Execution**:

1. Changes affect `packages/multitenant-mcp-service/` → DEVX project (matches ticket)
2. Ticket `DEVX-456` provided
3. Created branch: `DEVX-456-add-multitenant-support`
4. Created PR with title "DEVX-456: Add multitenant support"

### Example 3: PR without Jira Ticket

**User request**: "Create PR for updating dependencies"

**Execution**:

1. No ticket found → Asked: "Do you have a Jira ticket number? (If not, I'll use `chore/update-dependencies`)"
2. **WAIT for response** → User: "No ticket"
3. Validated format: `chore/update-dependencies`
4. Created branch, committed, pushed
5. Created PR with title "chore: Update dependencies"

### Example 4: Ambiguous Package Context

**User request**: "Create PR for adding shared utilities"

**Execution**:

1. Changes affect `shared/` directory → Could be UAA or DEVX
2. Asked: "Which Jira project should this PR be associated with? UAA or DEVX?"
3. **WAIT for response** → User: "UAA-5010"
4. Created branch: `UAA-5010-add-shared-utilities`

## Branch Validation

The pre-commit hook validates branch names. If your branch is rejected:

1. Check it matches one of the valid formats
2. Ensure Jira ticket prefix is uppercase (UAA, DEVX)
3. Ensure ticket number follows the prefix with a hyphen

Valid examples:

- `UAA-4839-fix-bug`
- `DEVX-123-new-feature`
- `k8s/UAA-100-update-config`
- `chore/update-deps`
- `fld/investigate-issue`
