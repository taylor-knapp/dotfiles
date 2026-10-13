---
name: pr
description: Create pull requests with proper branch naming and descriptions. Use when creating PRs, pushing branches, or the user mentions "pull request" or "PR".
allowed-tools: Bash(git push:*), Bash(gh pr create:*), Bash(gh pr edit:*), Read, Write, Edit, Glob, AskUserQuestion
disable-model-invocation: true
---

# Pull Request Creation

Create PRs following branch naming conventions and description standards.

## Context

Current repository state:

**Branch & Status:**
!`git status`

**Commits ahead of main:**
!`git log main..HEAD --oneline`

**Changes summary:**
!`git diff main...HEAD --stat`

**Upstream tracking:**
!`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1 || echo "No upstream configured"`

## Branch Formats

This repository enforces branch naming via pre-commit hooks. Valid formats:

| Format                   | Pattern                           | Example                       |
| ------------------------ | --------------------------------- | ----------------------------- |
| With Jira ticket         | `{UAA\|DEVX}-{number}-{name}`     | `UAA-4839-fix-snapshot`       |
| With k8s prefix + ticket | `k8s/{UAA\|DEVX}-{number}-{name}` | `k8s/UAA-123-update-config`   |
| Chore (no ticket)        | `chore/{name}`                    | `chore/update-deps`           |
| FLD (no ticket)          | `fld/{name}`                      | `fld/investigate-issue`       |
| Preview                  | `preview/{name}`                  | `preview/feature-demo`        |
| Dependabot               | `dependabot/{name}`               | `dependabot/npm-lodash-4.0.0` |
| Renovate                 | `renovate/{name}`                 | `renovate/typescript-5.x`     |

## Determining Jira Project

**Read AGENTS.md > Package to Project Mapping** to determine which project (UAA or DEVX) to use:

1. Check which package the changes affect
2. Look up the project in the mapping table
3. If ambiguous, ask the user which project to use

## Workflow

The context section above provides all git information. Use it to determine the current state.

### Creating a new PR

1. **Analyze the context** to understand what changes are being included
2. **Determine project** from package context (UAA or DEVX) - see AGENTS.md
3. **If no Jira ticket in branch name**: Ask user - "Do you have a Jira ticket number? (If not, I'll use `chore/` prefix)"
4. **Push with upstream**: `git push -u origin <branch-name>`
5. **Create PR**: Use `gh pr create` with `$(cat <<'EOF' ... EOF)` for the body (see Commands below)
6. Display PR URL prominently

### Updating an existing PR

1. **Analyze the context** to see new commits and upstream status
2. **Push commits**:
   - If "No upstream configured": `git push -u origin <branch-name>`
   - If upstream exists: `git push`
3. **Update PR description**: Use `gh pr edit` with `$(cat <<'EOF' ... EOF)` for the body (see Commands below)
4. Display PR URL prominently

## PR Description Format

**Principles:**

- Write for a reviewer context-switching to your PR — give them what the diff won't
- Never restate the diff; the reviewer is about to read the code
- Fewer words are always better than more
- Each section has ONE job — no repeating information across sections

```markdown
## Motivation

[In as few words as possible, WHY is this PR necessary. If unclear, ask the engineer.]

## Change Summary

[In as few sentences as possible, what is the bulk of this PR doing? How does it address the motivation? Don't enumerate files or changes — the reviewer will read the diff.]

## Review Context

[OPTIONAL — only include if it genuinely helps a reviewer context-switching to this PR. 1-5 bullets max with specific insights not covered in Motivation or Summary: reading order suggestions, design decisions worth noting, open questions, deployment gotchas. If this section wouldn't save the reviewer time, skip it entirely.]
```

**Anti-patterns to avoid:**

- ❌ Bullet-listing every file or function changed — that's what the diff is for
- ❌ Summary restating Motivation in different words
- ❌ Review Context that just repeats what Summary already said
- ✅ Motivation gives the "why" → Summary explains the approach → Review Context helps the reviewer navigate

## Commands

```bash
# Push with upstream (ALWAYS use -u flag for first push)
git push -u origin <branch-name>

# Create PR with heredoc body
gh pr create \
  --title "<title>" \
  --body "$(cat <<'EOF'
<pr body here>
EOF
)" \
  --base main \
  --assignee @me

# Update existing PR description with heredoc body
gh pr edit <pr-number> --body "$(cat <<'EOF'
<pr body here>
EOF
)"
```

## Sandbox Mode Notes

### Git Config Permission Error

When pushing with `-u` flag in sandbox mode, you may see:

```
error: could not write config file .git/config: Operation not permitted
```

This error occurs because sandbox prevents writing to `.git/config` to save the tracking relationship. **The push itself succeeds**, but the branch tracking isn't saved.

**Action**: If you see this error in the output:

1. **Immediately re-run** the same `git push -u origin <branch-name>` command with `dangerouslyDisableSandbox: true`
2. This will save the tracking relationship so future pushes work with just `git push`
3. Briefly explain to the user: "Re-ran push outside sandbox to save branch tracking."

## PR Title Format

| Scenario     | Format                         |
| ------------ | ------------------------------ |
| With Jira    | `{JIRA-TICKET}: {description}` |
| Without Jira | `chore: {description}`         |

## Critical Rules

- Use a valid branch format — pre-commit hook rejects invalid names
- Check AGENTS.md for package-to-project mapping
- Ask for Jira ticket if not provided (unless using exempt prefix)
- Wait for user response before creating branch
- Use `git push -u origin <branch-name>` to set upstream when pushing
- Display PR URL first and prominently after creation

For detailed examples and available labels, see [REFERENCE.md](REFERENCE.md).
