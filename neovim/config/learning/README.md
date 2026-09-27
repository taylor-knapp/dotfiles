# Learning: Keyboard Input, macOS, iTerm2, and Neovim

Written 2026-08-06 after a debugging session that started with "why doesn't Cmd+key
show up in Neovim?" and ended up touching every layer between your keyboard and
your editor.

Read the modules in order. Each is self-contained and takes 5-15 minutes.

| # | Module | What it answers |
|---|--------|-----------------|
| 1 | [The Keypress Journey](01-keypress-journey.md) | What happens between pressing a key and Neovim reacting |
| 2 | [Key Encoding: Legacy vs Kitty](02-key-encoding.md) | Why some modifiers work and others vanish |
| 3 | [Shared Keycodes](03-shared-keycodes.md) | Why `<C-i>` and `<Tab>` fight each other |
| 4 | [Your Current Setup](04-your-current-setup.md) | What's actually configured, in both halves |
| 5 | [Recommendations & Open Questions](05-recommendations.md) | What to change, what's still unknown |

## Tools

**`:KeyLog`** — already in this config (`lua/custom/keylog.lua`). Toggle it, press
keys, read `:messages`. Shows both the decoded keycode and the raw `\xNN` bytes.
This is the primary tool; reach for it first.

**[`probe.sh`](probe.sh)** + **[`probe.lua`](probe.lua)** — written during this
session. Feeds *synthetic* bytes to Neovim's parser, answering "what would Neovim
do if it received these exact bytes?" Useful when your terminal can't produce the
sequence you want to test. Module 5 explains usage.

Together they turn "this key doesn't work" from guesswork into a two-minute
experiment.

## How facts are labeled

Some findings came from feeding synthetic bytes to a headless Neovim; others came
from pressing real keys in the real terminal. These are **not** the same kind of
evidence, and mixing them up is how you end up confidently wrong. Every table in
these modules tags its rows:

- **[probe]** — Bytes were fed directly to Neovim's parser. Proves *Neovim accepts
  these bytes*. Says nothing about whether iTerm2 ever sends them.
- **[real]** — A key was physically pressed in iTerm2 with Neovim running. Proves
  the whole chain works end to end.
- **[?]** — Inferred, not tested. Treat as a hypothesis.

## The one-sentence summary

Neovim turned out to be almost blameless: it correctly decodes Super, Meta, and
modified arrows. Nearly every "broken" key was broken somewhere upstream — in
iTerm2's own key bindings, or in the one genuine Neovim gap (Hyper).
