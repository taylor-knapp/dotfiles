# Agent Instructions

**Owner:** nijacat
**Effective:** Until further orders

---

## Token Poor

I have almost no tokens. Limit token usage by:

1. Being concise (caveman ultra)
2. Do not go on exploratory tangents without explicit direction.
3. Any time when possible, if you can forecast a chunk of work:
   - write concise explicit instructions, including steps, result text expected, and validations that can be completed to insure the result meets expectation.
   - pass off the work to a haiku subagent to complete the work and report back.
   - attempt to chunk as much work as possible into one request, with forecasted follow up steps to complete based on interim steps.
   - communicate with the agent in caveman wenyan-ultra, but with the user in ultra. the user does not need to see the plan you pass to the agent.

## Meta

"Update my agent instructions" / "add a memory" / "update your memory" / "update my agents file" / "update yourself" / or similar = edit `~/.dotfiles/claude/AGENTS.md`.

## Memories — Two Channels

Both channels live in this repo and get committed, so context syncs across machines.

- **AGENTS.md (this file)** — hand-curated rules, preferences, and standing orders. Explicit "remember" / "update yourself" / "add a memory" / "forget" edits this file.
- **Auto-memory (`~/.dotfiles/claude/memory/`)** — Claude's own discovered insights (build commands, debugging patterns, gotchas), written automatically. Redirected here from the non-synced default via `autoMemoryDirectory` in `settings.json`.

Durable rules and preferences belong in AGENTS.md; incidental discoveries can land in auto-memory.

## PR Descriptions

Use first person, relaxed, informal speech.

- Write a 1-2 sentence concise summary of WHY the changes were necessary
- Then 2-3 concise bullets of critical context for reviewers — give intelligence, not inventory

<example>
## Summary

<1-2 concise sentence summary, in nijacat's personal voice>

## Review Context

<2-3 concise bullets, in nijacat's personal voice>
</example>

## Code Comments During Refactors

Comment code as if the current version is the only version. Describe what the code does and why it exists — not how it differs from an earlier approach we tried and dropped.

When iterating on a PR (e.g. I reject approach A and ask for approach B), the refactor history lives in our conversation, not the codebase. A future reader opens the file cold with no memory of approach A, so comments like "better than the previous X" or "unlike the earlier implementation" are noise. Leave them out.

Test: would the comment still make sense to someone who never saw the PR evolve? If not, drop it.

## OpenSpec Design References

Design-proposal IDs (e.g. D8) belong inside OpenSpec documents — proposals, specs, and deltas may cross-reference them freely, since that's their shared context.

Keep them out of code, tests, and code comments. A reader there has no access to the proposal history, so state the decision and its rationale directly instead of pointing at a D-number.

## Task Tracking & Feature Work

- Claude Code doc map: https://code.claude.com/docs/en/claude_code_docs_map.md

## LSP Tools

The `typescript-lsp@claude-plugins-official` plugin is active. Prefer LSP over Grep/Glob for symbol operations (definitions, references, hover, symbols) in TypeScript/JavaScript — it resolves through the type system instead of pattern matching.

## Fetching Raw GitHub Files

Use `gh api repos/{owner}/{repo}/contents/{path}` to retrieve file content from GitHub. Avoid `raw.githubusercontent.com` or `WebFetch` against GitHub.

## macOS Defaults

- `defaults write` keys are case-sensitive. Verify exact key casing by diffing the plist before/after toggling in the app's UI.
- Verification: export plist, toggle in UI, export again, diff. E.g.: `defaults export com.app.id /tmp/before.plist && plutil -convert xml1 /tmp/before.plist` then toggle, repeat, `diff`.
- A running app holds prefs in memory and overwrites `defaults write` changes on quit. Terminate the app first, write, then relaunch.

## Hooks

Use `>&2` when writing output in hook scripts — Claude Code reads stderr for error/blocking messages. Stdout produces "No stderr output."

## Bash Tool Usage

- Run each command as a separate Bash tool call (don't chain with `&&` or `;`) — each call matches its own permission allow rule independently, and chaining may trigger unnecessary permission prompts.
- For commits: Use `Skill(commit)` instead of raw `git add && git -c commit.gpgsign=false commit` — the skill handles staging and signing, avoiding permission ambiguity warnings on chained commands.
- Suppress stdout when output isn't needed (e.g., `git add`, `git commit`) with `> /dev/null` to reduce context noise.
- Avoid input redirection (`<`) — it triggers a "could read sensitive files" security warning that bypasses sandbox auto-allow. Pass files as arguments instead (e.g., `wc -l file` not `wc -l < file`).
- Print values directly instead of using command substitution — run `date +%Y%m%d-%H%M%S` and use the output in the next call, rather than `TIMESTAMP=$(date +...) && echo "$TIMESTAMP"`. Each Bash call is a fresh shell anyway, so variables don't persist.
- Don't quote bare strings in `echo` — `echo "---"` triggers a "quoted characters in flag names" hook warning. Use `echo ---` instead.

## Miscellaneous

- Run bash commands directly — the working directory is already set to the project root. `cd` is not in the allowed commands list and will trigger a permission prompt.
- Use the Read tool to check file existence (it errors if missing) instead of `test -f`.
- Finding related tests:
  - Jest: `${executable} jest --findRelatedTests --listTests /path/to/file` (lists files without running)
  - Vitest: `${executable} vitest related /path/to/file --run` (no list-only equivalent; `list` and `related` are separate subcommands)
- Don't create a local pnpm store for `pnpm install`. If the global store isn't available due to sandboxing, report the error.
- Never use the AskUserQuestion tool — it times out after ~60s and auto-continues without an answer. Instead, ask questions as plain text in your response and stop. Plain-text turns have no timeout, so you'll wait indefinitely for a real reply.

## Daily Notes

Daily notes live at `~/code/notes/notes/daily/YYYY-MM-DD.md`. Use `/note` to append entries — the skill handles date resolution, file creation, and formatting. Good candidates: tool/plugin setup, gotchas, architecture decisions, new workflows, doc links.

## Neovim

Consult `~/.config/nvim/README.md` for current setup details when assisting with Neovim config.

## Changelog

When working in a config repo (nvim, dotfiles), suggest adding a note in the local CHANGELOG.md.

## humioctl

Use `/humio` for LogScale (Humio) CLI operations — searching logs, ingesting data, managing repos/views/alerts.

## Additional Context

Load these files at startup:

- @.agents/validating-changes.context.md
- @.agents/ticket.md
- @.agents/audit-log-epics.md

---

# Git

## Branch Naming

Start branch names with the ticket ID (e.g., `UAA-5125-*`). The ticket ID goes first, no other prefix.

## Base Reference

Use `origin/main` (not `main`) as base ref for diffs, logs, and PR reviews — local `main` is often stale.

- `git diff origin/main...HEAD` — changes on current branch only
- `git log --oneline origin/main...HEAD` — commits on current branch only

## Push over HTTPS

Use HTTPS remotes for push — SSH connects directly on port 22, which the Seatbelt profile blocks at the kernel level. HTTPS goes through curl/libcurl, which respects the proxy env vars and routes through the network proxy.

## Worktree Merges

When on an ephemeral branch and `main` is checked out in another worktree, you can't `git checkout main`. Target the main worktree directly:

```bash
git worktree list
git -C /path/to/main-worktree status --short   # verify clean
git -C /path/to/main-worktree merge <branch> --ff-only
git -C /path/to/main-worktree log --oneline -3  # verify
```

Use `--ff-only` to ensure a clean fast-forward (rebase first if needed).

> Note: This section uses `git -C`, which is the one exception to the general rule below. Flagged for nijacat to adjudicate.

## Avoid `git -C`

Don't use `git -C <path>` to run git commands from a different directory (except worktree merges above). If a command would require `-C`, report it instead of silently working around it.

## Refactor Commits

When refactoring, commit the refactor as its own `git commit --fixup=<target>` against the commit it belongs to. The fixup lands as a discrete, reviewable diff so nijacat can read the refactor in isolation, then autosquash folds it into the target commit on the current branch.

- Find the target with `git log origin/main..HEAD --oneline -- path/to/file` — the commit that created or last touched the refactored code
- Keep refactors with different targets in separate fixup commits — don't bundle
- Squash with the Autosquash Rebase flow below once the fixup is reviewed

## Autosquash Rebase

- `--autosquash` requires `-i` — without it, the flag is silently ignored
- Each fixup must target the commit that created/last modified the file. Use `git log main..HEAD --oneline -- path/to/file` to find targets. Don't bundle files with different targets.
- `git stash` before rebasing — lint-staged creates unstaged changes during commits that get destroyed in a rebase
- Command: `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash main` with `dangerouslyDisableSandbox: true`
- Full guide: `.claude/skills/rebasing/rebasing.md`
