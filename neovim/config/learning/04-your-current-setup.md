# Module 4: Your Current Setup

**Goal:** an honest inventory of what's configured, in both halves, and which
parts are actually working.

## The central insight: your keyboard config lives in two places

```
  ~/.config/nvim/          iTerm2 Settings
  (git, reviewed)          (a plist, not backed up, not reviewed)
        │                        │
        └────────┬───────────────┘
                 │
          both required for
       your keymaps to function
```

Several of your Neovim keymaps only work because of an iTerm2 setting, and nothing
in the repo records that dependency. This is the highest-value thing to understand
from the whole session — not any individual key.

## Half 1: iTerm2 Key Bindings

From the settings screenshot. **[real]** — these are live; the `⌥←` row is proven
live because it produced the `<M-Left>` you observed.

| shortcut | action shown | payload | reaches Neovim as |
|---|---|---|---|
| `^i` | Send escape seq | `^[[105;5u` | `<C-I>` (distinct from Tab) |
| `⌘⌫` | Send Hex Codes | `0x18 0x7f` | readline delete-line |
| `^←` | Send Hex Codes | `0x01` | `<C-A>` **[probe]** |
| `⌥←` | Send escape seq | `^[[1;3D` | `<Esc>` `<Left>` → reassembled to `<M-Left>` **[real]** |
| `^→` | Send Hex Codes | `0x05` | `<C-E>` **[probe]** |
| `⌥→` | Send escape seq | `^[[1;3C` | `<Esc>` `<Right>` → reassembled to `<M-Right>` **[real]** |
| `⌥Del→` | Send escape seq | `^[ d` | readline delete-word |
| `⌘Del→` | Send Hex Codes | `0x0b` | readline kill-line |


## Half 2: Neovim keymaps

### Working

| keymap | location | why it works |
|---|---|---|
| `<M-Left>` → `bprev` | `init.lua:101` | iTerm2 `⌥←` binding sends `^[[1;3D` **[real]** |
| `<M-Right>` → `bnext` | `init.lua:102` | iTerm2 `⌥→` binding sends `^[[1;3C` **[real]** |
| `<C-i>` → jumplist fwd | `init.lua:161` | iTerm2 `^i` binding sends `^[[105;5u` |
| `<C-h/j/k/l>` → window nav | `init.lua:90-93` | plain Ctrl+letter, always worked |
| `<Tab>` → `>>` | `init.lua:152` | plain byte `0x09` |

All three of the first entries depend on iTerm2 settings that aren't in this repo.

### Broken — Hyper window navigation

```lua
-- init.lua:94-97
vim.keymap.set('n', '<Hyper-Left>',  '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<Hyper-Down>',  '<C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('n', '<Hyper-Up>',    '<C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('n', '<Hyper-Right>', '<C-w>l', { desc = 'Move to right window' })
```

**These can never fire.** Neovim has no Hyper keycode (Module 2): bit 16 is
stripped by the parser before the keymap layer is reached. Neovim accepts
`<Hyper-Left>` as a *keymap name* without complaint — `vim.keymap.set` doesn't
validate that a keycode is reachable — so there's no error, just silence.

They're harmless but dead. They also explain why you reached for the Hyper setting
in iTerm2 in the first place.

Good news: `<C-h/j/k/l>` at `init.lua:90-93` already provides the same window
navigation, so nothing is actually lost.

### Untested — Super maps in the LSP plugin

```lua
-- lua/plugins/lsp.lua:108
vim.keymap.set('n', '<D-b>', open_refs, …)
-- lua/plugins/lsp.lua:110, 113
vim.keymap.set('n', '<D-S-b>', …)
vim.keymap.set('v', '<D-S-b>', …)
```

These use `<D-` (Super), which Neovim *does* support **[probe]**. Whether they
actually fire depends on whether iTerm2 sends `ESC [ 98;9 u` for `⌘b` — which
depends on your Cmd modifier setting being **Super** (not Hyper, not Normal) and
on no iTerm2 Key Binding intercepting `⌘b`.

You reported that `<D-a>` prints in the probe, which is strong evidence Super
letters work end to end. **[real]** So these are probably fine — but worth
confirming, since they're the only Super maps you rely on.

### Stale comments

Two places in the repo assert things that are wrong on this machine:

- `CLAUDE.md:24` — "iTerm2 does NOT support kitty keyboard protocol." False;
  iTerm2 3.5+ does. *(Corrected as part of this session.)*
- `init.lua:157-160` — credits "Ghostty's kitty keyboard protocol." You don't run
  Ghostty; the real reason is your `^i` iTerm2 binding. *(Corrected.)*

## Summary table: what actually works today

| combo | status | evidence |
|---|---|---|
| `<D-a>` and Super+letter | works | **[real]** |
| `<S-Left>` | works | **[real]** |
| `<M-Left>` / `<M-Right>` | works (via iTerm2 binding) | **[real]** |
| `<C-Left>` / `<C-Right>` | hijacked → arrives as `<C-A>`/`<C-E>` | **[probe]** + settings |
| `<D-Left>` / `<D-Right>` | unclear — `OH`/`OF` anomaly | unresolved |
| `<Hyper-*>` anything | dead, always | **[probe]** |

**Next:** [Module 5 — Recommendations](05-recommendations.md).
