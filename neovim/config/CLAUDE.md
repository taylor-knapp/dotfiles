# Neovim Config — Agent Instructions

## Learning Mode

The user is learning how Neovim works and wants to make it their daily driver for code and text editing. For every change you make, explain in plain language: what the change does, why it works that way, and which Neovim/Lua concepts are involved (e.g. autocmds, options, keymaps, plugins). Favor teaching over terseness when describing actions.

- **Always** update `CHANGELOG.md` when making changes (date-grouped entries).
- Consider whether `README.md` needs updating — update it if the change affects structure, keymaps, or how a plugin works; skip it for minor tweaks.
- **Always** create a git commit after making changes. Follow commitlint conventions (use the `/commit` skill). Do not wait for approval — commit immediately. Skip the todo list approval step and execute the commit directly.

## Keyboard Setup

ZSA Moonlander split keyboard, Colemak layout. This affects all keymap suggestions:

- **Home row modifiers** (hold to activate): `A`=Left Shift, `R`=Left Ctrl, `S`=Left Option, `T`=Left Cmd on left hand; `N`=Right Cmd, `E`=Right Option, `I`=Right Ctrl, `O`=Right Shift on right hand
- **Layer keys** (thumb cluster): tap once to activate layer, hold to hold layer
- **Right space key**: tap=Space, hold=layer activation
- **Layers**: Base (0), Symbols (1), Numbers (2)

Ergonomic assumptions from standard keyboards don't apply here. Don't suggest keymaps based on physical key adjacency or "easier to reach" reasoning — the user's layout is custom and optimized already. When suggesting keymaps, prefer sequences the user can evaluate based on their layer/modifier setup, not standard QWERTY muscle memory.

## Terminal

Terminal: **iTerm2** (3.5+), which *does* support the kitty keyboard protocol. nvim queries for it at startup (`CSI ? u`) and enables flag 1 if the terminal replies. No tmux in the path.

When a modifier combo "doesn't reach Neovim," check causes in this order:

1. **An iTerm2 Key Binding is intercepting it.** Settings → Keys → Key Bindings, plus the profile's Keys tab. A binding replaces encoding entirely — the modifier remap is ignored for that key. This is the most common cause here; several arrow combos are already bound.
2. **nvim silently drops Hyper.** The parser handles Shift/Alt/Ctrl/Super/Meta but strips modifier bit 16, delivering the bare key. `<Hyper-*>` keymaps accept without error and can never fire. Use Super (`<D-`), never Hyper.
3. **macOS claims it system-wide** (e.g. `⌃←` = Mission Control "Move left a space"). No app-level config can override this; disable it in System Settings.

nvim modifier prefixes: Shift `<S-`, Option `<M-`, Ctrl `<C-`, Cmd/Super `<D-`, true Meta `<T-`.

Diagnose with `:KeyLog` (`lua/custom/keylog.lua`) — toggle, press keys, read `:messages`. Shows the decoded keycode *and* raw `\xNN` bytes, and logs `typed` (pre-mapping) so your own keymaps don't distort the reading. It fires after the terminal parser but before keymaps, so a keycode appearing there means the terminal delivered it and the problem is in your mappings. To test bytes your terminal can't produce, use `learning/probe.sh`.

**Config is split across two places.** `<M-Left>`/`<M-Right>` (`init.lua:101-102`) and `<C-i>` (`init.lua:161`) only work because of iTerm2 Key Bindings that are not in this repo. Before concluding a keymap is broken, check the iTerm2 side. See `learning/04-your-current-setup.md` for the full inventory.

Deeper writeup and a byte-level probe rig: `learning/`.

## How which-key Interacts With Keystrokes

When explaining keymap behavior, be precise about which-key's role — don't hand-wave that it "swallows" keys.

- **which-key registers *triggers* on prefix keys** (e.g. `]`, `<leader>`, `g`). Pressing a trigger key opens the popup and which-key waits for the rest of the sequence, then **forwards the completed sequence to the real mapping**. It does **not** consume or replace your mapping — the mapping still runs normally. So which-key being on a prefix is *not*, by itself, a reason a mapping fails.
- **The failure mode to watch for is replayed keys, not the initial press.** An `<expr>` mapping that `return`s a key string (e.g. `return ']c'`) feeds those keys back into the input stream. *Those replayed keys* hit triggers again (which-key, other mappings) and may not reach the built-in motion. The initial keypress was forwarded fine; the replay is what breaks.
- **`<Ignore>` ends the keypress** — nothing is replayed, so which-key/other triggers can't re-capture anything. Pattern: do the real action from a `vim.schedule(...)` callback and `return '<Ignore>'`.
- **`normal!` (with the `!`) bypasses all mappings**, including which-key triggers and buffer-local plugin mappings. Use `vim.cmd('normal! ]c')` to fire a *built-in* motion immune to remapping. This is why a direct-call keymap can work where a string-replay keymap silently fails.
- Diagnose with `:verbose nmap <lhs>` — it shows buffer-local mappings, which-key triggers, and where each was set. Check this before claiming a key is "unmapped" or "swallowed."

## Shared Keycodes (`<C-i>`/`<Tab>`, `<C-m>`/`<CR>`, `<C-[>`/`<Esc>`)

Some Ctrl-chords historically send the *same byte* as another key, so the terminal can't tell them apart: `<C-i>`=`<Tab>` (`0x09`), `<C-m>`=`<CR>` (`0x0d`), `<C-[>`=`<Esc>` (`0x1b`). The **kitty keyboard protocol** (Ghostty enables it by default; nvim 0.10+ negotiates it) sends a richer escape sequence that *does* distinguish each pair — you can confirm by mapping one side (e.g. `<C-i>`) and seeing it fire without triggering the other.

**But distinct-at-the-protocol-level does not save the builtin.** If you set a custom keymap on one member of a pair, that map still captures the shared base behavior, so the *other* member's **builtin** action gets swallowed. Concrete case in this repo: `<Tab>`→`>>` (`init.lua`) meant pressing `<C-i>` no longer ran its builtin jumplist-forward — even though kitty makes `<C-i>` and `<Tab>` distinct keys. The builtin lives on the shared code, and the `<Tab>` map shadows it.

**Fix: explicitly remap the other member back to its builtin.** `vim.keymap.set('n', '<C-i>', '<C-i>', { noremap = true })` — `noremap` makes the RHS resolve to the builtin (jumplist-forward) instead of looping. Same pattern restores `<CR>` if you map `<C-m>`, or `<Esc>` if you map `<C-[>`. Always pair a custom map on one member with an explicit builtin map on the other if you want both behaviors.

## Telescope Multi-Select & Bulk Edit

In telescope picker (find files, grep results):
- **Tab** — multi-select files
- **Ctrl-Q** — send selected files to quickfix list
- Then use `:cfdo s/pattern/replacement/g | w` to substitute and auto-save across all selected files
  - The `| w` pipes the write command, so each file is saved after the substitution
