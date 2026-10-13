# Writing Effective LLM Context Instructions — Research Reference

Comprehensive reference for writing system prompts, CLAUDE.md files, and AGENTS.md files. Based on academic research, official documentation from Anthropic and OpenAI, and practitioner findings (as of March 2026).

---

## 1. What Actually Works (Strong Evidence)

### 1.1 Clarity and Specificity

The single most robust finding across all sources. Clear, specific, unambiguous instructions outperform every other technique — emotional manipulation, threats, tips, personas, or stylistic tricks.

- The "DETAIL Matters" paper (2024) showed that simply rewording a prompt can produce a 30+ point accuracy gap.
- The "26 Principles" paper found specialized, specific prompts enhanced quality (+57.7%) and accuracy (+36.4%) on GPT-4.
- Anthropic's golden rule: "Show your prompt to a colleague with minimal context and ask them to follow it. If they'd be confused, Claude will be too."

**Application:** Instead of "make sure the code is good," write "run `pnpm exec eslint` and fix all errors and warnings before marking complete."

Sources:

- [DETAIL Matters (arXiv 2512.02246)](https://arxiv.org/abs/2512.02246)
- [26 Principles (arXiv 2312.16171)](https://arxiv.org/html/2312.16171v2)
- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### 1.2 Structured Formatting

Format alone can cause up to 40% performance variance. Claude is specifically tuned for XML tag parsing. GPT models prefer Markdown.

- "Does Prompt Formatting Have Any Impact on LLM Performance?" (2024) tested plain text, Markdown, JSON, and YAML with identical content. No universal optimal format exists, but structure always beats unstructured prose.
- Anthropic documentation explicitly recommends XML tags for Claude: they provide unambiguous section separation, handle nesting well, and survive tokenization better than whitespace-based formats.
- For CLAUDE.md and AGENTS.md files: Markdown headers and bullet points are the natural fit since these are Markdown files. Use consistent heading hierarchy.

**Application:** Use Markdown headers to create clear sections. Use bullet lists for rules. Use tables for reference data. Use code blocks for exact commands. Never write rules as prose paragraphs.

Sources:

- [Prompt Formatting Impact (arXiv 2411.10541)](https://arxiv.org/html/2411.10541v1)
- [Anthropic XML Tags Guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags)
- [XML vs Markdown Analysis (Medium)](https://medium.com/@isaiahdupree33/optimal-prompt-formats-for-llms-xml-vs-markdown-performance-insights-cef650b856db)

### 1.3 Positive Framing ("Do X") Over Negative Framing ("Don't Do Y")

Based on Ironic Process Theory (the "white bear problem"), telling an LLM "don't do X" requires it to first represent X, which paradoxically makes X more likely. Research shows InstructGPT actually performs _worse_ with negative prompts as it scales.

Anthropic's own documentation: "Tell Claude what to do instead of what not to do."

**Application:**

| Instead of...                          | Write...                                            |
| -------------------------------------- | --------------------------------------------------- |
| "Do not use markdown in your response" | "Write your response as flowing prose paragraphs"   |
| "Never use magic numbers"              | "Extract all numeric literals into named constants" |
| "Don't run commands without checking"  | "Verify the command exists before running it"       |

**Exception:** Negative instructions retain value for hard safety boundaries where the cost of violation is high and there's no clean positive reframing. E.g., "NEVER run bare `git commit`" is acceptable because the positive framing "always use `git -c commit.gpgsign=false commit`" should accompany it, and the negative reinforces the boundary.

Sources:

- [The Pink Elephant Problem (16x Engineer)](https://eval.16x.engineer/blog/the-pink-elephant-negative-instructions-llms-effectiveness-analysis)
- [Why Positive Prompts Outperform (Gadlet)](https://gadlet.com/posts/negative-prompting/)
- [Framing Effects Research (arXiv 2502.17091)](https://arxiv.org/abs/2502.17091)

### 1.4 Explain Why — Context and Motivation

Explaining _why_ a rule exists helps the model generalize to novel situations. Without the "why," the model applies rules rigidly or ignores them when context seems different.

Anthropic's documentation: "Instead of 'NEVER use ellipses,' write 'Your response will be read aloud by a text-to-speech engine, so never use ellipses since the engine will not know how to pronounce them.'"

**Application:** Every non-obvious rule should have a brief rationale:

| Rule only                              | Rule + rationale                                                                                                     |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| "Always use `origin/main` as base ref" | "Use `origin/main` (not `main`) as base ref — local `main` is often stale, `origin/main` stays current from fetches" |
| "Run prettier before eslint"           | "Run prettier first — it auto-fixes formatting that would otherwise appear as eslint errors, saving a round-trip"    |

Sources:

- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### 1.5 Brevity — Less Is More

Frontier LLMs reliably follow approximately 150-200 instructions. Claude Code's system prompt already contains ~50. Every instruction in CLAUDE.md/AGENTS.md competes for attention with every other instruction.

- HumanLayer's team CLAUDE.md is under 60 lines. Community consensus target: under 300 lines.
- Anthropic: "Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"
- For each line, ask: "Would removing this cause Claude to make mistakes?" If not, cut it.
- Content that's irrelevant to most tasks dilutes the signal for all tasks.

**Application:** Prefer mechanical guardrails (hooks, linters, deny rules) over written instructions. A hook that blocks unsigned commits is worth more than 10 lines explaining why you should sign commits. Reserve written instructions for things that can't be enforced mechanically.

Sources:

- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Builder.io: CLAUDE.md Guide](https://www.builder.io/blog/claude-md-guide)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Using CLAUDE.md Files (Anthropic Blog)](https://claude.com/blog/using-claude-md-files)

### 1.6 Repetition of Critical Rules Across Locations

"Prompt Repetition Improves Non-Reasoning LLMs" (Leviathan et al., Google Research, 2025) showed that duplicating instructions improved performance — winning 47 of 70 benchmark-model combinations with zero losses.

**Application:** The most critical rules should appear:

1. In the central context file (AGENTS.md)
2. At the point of use (the relevant skill file)
3. As a mechanical guardrail (hook, linter, deny rule)

Example: the `cd` ban appears as a settings.json deny rule + a PreToolUse hook whose block message explains the why.

Sources:

- [Prompt Repetition (arXiv 2512.14982)](https://arxiv.org/abs/2512.14982)
- [VentureBeat Coverage](https://venturebeat.com/orchestration/this-new-dead-simple-prompt-technique-boosts-accuracy-on-llms-by-up-to-76-on/)

### 1.7 Few-Shot Examples

One of the most reliable steering mechanisms. 3-5 well-crafted examples that cover edge cases dramatically improve consistency. More effective than lengthy explanations of what you want.

**Application:** When a rule involves judgment (e.g., commit message style, PR description tone), include 2-3 concrete examples of correct output rather than describing what you want in prose.

---

## 2. What Moderately Works (Use With Caution)

### 2.1 Emphasis Markers — Sparingly

Anthropic's CLAUDE.md documentation: "You can tune instructions by adding emphasis (e.g., 'IMPORTANT' or 'YOU MUST') to improve adherence — but use sparingly."

However, Anthropic also warns for newer models (Opus 4.5/4.6):

> "If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger. The fix is to dial back any aggressive language. Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'"

**Application:** Reserve emphasis for 3-5 truly critical rules. If everything is "CRITICAL" and "YOU MUST," nothing is. Use natural language for routine instructions. Emphasis is a budget — spend it wisely.

Sources:

- [Using CLAUDE.md Files (Anthropic Blog)](https://claude.com/blog/using-claude-md-files)
- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### 2.2 "Take a Deep Breath"

The most reliably positive emotional framing in Merkelbach's study (LessWrong, 2025): +2.4% on TruthfulQA, +1.0% on MBPP+. Consistent small improvements across models. The mechanism is likely that it triggers chain-of-thought reasoning patterns.

**Application:** For complex multi-step instructions, prefacing with "Think through this step by step" or similar can help. But the effect is small and mostly relevant for reasoning tasks, not instruction-following.

Sources:

- [Prompt Framing Changes LLM Performance (LessWrong)](https://www.lesswrong.com/posts/RTHdQuGJeBKWHbgyj/prompt-framing-changes-llm-performance-and-safety)

### 2.3 Progressive Disclosure via Skill Files

`@path/to/file` references in CLAUDE.md/AGENTS.md are loaded at startup — they consume instruction budget the same as inlining the content. They help with organization and reusability but do not reduce context size.

True progressive disclosure in Claude Code comes from **skill files** (`skills/*/SKILL.md`), which are only loaded when the skill is triggered. Action-specific rules (commit format, PR template, rebase procedure) belong in skill files so they don't consume instruction budget during unrelated tasks.

**Application:** Avoid `@` includes for size reduction. Use skill files for rules that only matter during specific actions.

Sources:

- [Using CLAUDE.md Files (Anthropic Blog)](https://claude.com/blog/using-claude-md-files)

---

## 3. What Doesn't Work (Debunked or Unreliable)

### 3.1 Threats, Tips, and Emotional Stakes

The Wharton "Prompting Science Report 3" (Meincke, Mollick, Mollick, & Shapiro, 2025) rigorously tested: email shutdown threat, "important to my career," threat to kick a puppy, elaborate "Mom suffers from cancer" scenario, HR report threat, threat to punch, $1,000 tip, and $1 trillion tip.

Tested across 5 models (Gemini 1.5 Flash, Gemini 2.0 Flash, GPT-4o, GPT-4o-mini, o4-mini) on 198 PhD-level questions and 100 engineering questions with 25 trials per condition.

**Result: "Threatening or tipping AI models has no meaningful effect on performance across challenging academic benchmarks."**

Individual questions showed dramatic swings (up to +36% or -35%), but these cancelled out in aggregate. The conclusion: "Practitioners should focus on simple, clear instructions."

**Application:** "This is mission critical" and "millions will die" adds zero compliance. It just wastes tokens.

Sources:

- [Wharton GAIL Report](https://gail.wharton.upenn.edu/research-and-insights/techreport-threaten-or-tip/)
- [arXiv Paper (2508.00614)](https://arxiv.org/abs/2508.00614)

### 3.2 Aggressive ALL CAPS Throughout

Both OpenAI and Anthropic now recommend against this as a default strategy.

- OpenAI: "It's generally not necessary to use all-caps or other incentives like bribes or tips."
- Anthropic: Dial back aggressive language with newer models to prevent overtriggering.

Strategic, selective use of CAPS for 2-3 critical items can work. But when everything is CAPITALIZED and BOLD and CRITICAL, the signal-to-noise ratio collapses.

Sources:

- [OpenAI GPT-4.1 Prompting Guide](https://developers.openai.com/cookbook/examples/gpt4-1_prompting_guide)
- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### 3.3 Generic Personas

"You are an expert software engineer" provides negligible benefit for accuracy tasks on modern models. The Learn Prompting experiment found an "Idiot" persona outperformed a "genius" persona on MMLU with GPT-4-turbo.

Detailed, domain-specific personas can help for open-ended creative tasks, but basic one-line personas show no improvement for instruction-following.

Sources:

- [PromptHub: Role Prompting Analysis](https://www.prompthub.us/blog/role-prompting-does-adding-personas-to-your-prompts-really-make-a-difference)
- [When A Helpful Assistant Is Not Really Helpful (arXiv)](https://arxiv.org/html/2311.10054v2)
- [Learn Prompting Guide](https://learnprompting.org/docs/advanced/zero_shot/role_prompting)

### 3.4 Politeness Optimization

Research is genuinely contradictory. Three major studies reach conflicting conclusions — one favors moderate politeness, one favors rudeness, one finds no significant effect. Effects are small, model-dependent, and language-dependent. Not worth optimizing for.

Sources:

- [Should We Respect LLMs? (ACL 2024)](https://aclanthology.org/2024.sicon-1.2/)
- [Mind Your Tone (arXiv 2510.04950)](https://arxiv.org/abs/2510.04950)
- [Does Tone Change the Answer? (arXiv 2512.12812)](https://arxiv.org/html/2512.12812v1)

---

## 4. The Meta-Finding: Newer Models Converge on Simplicity

Many techniques that showed large effects on older models (GPT-3.5, LLaMA 1/2) show diminished or reversed effects on newer models (GPT-4.1+, Claude 4.5+, Gemini 2.0). Newer models are:

- More robust to tone variation
- More literal in instruction following
- More likely to overtrigger on aggressive prompting
- Less susceptible to emotional manipulation

The trend is clear: **as models improve, the optimal prompting style converges on clear, direct, well-structured natural language.**

The NeurIPS 2025 paper "Emotional Framing as a Control Channel" confirmed this: aligned models remained stable across emotional valence, with tone affecting only stylistic features. Well-aligned models don't need emotional pressure to follow instructions — they just need clear instructions.

Sources:

- [NeurIPS 2025 Paper (OpenReview)](https://openreview.net/forum?id=vSbV01bdvf)

---

## 5. Claude Code Context Loading System

### 5.1 The Memory Hierarchy

Claude Code assembles context from multiple files in a specific priority order. More specific context wins on conflicts. All levels combine — they don't replace each other.

| File/Location | Scope | Shared in Git? | Loaded when |
|---|---|---|---|
| `~/.claude/CLAUDE.md` | Global (all projects) | No | Session start |
| `./CLAUDE.md` (project root) | Project-wide | Yes | Session start |
| `./CLAUDE.local.md` | Project, personal | No (.gitignored) | Session start |
| `./subdir/CLAUDE.md` | Subdirectory-specific | Yes | Session start |
| `.claude/rules/*.md` (no frontmatter) | Project-wide | Yes | Session start |
| `.claude/rules/*.md` (with `paths:`) | Pattern-triggered | Yes | On file read |
| `.claude/agents/*.md` | On-demand subagents | Yes | When invoked |
| `skills/*/SKILL.md` | Action-specific | Yes | When skill triggers |
| `AGENTS.md` | Cross-tool universal | Yes | Session start |

**Critical behavior:** `CLAUDE.md` and rules survive context compaction (`/compact`). After compaction, Claude re-reads them from disk and re-injects them fresh. Conversational instructions are lost. This makes `CLAUDE.md` the only safe place for instructions that must survive long sessions.

### 5.2 The `.claude/rules/` Directory

The primary mechanism for modular rules. Every `.md` file is automatically discovered recursively — no configuration required.

- **Rules without frontmatter** load unconditionally at session start, same priority as `CLAUDE.md`
- **Rules with `paths:` frontmatter** load conditionally when Claude reads files matching the specified globs

```yaml
---
paths:
  - "src/api/**/*.ts"
  - "src/**/*.{ts,tsx}"
---
# API Development Rules
- All API endpoints must include input validation
```

**YAML quoting is mandatory.** Glob patterns starting with `{` or `*` are reserved YAML indicators and fail silently if unquoted. Always quote all patterns.

### 5.3 Known Frontmatter Bugs (as of March 2026)

| Bug | Impact | Workaround |
|---|---|---|
| `paths:` vs `globs:` key discrepancy | Documented `paths:` key doesn't work reliably in all versions; undocumented `globs:` works more reliably | Test both; prefer whichever works in your version |
| Rules trigger on Read only, not Write/Create | File creation conventions are silently ignored | Place creation rules in always-on rules (no frontmatter) |
| User-level rules ignore `paths:` | `~/.claude/rules/` always loads globally regardless of frontmatter | Only use path-scoping in project-level rules |
| Git worktree path resolution | Path filtering bypassed for worktree-relative paths | Use always-on rules as fallback |

### 5.4 Context Architecture Patterns

**Pattern 1: CLAUDE.md with `@import` triggers**
Keep `CLAUDE.md` minimal. Reference detailed specs only when needed via `@path/to/file.md`.

**Pattern 2: Rules directory with domain separation**
```
.claude/rules/
├── always-on.md           ← no frontmatter, loads every session
├── typescript.md          ← paths: "**/*.{ts,tsx}"
├── testing.md             ← paths: "**/*.test.{ts,tsx}"
├── api.md                 ← paths: "src/api/**/*"
└── database.md            ← paths: "src/db/**/*", "prisma/**/*"
```

**Pattern 3: Skill trigger tables**
Maintain a routing table in `CLAUDE.md` that maps keywords to skill files, with skills loading on demand. This keeps main context lean while making specialized knowledge accessible.

**Lazy loading insight:** One community optimization achieved a 54% reduction in initial context tokens while maintaining full tool access, by replacing always-loaded documentation with on-demand skill files.

### 5.5 Context Window Management

- Use `/clear` between distinct tasks to reset accumulated context while preserving `CLAUDE.md`
- Keep context below 60% capacity — attention quality degrades well before hard limits
- Customize compaction behavior: `"When compacting, always preserve the full list of modified files and any test commands"`

Sources:

- [How Claude remembers your project (Official Docs)](https://code.claude.com/docs/en/memory)
- [Best Practices for Claude Code (Official Docs)](https://code.claude.com/docs/en/best-practices)
- [Using CLAUDE.MD files (Anthropic Blog)](https://claude.com/blog/using-claude-md-files)
- [Claude Code Rules Directory (claudefa.st)](https://claudefa.st/blog/guide/mechanics/rules-directory)
- [Claude Code Path-Specific Rules (paddo.dev)](https://paddo.dev/blog/claude-rules-path-specific-native/)
- GitHub Issues: #17204 (paths vs globs), #21858 (user-level scoping), #13905 (YAML quoting), #16299 (global loading), #23478 (read-only trigger), #24112 (create files), #23569 (worktrees)

---

## 6. Optimal Pattern for Context Files

Based on the combined evidence, the optimal structure for agent context instructions:

### Structure

```markdown
# Section Header

Brief rationale for why this section exists (1 line).

- Rule as positive directive ("Use X when Y")
- Rule with inline rationale ("Use X — because Y causes Z")
- Exact command/example in code block when applicable
```

### Tone

- Direct, natural language — like talking to a competent colleague
- No emotional manipulation, threats, or stakes language
- Imperative mood ("Use," "Run," "Write") — not conditional ("You should consider...")
- Brief rationale after rules that aren't self-evident

### Emphasis Budget

- Reserve CAPS/bold/IMPORTANT for a maximum of 3-5 rules across the entire file
- Everything else in natural language
- If a rule needs aggressive emphasis to be followed, consider a mechanical guardrail instead

### Organization

- Universal rules in the central file (AGENTS.md)
- Domain/action-specific rules in skill files (loaded on trigger)
- Action-specific rules in skill files (true progressive disclosure — loaded only on trigger)
- Critical rules repeated at both central file and point of use
- Mechanical enforcement (hooks, deny rules, linters) wherever possible

### Hierarchy of Enforcement Reliability

1. **Mechanical guardrails** (hooks, deny rules, linters) — most reliable
2. **In-context rules at point of use** (skill files loaded during the relevant action)
3. **Central context rules** (AGENTS.md, loaded at all times)
4. **Emphasis and formatting** (CAPS, bold) — least reliable, diminishing returns

---

## 7. Complete Source Index

### Academic Papers

- [EmotionPrompt (arXiv 2307.11760)](https://arxiv.org/abs/2307.11760)
- [Should We Respect LLMs? (ACL 2024)](https://aclanthology.org/2024.sicon-1.2/)
- [Mind Your Tone (arXiv 2510.04950)](https://arxiv.org/abs/2510.04950)
- [Does Tone Change the Answer? (arXiv 2512.12812)](https://arxiv.org/html/2512.12812v1)
- [Wharton Tipping/Threats Study (arXiv 2508.00614)](https://arxiv.org/abs/2508.00614)
- [Prompt Repetition (arXiv 2512.14982)](https://arxiv.org/abs/2512.14982)
- [Prompt Formatting Impact (arXiv 2411.10541)](https://arxiv.org/html/2411.10541v1)
- [DETAIL Matters (arXiv 2512.02246)](https://arxiv.org/abs/2512.02246)
- [26 Principles (arXiv 2312.16171)](https://arxiv.org/html/2312.16171v2)
- [When A Helpful Assistant Is Not Really Helpful (arXiv 2311.10054)](https://arxiv.org/html/2311.10054v2)
- [NeurIPS 2025: Emotional Framing (OpenReview)](https://openreview.net/forum?id=vSbV01bdvf)
- [Prompt Framing LessWrong Study](https://www.lesswrong.com/posts/RTHdQuGJeBKWHbgyj/prompt-framing-changes-llm-performance-and-safety)
- [Framing Effects (arXiv 2502.17091)](https://arxiv.org/abs/2502.17091)

### Official Documentation

- [Anthropic Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Using CLAUDE.md Files (Anthropic Blog)](https://claude.com/blog/using-claude-md-files)
- [Anthropic XML Tags Guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags)
- [OpenAI GPT-4.1 Prompting Guide](https://developers.openai.com/cookbook/examples/gpt4-1_prompting_guide)

### Practitioner Sources

- [Simon Willison: Context Engineering](https://simonwillison.net/2025/jun/27/context-engineering/)
- [Simon Willison: Claude 4 System Prompt Analysis](https://simonw.substack.com/p/highlights-from-the-claude-4-system)
- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Builder.io: CLAUDE.md Guide](https://www.builder.io/blog/claude-md-guide)
- [Olickel: Everything I'll Forget About Prompting LLMs](https://olickel.com/everything-i-know-about-prompting-llms)
- [Wharton GAIL Report](https://gail.wharton.upenn.edu/research-and-insights/techreport-threaten-or-tip/)
- [PromptHub: Role Prompting Analysis](https://www.prompthub.us/blog/role-prompting-does-adding-personas-to-your-prompts-really-make-a-difference)
- [The Pink Elephant Problem](https://eval.16x.engineer/blog/the-pink-elephant-negative-instructions-llms-effectiveness-analysis)
