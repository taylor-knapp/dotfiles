---
name: update-context
description: Apply research-backed writing principles when adding or editing agent context (AGENTS.md, skills, hooks, settings). Use when the user asks to "remember", "update yourself", "add a memory", "update context", "update agents", or modifies any context/instruction file.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
disable-model-invocation: true
---

# Update Agent Context

Write context instructions optimized for current Claude models and Claude Code's system prompt architecture.

## Trigger Conditions

Activate this skill when:

- User says "remember," "update yourself," "add a memory," "update context," "update agent deets," or similar
- User asks to modify AGENTS.md, a skill, a hook, or settings.json
- You need to record a new rule, preference, or operational note

## Target Files

| File | Purpose |
| --- | --- |
| `~/.dotfiles/claude/AGENTS.md` | Universal rules, preferences, standing orders. Linked as `~/.claude/CLAUDE.md` |
| `~/.dotfiles/claude/skills/*/SKILL.md` | Action/domain-specific rules, loaded on trigger |
| `~/.dotfiles/claude/settings.json` | Deny rules, hook wiring. Linked as `~/.claude/settings.json` |
| `~/.dotfiles/claude/hooks/*.sh` | Hook scripts, referenced by path from settings.json |

Editing these = editing live global config. New skill dirs need `~/.dotfiles/claude/deploy.sh` to get linked into `~/.claude/skills`.

## Claude Code Context Hierarchy

Context loads in a specific order. More specific wins on conflicts. All levels combine — they don't replace.

| Location | Scope | When loaded | Survives compaction? |
|---|---|---|---|
| `~/.claude/CLAUDE.md` | Global (all projects) | Session start | Yes |
| `./CLAUDE.md` (project root) | Project-wide | Session start | Yes |
| `./CLAUDE.local.md` | Project, personal | Session start | Yes |
| `./subdir/CLAUDE.md` | Subdirectory-specific | Session start | Yes |
| `.claude/rules/*.md` (no frontmatter) | Project-wide | Session start | Yes |
| `.claude/rules/*.md` (with `paths:`) | Pattern-triggered | On file read | Yes |
| `.claude/agents/*.md` | On-demand subagents | When invoked | N/A (fresh context) |
| `skills/*/SKILL.md` | Action-specific | When skill triggers | N/A (loaded on demand) |

**Key behavior:** `CLAUDE.md` and rules survive context compaction (`/compact`) — Claude re-reads them from disk. Conversational instructions are lost. This makes these files the only safe place for instructions that must survive long sessions.

## Reference

Full research: [REFERENCE.md](./REFERENCE.md)

## How Claude Processes Context Instructions

Understanding these Claude-specific behaviors should inform every edit:

1. **Claude Code's system prompt consumes ~50 of your instruction budget.** Frontier Claude models reliably follow ~150-200 instructions total. Every line in AGENTS.md competes with the system prompt and with every other line. Anthropic: "Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"

2. **Opus 4.5/4.6 overtrigger on aggressive language.** Anthropic explicitly warns: "Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'". Aggressive emphasis that compensated for older models' inattention now causes newer Claude models to over-apply rules.

3. **Claude is tuned for XML parsing.** Anthropic: Claude has been "specifically tuned to pay special attention to XML structure." XML tags provide unambiguous section separation and survive tokenization better than whitespace-based formats. Use XML within Markdown files for data boundaries (examples, templates, quoted content).

4. **Claude generalizes better with rationale.** Anthropic: "Instead of 'NEVER use ellipses,' write 'Your response will be read aloud by a text-to-speech engine, so never use ellipses since the engine will not know how to pronounce them.'" The "why" lets Claude apply rules correctly to edge cases.

5. **Positive framing outperforms negative framing.** Anthropic's docs: "Tell Claude what to do instead of what not to do." Based on Ironic Process Theory — representing "don't do X" requires Claude to first activate the concept of X.

6. **`@` referenced files are loaded at startup, skill files are loaded on trigger.** Files referenced with `@` in CLAUDE.md/AGENTS.md are pulled into context automatically — they still consume instruction budget. True progressive disclosure comes from **skill files**, which only load when the skill is triggered. Prefer skills over `@` includes for anything not needed in every session.

## Writing Checklist

Apply in order before writing or editing any context instruction:

### 1. Can it be a guardrail instead?

Claude Code's enforcement hierarchy, from most to least reliable:

1. **Mechanical guardrails** — hooks, deny rules, linters
2. **Point-of-use rules** — skill files loaded during the relevant action
3. **Central context** — AGENTS.md, loaded into every conversation
4. **Emphasis/formatting** — CAPS, bold — least reliable, diminishing returns

Where to create guardrails:

- Hook: script in `~/.dotfiles/claude/hooks/`, wired up in `settings.json`, applies globally
- Deny rule: `~/.dotfiles/claude/settings.json`, applies globally
- Sandbox (fs, network, per-command argv policy): nono profiles in `~/.dotfiles/nono/profiles/`
- Linter: eslint, prettier config (per-project)

If a guardrail exists, the written instruction only needs to explain the _why_ so future sessions understand the guardrail's purpose — not re-state the rule.

### 2. Does it already exist?

Search AGENTS.md and `skills/` for overlapping content before adding. Update existing rules rather than duplicating. Redundancy across files is intentional only for 3-5 critical rules.

### 3. Where does it belong?

- Universal, and Claude would make mistakes without it: `AGENTS.md`
- Action- or domain-specific (PR, macOS defaults, tickets): `skills/*/SKILL.md` — new skill if none fits
- One repo only: that repo's `CLAUDE.md` or `.claude/rules/*.md` (`paths:` frontmatter only works at project level)
- Specialized repeatable workflow needing fresh context: `.claude/agents/*.md`

If a rule is critical enough to repeat, place it in both the central file and the point-of-use file.

### 3a. Using path-scoped rules (`.claude/rules/` with frontmatter)

Path-scoped rules trigger only when Claude reads files matching the specified globs:

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"
---
# API Development Rules
- All API endpoints must include input validation
```

**YAML quoting is mandatory** — glob patterns starting with `{` or `*` are reserved YAML indicators and fail silently if unquoted. Always quote all glob patterns.

**Known limitations (as of March 2026):**
- Rules trigger on **file reads only**, not writes/creates — place creation conventions in always-on rules
- `paths:` vs `globs:` — the documented key is `paths:`, but `globs:` works more reliably in some versions. Test both if path-scoping doesn't fire.
- User-level rules (`~/.claude/rules/`) ignore `paths:` frontmatter entirely — they always load globally
- Git worktrees have path resolution bugs that bypass filtering

**Workaround for write-trigger gap:** Place file creation conventions in always-on rules (no frontmatter), or ensure Claude reads an existing file in the target directory before creating new files.

### 4. Write it for Claude

**Tone:** Direct, natural language. Imperative mood ("Use," "Run," "Write"). Anthropic's golden rule: "Show your prompt to a colleague with minimal context and ask them to follow it. If they'd be confused, Claude will be too."

**Positive framing first.** Lead with what to do. Reserve "Never do X" for hard safety boundaries only, and always pair with the positive alternative.

<example type="positive-framing">
Instead of: "Do not use markdown in your response"
Write: "Write your response as flowing prose paragraphs"

Instead of: "Never use magic numbers"
Write: "Extract all numeric literals into named constants"
</example>

**Include the why.** Inline rationale after rules that aren't self-evident:

<example type="inline-rationale">
- Use `origin/main` (not `main`) as base ref — local `main` is often stale
- Run prettier before eslint — it auto-fixes formatting that would show as lint errors
</example>

**Be specific.** Exact commands in code blocks. Exact file paths. Exact flag names.

**Be brief.** Each rule in 1-2 lines. AGENTS.md total target: under 300 lines. For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.

**Emphasis budget: 3-5 items max across the entire file.** Opus 4.5/4.6 overtrigger on aggressive language. If a rule needs ALL CAPS to be followed, it needs a mechanical guardrail instead.

**Use XML tags for data boundaries.** Markdown for overall structure (headers, bullets, tables). XML tags where Claude needs to distinguish instructions from examples, templates, or quoted content:

```markdown
## Commit Message Format

<example>
feat(auth): add session token rotation

Rotate tokens on refresh to meet compliance requirements.
</example>
```

**Use few-shot examples for judgment calls.** When a rule involves style or tone (commit messages, PR descriptions), 2-3 concrete examples steer Claude more reliably than prose descriptions.

### 5. Verify the edit

After writing:

1. Read the modified file to confirm the edit landed correctly
2. Check total line count — flag if AGENTS.md exceeds 300 lines
3. Check for contradictions with other rules in the same file
4. Check for unintentional duplication

## Anti-Patterns — Do Not Write

| Pattern                                   | Why it fails with Claude                                          | Instead                                             |
| ----------------------------------------- | ----------------------------------------------------------------- | --------------------------------------------------- |
| "CRITICAL: YOU MUST" on every rule        | Opus 4.5/4.6 overtrigger — applies rules too aggressively         | Natural language, reserve emphasis for 3-5 items    |
| Emotional stakes ("lives depend on this") | Zero effect on compliance (Wharton 2025)                          | State the rule directly                             |
| Long prose paragraphs                     | Claude follows structured rules more reliably than embedded prose | Bullet + code block                                 |
| Restating what a hook enforces            | Wastes instruction budget (~150-200 total)                        | Reference the guardrail, explain the why            |
| Negative-only framing ("NEVER do X")      | Claude activates the concept of X to avoid it                     | Positive directive first, negative as reinforcement |
| Generic persona ("You are an expert")     | No measurable accuracy improvement on Claude                      | Omit entirely                                       |
| Everything in AGENTS.md                   | Bloated files cause Claude to deprioritize instructions           | Move action-specific rules to skill files (loaded on trigger, not at startup) |

## Example: Good vs Bad

**Bad:**

```markdown
## GITHUB FILES — NUCLEAR PROTOCOL

> HALT. READ THIS BEFORE EVERY FETCH OR MILLIONS DIE.

NEVER EVER use WebFetch on GitHub. It is EXTREMELY DANGEROUS and your
mission is over. This is ABSOLUTELY CRITICAL.
```

**Good:**

```markdown
## GitHub Files

Fetch GitHub file content with `gh api repos/{owner}/{repo}/contents/{path}`
rather than raw.githubusercontent.com or WebFetch — the sandbox can only
allow GitHub by domain, so raw fetches are a prompt-injection vector.
```

Both convey identical information. The second spends its tokens on rationale and specificity instead of emphasis and emotional framing — same budget, better allocation. It leads with the positive directive and spends no emphasis budget.
