---
name: note
description: Add an entry to today's daily note. Use when the user wants to capture learnings, document setup, or jot something down.
disable-model-invocation: true
---

# Daily Note

Append an entry to today's daily note at `~/code/notes/notes/daily/YYYY-MM-DD.md`.

## Instructions

1. Determine today's date
2. Read the daily note file if it exists; if not, create it
3. File format — frontmatter + sections:

```markdown
created: YYYY-MM-DDTHH:MM:SS-05:00
type: note

---

# Topic Heading

- thing I learned or set up
- another thing with [links](https://example.com) to resources
  - sub-details, keybindings, commands, etc.

---

### Deeper Writeup (optional)

Longer-form notes on something worth documenting in detail.
```

4. Append the new entry under a heading, separated by `---` from prior entries
5. Good candidates: tool/plugin setup, gotchas/workarounds, architecture decisions, new keybindings/workflows, doc links

## Session-End Prompt

At session end where knowledge was gained: prompt "Want to add today's learnings to your daily note?" and append if confirmed.
