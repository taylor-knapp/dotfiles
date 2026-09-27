# Module 2: Key Encoding — Legacy vs the Kitty Protocol

**Goal:** understand the actual bytes, so that "Cmd+Left does nothing" becomes a
question you can answer by reading a hex dump.

## The legacy problem

Terminals were standardized when keyboards had far fewer keys. The original ASCII
scheme could express Ctrl+letter (by zeroing the top bits — `Ctrl+A` = byte
`0x01`) and not much else. There is no room in that scheme for Cmd, for
Ctrl+Shift+letter, or for distinguishing `Ctrl+I` from `Tab`.

Two extensions grew on top:

**Legacy CSI with a modifier parameter** — used for *functional* keys (arrows,
Home/End, F-keys):

```
ESC [ 1 ; <mods> D          ← Left arrow with modifiers
 1b  5b 31 3b   ..    44
```

**The kitty keyboard protocol / CSI-u** — used for *text* keys that can't be
legacy-encoded:

```
ESC [ <unicode> ; <mods> u  ← a letter with modifiers
 1b  5b   ..     3b   ..  75
```

So `Cmd+a` and `Cmd+Left` travel by **two completely different encodings**. This
is why one of them can work while the other doesn't — a fact that confused this
whole debugging session until we tested them separately.

## The modifier bitmask

Both forms encode modifiers as a single number. It's a **bitmask plus one**:

| bit | value | modifier |
|-----|-------|----------|
| 0 | 1 | Shift |
| 1 | 2 | Alt / Option |
| 2 | 4 | Ctrl |
| 3 | 8 | **Super** (Cmd) |
| 4 | 16 | **Hyper** |
| 5 | 32 | **Meta** |
| 6 | 64 | Caps Lock |
| 7 | 128 | Num Lock |

The encoded value is `1 + sum of active bits`. So:

- Shift alone → `1 + 1` = **2**
- Ctrl alone → `1 + 4` = **5**
- Super alone → `1 + 8` = **9**
- Hyper alone → `1 + 16` = **17**
- Super+Shift → `1 + 8 + 1` = **10**

Once you know this, you can read and write these sequences by hand. `ESC [ 1;9 D`
is unambiguously "Super + Left Arrow."

## What Neovim actually does with them

Every row below was produced by feeding exact bytes to a headless Neovim and
reading back what its parser produced.

**Text keys (CSI-u form):** **[probe]**

| bytes sent | meaning | Neovim decoded |
|---|---|---|
| `ESC [ 97;5 u` | Ctrl+a | `<C-A>` |
| `ESC [ 97;9 u` | Super+a | `<D-a>` |
| `ESC [ 97;10 u` | Super+Shift+a | `<D-A>` |
| `ESC [ 97;33 u` | Meta+a | `<T-a>` |
| `ESC [ 97;3 u` | Alt+a | `<Esc>` then `a` |
| `ESC [ 97;17 u` | **Hyper+a** | **`a`** ← modifier gone |

u is the final byte that marks "this is a text key in CSI-u protocol."

CSI-u format: ESC [ <codepoint>;<modifier> u

The u at the end tells nvim "decode the codepoint as a character." Other keys use different final bytes:
- D = Left Arrow
- A = Up Arrow
- F = End key
- etc.

**Functional keys (legacy CSI form):** **[probe]**

| bytes sent | meaning | Neovim decoded |
|---|---|---|
| `ESC [ 1;2 D` | Shift+Left | `<S-Left>` |
| `ESC [ 1;3 D` | Alt+Left | `<Esc>` then `<Left>` |
| `ESC [ 1;5 D` | Ctrl+Left | `<C-Left>` |
| `ESC [ 1;9 D` | Super+Left | `<D-Left>` |

Final byte selects the arrow: `D`=Left, `C`=Right, `A`=Up, `B`=Down.

## Three lessons from those tables

**1. Neovim's prefixes are not what you'd guess.**

| modifier | Neovim prefix |
|---|---|
| Shift | `<S-` |
| Alt / Option | `<M-` (for "Meta", historically) |
| Ctrl | `<C-` |
| Super / Cmd | `<D-` (for "Diamond"/Command) |
| Meta (true meta) | `<T-` |
| Hyper | *none — unsupported* |

Note the trap: Option maps to `<M->`, but *true* Meta maps to `<T->`. The naming
is a historical accident.

**2. Hyper is unusable with Neovim.** Bit 16 isn't recognized, so the parser
strips it and delivers the bare key. `Hyper+a` arrives as a plain `a`.

This is the root cause of your original symptom. You set Cmd to send Hyper, then
pressed `Ctrl-V` in insert mode expecting to see something logged. `Ctrl-V`
inserts the *decoded* keypress — and the decoded keypress was literally the
character `a`. It looked like "nothing happened" because a plain letter appeared
instead of an escape sequence. Nothing was broken; the modifier had already
evaporated one layer up.

**Use Super, never Hyper.** Meta (`<T->`) technically works but is unusual and
poorly supported by plugins.

**3. Alt is special-cased as ESC-prefix.** `Alt+Left` decodes to two keys:
`<Esc>` followed by `<Left>`. This is the ancient "meta sends escape" convention.
Neovim reassembles it into `<M-Left>` at the keymap layer, which is why your
`<M-Left>` buffer-navigation mapping works.

## How Neovim negotiates the kitty protocol

Neovim doesn't assume the terminal supports CSI-u. At startup it asks. Captured
from a real Neovim launch: **[probe]**

```
ESC [ ? u        ← "what kitty flags are you currently using?"
ESC [ > 4 ; 0 m  ← "turn off the older modifyOtherKeys scheme"
```

If the terminal replies `ESC [ ? <flags> u`, Neovim then pushes its own request:

```
ESC [ > 1 u      ← "enable flag 1: disambiguate escape codes"
```

Flag 1 is the minimal level. Under it, keys that *can* be legacy-encoded still
are; only keys that can't (like Super+letter) get the CSI-u treatment. That is
sufficient for everything you need.

**So: yes, Neovim requests the kitty protocol.** That question is settled. And
iTerm2 3.5+ does support it — an earlier note in this repo's `CLAUDE.md` claiming
otherwise was wrong and has been corrected.

## A caveat about the probe results

One probe result gives away a limitation of the test rig: `ESC [ 105;5 u`
(Ctrl+i) decoded as `<Tab>`, not `<C-I>`. That's because the headless test Neovim
never completed kitty negotiation — no terminal was there to answer its query —
so it fell back to legacy interpretation.

The practical implication: **[probe]** results prove Neovim's parser *accepts*
those bytes. They do not prove iTerm2 *sends* them. Always confirm end to end with
`vim.on_key` in the real terminal.

**Concepts introduced:** CSI sequences, CSI-u, the kitty keyboard protocol,
modifier bitmask, protocol negotiation, Neovim modifier prefixes, ESC-prefix Alt.

**Next:** [Module 3 — Shared Keycodes](03-shared-keycodes.md).
