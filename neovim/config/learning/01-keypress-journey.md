# Module 1: The Keypress Journey

**Goal:** build a mental model of the five layers a keypress crosses. When a key
"doesn't work," the useful question is never "why is Neovim broken?" — it's
"which layer ate it?"

## The layers

```
  You press ⌘←
        │
  ┌─────▼──────────────────────────────────────┐
  │ 1. macOS / WindowServer                    │  system hotkeys win first
  │    Mission Control, Spotlight, menu bar    │
  └─────┬──────────────────────────────────────┘
        │ (survivors continue)
  ┌─────▼──────────────────────────────────────┐
  │ 2. iTerm2 application                      │  its own Key Bindings
  │    - modifier remapping (Cmd→Super/Hyper)  │
  │    - Key Bindings table (Send Hex Code…)   │
  └─────┬──────────────────────────────────────┘
        │ BYTES go down the pseudo-terminal
        │ e.g. 1b 5b 31 3b 39 44
  ┌─────▼──────────────────────────────────────┐
  │ 3. (tmux, if present)                      │  re-encodes or strips
  │    NOT in your path — you run nvim direct  │
  └─────┬──────────────────────────────────────┘
        │
  ┌─────▼──────────────────────────────────────┐
  │ 4. Neovim's terminal input parser          │  bytes → keycode
  │    "1b 5b 31 3b 39 44" → <D-Left>          │
  └─────┬──────────────────────────────────────┘
        │
  ┌─────▼──────────────────────────────────────┐
  │ 5. Neovim's keymap layer                   │  keycode → action
  │    vim.keymap.set('n', '<D-Left>', …)      │
  └────────────────────────────────────────────┘
```

The crucial thing to internalize: **layers 1-3 speak in bytes, not keys.** Your
keyboard's notion of "Cmd + Left Arrow" ceases to exist the moment iTerm2 writes
to the pseudo-terminal. All Neovim ever receives is a stream of bytes. It has to
*reconstruct* the idea of "Cmd+Left" from them.

## Where each layer can eat a key

**Layer 1 — macOS.** Some combinations are claimed system-wide by WindowServer
before any application sees them. `⌃←`/`⌃→` are the classic example (Mission
Control's "Move left/right a space"). If macOS claims a key, no application-level
configuration can rescue it — you must disable the system shortcut in System
Settings → Keyboard → Keyboard Shortcuts.

Menu-bar equivalents are a softer version of the same thing: `⌘A` is Edit → Select
All in most apps.

**Layer 2 — iTerm2.** Two separate mechanisms, easy to confuse:

- *Modifier remapping* (Profiles → Keys): "make the Command key report as Super."
  This changes how modifiers are **encoded** into bytes.
- *Key Bindings* (Settings → Keys → Key Bindings, and per-profile): "when ⌘← is
  pressed, send these exact bytes instead." This **replaces** encoding entirely.

Key Bindings win. If a binding exists for a key, the modifier remapping is
irrelevant for that key — iTerm2 just sends the literal bytes you specified. This
was the entire explanation for your Ctrl/Cmd arrow mystery.

**Layer 3 — tmux.** Not in your path (your Neovim reports `TERM_PROGRAM=iTerm.app`,
which means no tmux between). Mentioned only because it's a common culprit and
because I briefly misdiagnosed it: the tmux I found was my own sandbox's, not
yours. If you ever adopt tmux, know that it does **not** speak the kitty keyboard
protocol — it implements the older xterm `modifyOtherKeys`/CSI-u scheme and needs
`extended-keys on` plus `extended-keys-format csi-u` to pass modified keys through
at all.

**Layer 4 — Neovim's parser.** Turns bytes into keycodes. This layer has exactly
one gap that matters to you: it recognizes Shift, Alt, Ctrl, Super, and Meta, but
**silently discards Hyper**. Module 2 covers this.

**Layer 5 — keymaps.** The part you write Lua for. Also where which-key,
buffer-local plugin maps, and shadowing live. Diagnose with `:verbose nmap <lhs>`.

## The diagnostic move: split the chain in half

The single most useful tool is a probe that shows you exactly what **layer 4**
produced. If a keycode appears there, layers 1-3 are innocent and the problem is
your keymaps. If nothing appears, layers 1-3 ate it and your Lua is irrelevant.

**You already have this tool.** `lua/custom/keylog.lua` provides it:

```vim
:KeyLog       " toggle on, type keys, toggle off
:messages     " review the full log
```

It prints two views per keypress — the readable keycode (`<D-Left>`) via
`vim.fn.keytrans`, and the literal bytes in `\xNN` hex. The hex view is what makes
it better than an ad-hoc snippet: you see the actual escape sequence, so you can
compare it byte-for-byte against Module 2's tables.

It also logs `typed` rather than `key`. `vim.on_key` hands the callback both: `key`
is post-mapping, `typed` is what you physically entered. For "what did my terminal
send?" you want `typed` — otherwise your own keymaps distort the answer.

If you want a throwaway version without the hex view:

```vim
:lua vim.on_key(function(k) vim.notify(vim.fn.keytrans(k)) end)
:lua vim.on_key(nil)
```

**Concepts introduced:** pseudo-terminal, byte stream vs keycodes, `vim.on_key`,
`vim.fn.keytrans`, layer isolation as a debugging strategy.

**Next:** [Module 2 — Key Encoding](02-key-encoding.md), which explains what those
bytes actually look like and why Hyper dies.
