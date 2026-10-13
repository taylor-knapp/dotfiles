---
name: français
description: Create and review French-learning Anki cards. Use when the user wants French flashcards, grammar drills, or to study French.
disable-model-invocation: true
---

# Français

Build and review French-learning Anki cards.

**For all Anki MCP usage (tool names, ToolSearch loading, add/find/review/sync), follow
the [anki skill](../anki/SKILL.md).** This skill only adds French-specific knowledge.

## Decks

- Default: `Français` (root). Put new grammar cards here unless the user names a subdeck.
- Existing subdeck: `Français::Se présenter`.

## Note types

- **Cloze** — fields `Text`, `Back Extra`. Primary type for fill-in grammar drills.
  `Back Extra` holds the rule explanation (write it in French where reasonable, HTML allowed).
- **Français Q&R** — fields `Question`, `Réponse`, `Indice`. **Dialogue only.** Use *only*
  for conversational exchanges (e.g. "D'où viens-tu ?") so both sides of the conversation
  get practiced. Creates two cards (question→réponse and réponse→question).
- **Basic** — fields `Front`, `Back`. Single question→answer card. **Use for all grammar
  questions** — anything that isn't a dialogue exchange.
- **Français Conjugaison** — fields `Concept`, `Explanation`, `Examples`.

## Tag scheme (kebab-case)

Existing: `se-presenter`, `prepositions`, `negation`, `partitif`. Reuse and extend in
this style.

## Card-design conventions

- **Cloze cards** are full French sentences with the target hidden:
  - `Text`: `J'habite {{c1::en}} France.`
  - `Back Extra`: `en + feminine country`
- **Grammar rules** — make several concrete example cards covering each
  scenario/exception **plus** one summary card stating the rule. Show the original form
  in `Back Extra` like `(← des légumes)`.
- **Cover exceptions explicitly.** E.g. negation: `être` keeps the full article;
  contrast/specific keeps the article.

## Workflow

1. Propose cards in a table.
2. Get user approval.
3. `add_notes`, batched by deck + model.
4. `sync`.
