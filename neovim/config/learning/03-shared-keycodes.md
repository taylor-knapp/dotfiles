# Module 3: Shared Keycodes

**Goal:** understand why `<C-i>` and `<Tab>` interfere, why the kitty protocol
only half-solves it, and what the fix actually does.

his module revises a note already in this repo's `CLAUDE.md` — the mechanism
there was right, but it credited Ghostty for something that on your machine comes
from an iTerm2 setting.

## The collision

Three Ctrl-chords historically transmit the *same single byte* as another key:

| pair | shared byte |
|---|---|
| `<C-i>` / `<Tab>` | `0x09` |
| `<C-m>` / `<CR>` | `0x0d` |
| `<C-[>` / `<Esc>` | `0x1b` |

Under legacy encoding the terminal genuinely cannot tell them apart. One byte, two
possible intentions.

## What the kitty protocol fixes

With CSI-u available, the terminal can send a *distinct* sequence for `Ctrl+i`:

```
ESC [ 105;5 u      ← 105 is Unicode 'i', 5 is Ctrl
```

while plain `Tab` continues to send `0x09`. Now they're distinguishable.

## What the kitty protocol does NOT fix

Here's the subtle part, and it's the part worth actually remembering.

Making the keys *distinguishable at the wire level* does not automatically restore
their *builtin behaviors* inside Neovim. Neovim's builtin actions are attached to
the shared keycode. If you map one member of a pair, that map captures the shared
base behavior, and the other member's builtin gets swallowed.

Concretely, in this repo: `init.lua:152` maps `<Tab>` → `>>` (indent line). That
map shadows the builtin sitting on the shared code, so pressing `<C-i>` no longer
runs its builtin jumplist-forward — *even when* the protocol makes the two keys
distinct.

## The fix

Explicitly map the other member back to its builtin:

```lua
vim.keymap.set('n', '<C-i>', '<C-i>', { noremap = true, desc = 'Jumplist forward' })
```

The `noremap = true` is load-bearing. It makes the right-hand side resolve to the
**builtin** `<C-i>` (jumplist forward) rather than recursively re-entering your own
mapping. Without it you'd get an infinite loop.

This lives at `init.lua:161` and is correct. Only its comment was wrong.

**General rule:** whenever you map one member of a shared-keycode pair, pair it
with an explicit builtin map on the other member if you want both behaviors.

## Why it works on *your* machine specifically

The existing comment says Ghostty's kitty protocol makes them distinct. You don't
use Ghostty. On your setup, `<C-i>` is distinct because of an **iTerm2 Key
Binding** you created:

| shortcut | action | payload |
|---|---|---|
| `^i` | Send escape sequence | `^[[105;5u` |

That binding hardcodes exactly the CSI-u sequence for Ctrl+i and sends it
unconditionally — no negotiation required. It's a clever workaround, and it's the
same technique Module 5 recommends for the arrow keys.

But it means **the behavior depends on a setting that isn't in this git repo.** If
you reinstall iTerm2, restore from a different backup, or switch machines, `<C-i>`
silently reverts to being indistinguishable from `<Tab>`, and the mapping at
`init.lua:161` quietly stops doing anything useful. Module 4 develops this theme —
your keyboard config genuinely lives in two places.

**Concepts introduced:** shared keycodes, keymap shadowing, `noremap` and
recursion, config split across version-controlled and non-version-controlled
halves.

**Next:** [Module 4 — Your Current Setup](04-your-current-setup.md).
