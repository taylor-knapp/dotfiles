---
name: anki
description: Work with Anki via the anki MCP server — add, find, review, and sync cards. Use when the user wants to create flashcards, study, or manage Anki decks.
disable-model-invocation: true
---

# Anki

Manage Anki flashcards through the `anki` MCP server.

## MCP mechanics

All tools are prefixed `mcp__anki__` and are **deferred** — their schemas are not loaded.
Before calling any tool, load its schema:

```
ToolSearch  query: "select:mcp__anki__list_decks,mcp__anki__add_notes"
```

Load multiple at once by comma-joining names. Calling a tool before its schema is
loaded fails with `InputValidationError`.

## Core workflow tools

### Inspect (always do this first)

- `list_decks` — list decks. Add `include_stats: true` for new/learn/due counts.
- `model_names` — list note types.
- `model_field_names` — exact field names for a model. **Always inspect deck + model
  fields before adding** — fields are keyed by exact name.

### Find / read

- `find_notes` — Anki query syntax. Returns note IDs. Examples:
  - `deck:Name`, `tag:x`, `is:due`, `note:Cloze`, `added:1`
- `notes_info` — full field + tag data for note IDs. Use `include_fields` /
  `exclude_fields` to trim large payloads.

### Add

- `add_note` — single note.
- `add_notes` — batch. **Same deck + model per call.** Atomic undo, partial-success.
  Pass a shared `tags` array + per-note `fields` keyed by exact field name.

### Edit / delete

- `update_note_fields`, `update_notes` (batch), `delete_notes`, `tag_management`.

### Review

- `get_due_cards`, `present_card`, `rate_card`, `get_card_memory_state`.
- FSRS: `get_fsrs_params`, `optimize_fsrs_params`.

### GUI

- `gui_add_cards`, `gui_browse`, `gui_edit_note`, `gui_current_card`.

### Sync

- `sync` — call at the **start of a review session** and **after a batch of edits**.
  Async — returns `status: started`.

## Rules / gotchas

- **Only create cards the user explicitly asked for.** Show proposed cards in a table
  and get approval **before** calling `add_notes`.
- **Match existing deck conventions.** Inspect a few existing notes with `notes_info`
  first — copy field style, tag scheme, HTML formatting.
- **Fields accept HTML** — `<b>`, `<i>`, `<br>`.
- **Cloze syntax** — `{{c1::hidden}}`. Multiple cloze groups `{{c1::}}` `{{c2::}}` on one
  note create staged deletions (separate cards).
- **Cloze preference — always use `{{c1::}}` for every deletion on a note.** The user
  wants exactly **one card per cloze note**, no matter how many blanks. Reuse `c1` for
  all deletions so they hide/reveal together as a single card. Never use `c2`, `c3`, …
  to stage separate cards unless the user explicitly asks.
- **Don't edit a note while the user has it open in the Anki browser** — lock conflict.
- **Use UTF-8** for accented characters.
