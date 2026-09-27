# Changelog

## 2026-09-15

- Diff panes now scroll and move their cursors in lockstep (`init.lua`, `lua/plugins/diffview.lua`).

  **Why they drifted.** `:diffthis` — which diffview runs on each pane — sets the window-local option `scrollbind` on both windows, so scrolling one scrolls the other. But `scrollbind` only obeys what the global `scrollopt` option lists, and the default is `ver` alone: vertical scrolling is synced, horizontal scrolling isn't, and after a jump (a search, `gg`, `}`) the two sides are left permanently offset from each other. `scrollopt` is now `ver,hor,jump` — `hor` binds sideways scrolling, and `jump` re-syncs the panes after a jump instead of baking in the offset.

  **Cursor lockstep is a separate option.** `cursorbind` ties the *cursor line* (so `j`/`k` in one pane walks the other pane's cursor down the matching line), where `scrollbind` only ties the *viewport*. `:diffthis` does not set it, so there's a new `OptionSet` autocmd on `diff` that mirrors it: `vim.wo.cursorbind = vim.v.option_new == '1'`.

  **Neovim concepts — `OptionSet` and `vim.v.option_new`:** `OptionSet` is an autocmd event that fires whenever an option is assigned, with the option name as the `pattern`. `vim.v.option_new` holds the value it was just set to (as a string, hence the `== '1'`). Since a window entering or leaving diff mode *is* a write to `diff`, this one autocmd catches diffview's panes as they're created and tears the binding back down when they close — no hunting for window IDs, and nothing diffview-specific to keep in sync.

  Alignment across added/removed lines already worked: `diffopt` includes `filler`, which inserts placeholder lines on the short side so matching lines sit on the same screen row.

- Telescope: auto-widen to `[+tests]` when you type a test-file query, and scope oldfiles to the current repo (`lua/plugins/telescope.lua`).

  **Auto-widen on `.spec`/`.test` in the prompt.** `[narrow]` mode excludes test files via `--glob=!*.{test,spec}.ts`, so typing `utils.spec` there searches a haystack the file has been removed from — zero results, and no hint why. The picker now watches the prompt: type or paste `.spec` or `.test` while in `[narrow]`, and it flips to `[+tests]` and reopens carrying your query over. The prompt prefix changes to `[+tests] > ` so the switch is visible, not silent.

  **Neovim concept — `on_input_filter_cb`:** a Telescope picker option that fires on every prompt change. Telescope's intended use is rewriting the input before it reaches the finder; here it's used purely as a change hook (it returns nothing, so the input passes through untouched).

  Two details that make it work. First, the reopen is wrapped in `vim.schedule` — closing and reopening a picker from inside its own input callback fails, so the work is deferred to the next event-loop tick, after Telescope finishes handling the keystroke. Second, `pending_toggle` guards against re-entry: `actions.close` and the new picker's `default_text` both fire input events, which would otherwise re-enter the callback mid-reopen.

  `open_picker` is now forward-declared (`local open_picker` above, `function open_picker` below) because it and the widen helper call each other. A plain `local function` wouldn't be in scope inside the helper defined above it.

  **Known behavior:** after an auto-widen the mode stays `[+tests]` for that picker session. `<leader>ff`/`<leader>fg` reset to `[narrow]`, and `<C-s>` still cycles manually.

  **Oldfiles scope:** `<leader>fr` shells out to `git rev-parse --show-toplevel` and passes that as `cwd` with `cwd_only = true`, falling back to `getcwd()` outside a repo. `:oldfiles` is global — Neovim's shada file remembers recent files across every project — so unfiltered it surfaced files from unrelated repos.

## 2026-09-14

- Added Jest support to neotest (`lua/plugins/neotest.lua`). `neotest-jest` is now registered as a second adapter next to `neotest-vitest`, so the existing `<leader>t*` keymaps work in Jest projects with no extra config and no new keymaps.

  **How neotest picks an adapter:** neotest asks each adapter in the list `is_test_file(path)` and `root(dir)`. The first one that claims the current file wins. `neotest-vitest` only claims a file when it can find a Vitest config in the project root; `neotest-jest` looks for Jest config or a `jest` key in `package.json`. So both can be registered permanently — per-project detection is the adapters' job, not yours.

  **`jestCommand = 'npm test --'`** runs the project's own `test` script rather than a global `jest` binary, so whatever flags the repo already sets (config path, setup files, projects) still apply. The trailing `--` forwards neotest's own arguments (test name pattern, reporter, `--json`) through npm to Jest instead of npm eating them.

  The duplicated `filter_dir` closure was pulled out into one `not_node_modules` local shared by both adapters. `filter_dir` is neotest's directory-walk pruner — returning `false` stops it descending, which keeps it from scanning `node_modules` for test files.

  Still lazy-loaded: the `vim.pack.add` call only fires on the first `<leader>t*` press, so adding a second adapter costs nothing at startup.

## 2026-08-26

- Wipe the leftover `[No Name]` buffer after `<leader>ba` (`init.lua`). Deleting all buffers drops you into an empty unnamed buffer. Opening a file with `:edit` (oil, find_files) reuses that buffer in place, which is why it appeared to clear itself — but Telescope pickers that jump via `:buffer` (oldfiles, live_grep) leave it behind as the alternate (`#h` in `:ls`).

  A `BufEnter` autocmd now deletes the alternate buffer if it is a listed, unnamed, unmodified, single-empty-line, normal-`buftype` buffer that is not visible in any window.

  **Cost:** it checks the alternate buffer only (`bufnr('#')`) rather than scanning the buffer list, and returns immediately when the buffer being entered is unnamed — which covers most `BufEnter` events. Past that it is roughly six C-level API calls against one buffer: no list iteration, no filesystem access, nothing measurable.

  **Why each guard is there** — every one rules out a class of side effect: `buflisted` skips help, quickfix and terminal buffers; `buftype == ''` skips oil, Telescope and other plugin UI; `not modified` makes data loss impossible; the empty-name and single-empty-line checks mean it can only ever match a genuinely empty scratch buffer; and `win_findbuf` being empty means a scratch buffer you deliberately have open in a split is left alone.

  **Known tradeoff:** if you intentionally keep an empty unnamed buffer as your `<C-^>` alternate-buffer target, it will be removed. Delete the autocmd if that matters more than the tidy buffer list.

- Restored organize-imports on save, without blocking (`lua/plugins/conform.lua`). It was removed from the save path in the non-blocking `:w` change because it cost a synchronous `vim.lsp.buf_request_sync` round-trip, leaving it on `<leader>lf` only. It now runs again on every save, rewritten as an async `client:request` on `BufWritePost` — `:w` still returns immediately.

  Organize-imports and format both mutate the buffer, so running them concurrently would let one clobber the other's edits. They're chained instead: `organize_imports` takes a `done` callback and invokes it on every path (no LSP client, empty result, edits applied), so format can only start once imports have settled, and the single `noautocmd write` happens in format's callback. One sequential chain, one write.

  Also dropped the hardcoded `name = 'typescript-tools'` client guard in favor of a `textDocument/codeAction` capability check, and now requests both `source.organizeImports` and `source.organizeImports.ts` so vtsls and ts_ls work too. `offset_encoding` is read from the client rather than hardcoded to `utf-16`, which corrupts edits on non-ASCII lines when a server negotiates utf-8.

- Fixed the above: organize-imports was a silent no-op (`lua/plugins/conform.lua`). typescript-tools does not expose organize-imports through standard `textDocument/codeAction` — requesting `source.organizeImports` returns only unrelated `refactor.extract` actions ("Move to file"), and those carry a `command` rather than an `edit`, so the `if r.edit` loop matched nothing, applied no changes, and still called its completion callback. Saving looked like it worked and changed nothing.

  typescript-tools instead uses the custom LSP method `typescriptTools/organizeImports`, whose result *is* the workspace edit, applied with a hardcoded `utf-8` encoding (see the plugin's `custom_handlers.lua`). That is now the path taken when the typescript-tools client is attached; the standard codeAction path remains for vtsls/ts_ls, with an added client-side `kind` filter because servers ignore the `only` context filter.

  Mode is `SortAndCombine`, which merges same-source imports and sorts them. Deliberately not `All`, which also deletes unused imports on every save — hostile mid-edit when an import has been typed before its usage.

  Verified end to end against a real TypeScript buffer with the LSP attached: five single-name imports from two modules collapse to two lines on `:w`, the on-disk file matches the buffer, and a second save is a no-op (no rewrite loop).

## 2026-08-24

- Broadened auto-save (`init.lua`). Previously only `FocusLost` (leaving the nvim window) plus `autowriteall` (buffer switches) triggered a write, so editing continuously in one window never saved. Now `InsertLeave` and `TextChanged` also write. Guarded to normal file buffers with a name (`buftype == ''`, modifiable, non-empty name) so terminals, quickfix, help, and unnamed scratch buffers are skipped — writing an unnamed buffer errors.

  Note: combined with the async format-on-`BufWritePost` in `lua/plugins/conform.lua`, each save writes the file twice, so `TextChanged` makes file watchers noticeably busier. Drop `TextChanged` and keep `InsertLeave` if that becomes a problem.

## 2026-08-24

- Added grep-to-replace workflow in Telescope (`lua/plugins/telescope.lua`). `<C-x>` in a live-grep picker sends results to the quickfix list (or just the Tab-selected subset if any), opens it, prompts for a replacement string, runs `cfdo %s/.../gc | update` across all files with per-match confirmation, then closes the editing window and quickfix. `<C-q>` still opens the quickfix without replacing.

## 2026-08-24

- Fixed Tab multi-select in Telescope picker (`lua/plugins/telescope.lua`). The `<C-i>` mapping to `toggle_mode` was capturing Tab due to the shared byte `0x09` — even though the iTerm2 Key Binding sends `<C-i>` as `[105;5u` to distinguish it. Telescope sees the byte first, and since `<C-i>` was mapped there, Tab fell through to the indent mapping instead of multi-selecting files. Added explicit `['<Tab>'] = actions.toggle_selection` to the Telescope input mappings so Tab is captured before byte-level routing.

## 2026-08-24

- Made `:w` non-blocking (`lua/plugins/conform.lua`). Saving ran two synchronous operations on the main thread *before* the write: `organize_imports()`, which does a `vim.lsp.buf_request_sync` with a 3000ms timeout against typescript-tools, and `conform.format()` with `timeout_ms = 2000`, which spawns the formatter and waits for it to exit. Both blocked the UI on every save of a `.ts`/`.tsx`/`.js`/`.jsx` file; the two other-filetype patterns (`.lua`/`.json`/`.md`) blocked on the formatter alone.

  **Fix.** Both `BufWritePre` autocmds are replaced by a single `BufWritePost` one that calls `conform.format({ async = true })` and, in the completion callback, writes the buffer again with `noautocmd write` to persist the formatted text. `:w` now returns immediately. `noautocmd` is what stops the second write from re-triggering `BufWritePost` into a loop.

  **Tradeoffs.** The buffer visibly reformats a moment after the save, and each save writes the file twice — file watchers and dev servers will see two events. `organize_imports()` is no longer part of saving at all; it costs a blocking tsserver round-trip and is now opt-in via `<leader>lf`, which still does organize-imports-then-format synchronously.

  Also switched the deprecated `lsp_fallback = true` to the current `lsp_format = 'fallback'` — the old spelling was emitting a deprecation warning on every save.

  **To undo:** restore the two `BufWritePre` autocmds. If you want format-before-write back but without the stall, the middle option is keeping `BufWritePre`, dropping the `organize_imports()` call, and lowering `timeout_ms` to ~500.

  Note that no formatter binary (`prettier`, `biome`, `stylua`) is currently installed globally or under Mason, so in this repo conform falls through to LSP formatting; project-local `node_modules/.bin/prettier` still resolves normally in JS/TS repos.

- Fixed `foldexpr` referencing a nonexistent global (`init.lua`). It was set to `v:lua.vimtreesitter.foldexpr()` — missing the dot, so it named a global `vimtreesitter` rather than `vim.treesitter`. Every fold computation hit a nil lookup. Now `v:lua.vim.treesitter.foldexpr()`.

- Deferred neotest until first use (`lua/plugins/neotest.lua`). It was loaded and `setup()` fully at startup despite only being needed when running a test. The `vim.pack.add` + `setup()` pair now lives behind a `loaded` flag that the six `<leader>t*` keymaps trigger on first press; subsequent presses hit the cached module. First press costs ~100ms, then nothing.

  Note `vim.pack` has **no** event-based lazy loading — there is no `cmd`/`ft`/`keys` trigger like lazy.nvim, and `load = false` only skips sourcing `plugin/` files while still doing the git check and `:packadd!`. Deferral has to be hand-rolled per plugin, which is why only neotest got it.

  Startup median dropped to ~185ms over 5 runs. The 254ms figure quoted earlier was a single cold sample and overstated the baseline; the real gain here is smaller than the ~21ms the startuptime log attributed to neotest, since that log double-counts shared dependencies.

  **Left eager deliberately:** `octo` (~29ms) registers the `:Octo` command and `octo://` buffer handling at setup time, and `claudecode` (~15ms) starts a server that should be listening before you think to use it. Both would need stub commands shadowing the real ones and re-dispatching — a failure mode that is hard to diagnose later, for ~45ms.

- Removed the orphaned `lazy-lock.json`. Nothing in the config has referenced lazy.nvim since the `vim.pack` migration, and two lockfiles alongside `nvim-pack-lock.json` is a confusion hazard. The lazy.nvim data directory (`~/.local/share/nvim/lazy`, 111M) is still on disk and can be deleted manually.

- Removed `redrawtime = 10000` (`init.lua`), reverting to the 2000ms default. Confirmed unintentional — inherited, not set for a specific file.

  `redrawtime` is the budget nvim spends on `hlsearch`, `inccommand`, `:match`, syntax highlighting, and async treesitter parsing before it gives up and leaves the rest unhighlighted (syntax highlighting stays off for that window until `<C-l>`). On a file or pattern that trips the limit, 10000 meant waiting ~10s for that pass to abandon itself instead of ~2s, reaching the same end state. The higher value only pays off for content that is slow but *finishable* between 2s and 10s — a narrow band not worth the repeated stall.

  Left `maxmempattern = 20000` (also 20× its 1000 default) in place: exceeding that limit raises a hard `E363` and aborts the match rather than degrading gracefully, so a raised ceiling there is defensible.

  **To undo:** re-add `vim.opt.redrawtime = 10000`.

## 2026-08-20

- Bound `<Tab>` to `accept` in blink.cmp (`lua/plugins/blink.lua`). The `default` preset navigates with `<C-n>`/`<C-p>`/arrows and accepts with `<C-y>`, leaving `<Tab>` on `snippet_forward`; Tab now accepts the highlighted completion instead, with arrows still navigating. Falls back to a literal Tab when no menu is open. Note this shadows `snippet_forward`, so Tab no longer advances through snippet placeholders (`<S-Tab>`/`snippet_backward` still goes back) — chain `{ 'accept', 'snippet_forward', 'fallback' }` if that's wanted. Insert-mode only, so it doesn't affect the normal-mode `<Tab>`→`>>` map or the `<C-i>` shared-byte remap.
- Fixed JSDoc comment continuation producing stray, progressively-indented `*` lines (`after/ftplugin/typescript.lua`, plus `javascript`/`typescriptreact`/`javascriptreact` siblings that source it). Pressing Enter or `o` inside a `/** */` block indented each new comment leader one level deeper than the last; Prettier rewrote them to a single space on save, so every doc-comment edit produced a spurious diff.

  **Cause.** Neovim's bundled `runtime/indent/typescript.vim` sets `indentkeys` to `0{,0},0),0],0,,!^F,o,O,e`. The `o`/`O` entries re-trigger `GetTypescriptIndent()` whenever a line is opened, and that function delegates to `cindent()` inside multi-line comments (line 360 of the runtime file). `cindent` indents the new leader relative to the previous line, so continuations drift cumulatively.

  **Fix.** Drop `o`, `O`, and `e` from `indentkeys`. `indentexpr` remains fully active for code — it still fires on the bracket and comma keys and `<C-f>` — it just no longer re-indents a line at the moment one is opened. The setting is applied from a `vim.schedule` callback because something in this config re-runs the stock indent file after `after/ftplugin` loads, overwriting a direct assignment.

  **To undo:** delete `after/ftplugin/typescript.lua` and its three siblings. Watch for `o`/`O` in code no longer auto-adjusting indent on line open (`autoindent` still copies the previous line's indent; `==` re-indents on demand).

  Diagnosed by elimination in a live session: `smartindent` (already cleared by the runtime indent file, so a no-op), blink.cmp's `<CR>` accept binding, and typescript-tools were each ruled out. `:setlocal indentexpr=` confirmed the indent path, and removing `o,O,e` from `indentkeys` confirmed the trigger. Note this does **not** reproduce in headless nvim — test changes here in a real session.

## 2026-08-18

- Fixed typescript-tools failing to attach on the first TypeScript buffer (`lua/plugins/lsp.lua`). The plugin was loaded lazily from a `FileType` autocmd, but `typescript-tools.setup()` registers its *own* `FileType` autocmd to start tsserver — by the time it did, the event for the current buffer had already fired, so nothing started it. Opening nvim directly on a `.ts` file gave no LSP until you re-edited the buffer. The plugin is now loaded eagerly alongside the rest of the LSP stack; tsserver still only spawns for TS/JS buffers because typescript-tools gates that itself, so the lazy wrapper was buying nothing and costing an attach bug. Also dropped the redundant `ts_loaded` flag (the autocmd already used `once = true`).
- Declared `plenary.nvim` in the LSP pack list (`lua/plugins/lsp.lua`). typescript-tools requires it, but only `telescope.lua` and `octo.lua` loaded it, and both run after `lsp.lua` — the lazy loading had masked the ordering problem. Loading eagerly surfaced it as a `require` failure at startup.
- Added the `eslint` language server to Mason's `ensure_installed` (`lua/plugins/lsp.lua`). It's a real LSP separate from tsserver, so it coexists with typescript-tools rather than conflicting; the `automatic_enable` exclusion still only covers `ts_ls`/`vtsls`. Configured with the shared blink.cmp `capabilities`.

## 2026-08-13

- Added `neotest.nvim` with `neotest-vitest` adapter for running TypeScript vitest tests directly in Neovim. Tests run in a summary window showing pass/fail status, output, and error messages. Keymaps: `<leader>tn` (run nearest test), `<leader>tf` (run all tests in current file), `<leader>ts` (toggle test summary window), `<leader>to` (open test output in full window), `<leader>td` (debug nearest test with DAP). Wired to use `npm run test` as the vittest command.

## 2026-08-06

- Removed the uaa-shared sync process: deleted the `## uaa-shared Sync` section from `CLAUDE.md` and the `.last-uaa-sync` tracker file. The agent no longer prompts to mirror this config to `~/code/uaa-shared/taylor.knapp/nvim-config`. The existing mirror directory is untouched — only this repo's automation is gone.
- Added `learning/` — five teaching modules on how macOS, iTerm2, and Neovim handle keyboard input, plus a reusable byte-level probe rig (`probe.lua`, `probe.sh`). Covers the keypress journey across layers, legacy vs kitty/CSI-u encoding and the modifier bitmask, shared keycodes, an inventory of the current two-halves config, and open recommendations. Findings are tagged by evidence type: `[probe]` (synthetic bytes fed to nvim's parser) vs `[real]` (keys pressed in iTerm2).
- Corrected the terminal section of `CLAUDE.md`. It claimed iTerm2 does not support the kitty keyboard protocol — false; iTerm2 3.5+ does, and nvim negotiates it (`CSI ? u` query, then `CSI > 1 u`). Replaced with an ordered debugging checklist: check iTerm2 Key Bindings first (a binding replaces encoding entirely), then nvim's Hyper gap, then macOS system hotkeys. Added the modifier-prefix table (`<S- <M- <C- <D- <T-`) and a note that several keymaps depend on iTerm2 settings outside this repo.
- Corrected the `<C-i>` comment in `init.lua`. It credited Ghostty's kitty protocol; this machine runs iTerm2, and `<C-i>` is distinct only because of an iTerm2 Key Binding sending `^[[105;5u`. Documented that dependency and why `noremap` is required.
- Flagged the `<Hyper-*>` window-navigation keymaps (`init.lua:94-97`) as dead code. nvim's parser strips modifier bit 16, so no `<Hyper-*>` keycode ever reaches the keymap layer — `vim.keymap.set` accepts the name silently. Left in place pending a decision; `<C-h/j/k/l>` already covers the same navigation.

## 2026-08-05

- Added `<M-Left>` / `<M-Right>` (Option+Left/Right arrow) for buffer navigation (`init.lua`). Mirrors the existing `[b`/`]b` buffer navigation mappings — `bnext` and `bprev` under the hood. Provides an ergonomic alternative for buffer cycling alongside `<C-t>`/`<C-S-t>`.

## 2026-07-06

- Added `<leader>/` in visual mode to search *within* the current selection (`init.lua`). It runs `<Esc>/\%V`: leaving visual mode sets the `'<`/`'>` marks that define the `\%V` region, and `\%V` is Vim's built-in "inside the visual area" pattern atom. The search line opens prefilled with `\%V` so any pattern you type after it only matches inside the highlighted block; `n`/`N` cycle matches within that region. Distinct from `//`, which searches *for* the selected text everywhere.
- Added `//` in visual mode to search for the current selection (`init.lua`). The mapping runs `y/<C-r>"<CR>N`: `y` yanks the selection into the unnamed register `"`, `/` opens the search line, `<C-r>"` pastes the register's contents into it, `<CR>` executes the search (jumping to the next match), and `N` jumps back to the original selection so the cursor stays put. After searching you can use `cgn`/`dgn` to change/delete the next match and `.` to repeat on each following match, or `n` to skip one. Mapped in `x` (visual) mode rather than `v` (visual + select) so it doesn't hijack select-mode, where typing characters should replace the selection.

## 2026-07-02

- Added `<leader>bo` keymap for the existing `:Bo` command that deletes all buffers except the current one (`init.lua`). `:Bo` loops over `getbufinfo({ buflisted = 1 })` and `bdelete`s every buffer whose `bufnr` differs from the current one. This avoids the `[No Name]` leftover you get from `:%bd|e#`: `%bd` deletes *every* buffer including the current, so Neovim spawns an empty scratch `[No Name]` buffer to always have something displayed; `e#` reopens the alternate file but the scratch buffer lingers. The loop never touches the current buffer, so the buffer list is never emptied and no scratch buffer is created.

## 2026-06-24

- Made nvim's background transparent so it matches the terminal exactly (`lua/plugins/onedark.lua`). Set `transparent = true` in the onedark setup, which assigns `c.none` to the background of `Normal`, `SignColumn`, `EndOfBuffer`, etc., letting the terminal's own background (and its opacity/blur) show through. Floats keep an opaque background via the existing `NormalFloat`/`FloatBorder` `custom_highlights`. This replaces the earlier approach of hardcoding a `bg0` hex: the terminal's plist `Background Color` is `#282c34` (RGB 40/44/52) — also onedark's default dark `bg0`, so a `bg0 = '#282c34'` override was a no-op — but pixel-sampling showed the terminal renders at `#353942` because it applies opacity. Rather than chase the blended color with a guessed hex, transparency makes nvim inherit the terminal background directly.

## 2026-06-23

- Mapped `<C-i>` to its builtin jumplist-forward in normal mode (`init.lua`). Verified `<C-i>` and `<Tab>` are *distinct* keys under Ghostty's kitty keyboard protocol (a test map of `<C-i>` fired separately from the `<Tab>`→`>>` indent map, and `:verbose nmap <C-i>` showed "No mapping found"), so the Tab indent map was **not** capturing `<C-i>` — the earlier "shared keycode" theory was wrong for this setup. Since `<C-i>` was otherwise unmapped, added an explicit `noremap` map of `<C-i>`→`<C-i>` so the jumplist-forward intent is clear and protected from future `<Tab>` edits. Note: a buffer-local `<C-i>` exists in the telescope picker (`lua/plugins/telescope.lua`, cycles search modes) but that is picker-scoped and does not affect normal mode.
- Added `:KeyLog` keystroke logger (`lua/custom/keylog.lua`, wired in `init.lua`). Toggles a `vim.on_key()` callback — Neovim's hook that fires for every key consumed from the input stream. For each press it echoes two views to `:messages`: the *readable* key name via `vim.fn.keytrans()` (e.g. `<F1>`, `<C-A>`) and the *raw* bytes in `\xNN` hex (the actual escape sequence the terminal sent). It logs the `typed` key (pre-mapping) so you see what the keyboard/terminal really sent. The callback is scoped to a namespace so re-running `:KeyLog` removes exactly this logger; echoing is deferred via `vim.schedule` because `on_key` runs in a fast event context where direct echo is unsafe. Useful for debugging which escape sequence a key/chord produces. Quick built-in alternatives for one-off checks: insert-mode `<C-v>` then the key inserts its raw bytes into the buffer, and `:verbose nmap <lhs>` shows what a key is bound to.

## 2026-06-19

- Added `<leader>of` to reveal the current file in macOS Finder (`init.lua`). The keymap grabs the buffer's absolute path with `vim.fn.expand('%:p')` and runs `open -R <file>` via `vim.system` (async, non-blocking) — `open -R` selects the file inside a Finder window rather than opening it. Warns via `vim.notify` if the buffer has no file on disk (e.g. an unnamed scratch buffer).

## 2026-06-18

- Fixed bare `]c` / `[c` doing nothing in diff windows (e.g. diffview panes) (`lua/plugins/gitsigns.lua`). gitsigns' buffer-local `]c` expr mapping used `if vim.wo.diff then return ']c' end` — returning the string `]c` replays it as keystrokes, which got re-captured by which-key's `]` trigger and never reached the built-in change-jump motion. The normal-file branch already worked because it returns `<Ignore>` (no replay) and jumps from a scheduled `gs.next_hunk()`. Fix: the diff branch now schedules `vim.cmd('normal! ]c')` (the `!` fires the built-in motion with no remapping, immune to which-key) and also returns `<Ignore>`, matching the working pattern. Same for `[c`.
- Documented which-key keystroke interaction in `CLAUDE.md` — which-key forwards completed sequences to real mappings (doesn't "swallow" them); the failure mode is *replayed* keys from `<expr>` returns getting re-trapped, not the initial press; `<Ignore>` ends a press cleanly and `normal!` bypasses all mappings.

- Added `<A-c>` / `<A-C>` (Opt+C / Opt+Shift+C) for next/prev change navigation, working in both normal git buffers and diffview diff panes (`init.lua`, `lua/plugins/diffview.lua`). Handler: in a native diff window (`vim.wo.diff == true`, which covers diffview's diff panes) it runs built-in `]c`/`[c`; elsewhere it calls gitsigns `next_hunk`/`prev_hunk`. Crucially, each direction is mapped to *two* left-hand sides — the `<A-c>` key code **and** the literal composed characters `ç`/`Ç` — because on macOS, holding Option and pressing a letter emits the composed char (Opt+c → `ç`) instead of `<M-c>` unless the terminal sends Option-as-Meta; mapping both makes it fire regardless of delivery. Removed the earlier diffview buffer-local `<A-c>` overrides (which jumped to next *file* via `select_next_entry`) so the global change-navigation handler applies inside diffview. Replaced the earlier `<leader>nc`/`<leader>pc` bindings.

## 2026-06-17

- Added `<A-Left/Down/Up/Right>` (Option+arrow) window navigation keymaps (`init.lua`). Mirrors the existing `<C-Left/Down/Up/Right>` mappings — `<C-w>h/j/k/l` under the hood. Option variants avoid macOS system shortcut conflicts on some terminals.

## 2026-06-17

- Added `telescope-live-grep-args.nvim` extension for path-scoped grep (`lua/plugins/telescope.lua`). The extension replaces `builtin.live_grep` in the `<leader>fg` picker, letting you pass ripgrep flags directly in the prompt. Workflow: type your search term, press `<C-k>` to auto-quote it, then append flags like `--iglob **/terraform/**` to scope results. Shortcut: `<C-g>` quotes the prompt and appends `--iglob **/` in one step — just type the directory name and `/**` suffix. `<C-space>` freezes the current result list and starts a fuzzy refinement search within it. The extension uses its own prompt parser (`auto_quoting = true`) — unquoted text is treated as one search term, so you must quote the search term before adding rg flags. Mode cycling (`<C-i>` for narrow/+tests/all) still works — each mode's `vimgrep_arguments` are passed through to the extension picker.
- Updated oil.nvim `<leader>fg` to use `live_grep_args` instead of `builtin.live_grep` (`lua/plugins/oil.lua`). Grepping from an oil buffer now uses the same picker (with `<C-k>`, `<C-g>`, `<C-space>` keybindings) as the global `<leader>fg`, scoped to the current oil directory via `search_dirs`.
- Patched `telescope-live-grep-args.nvim` extension (`cmd_generator`) to skip rg execution when a glob value is incomplete (`*`, `**`, `**/`). Prevents expensive full-project scans while typing a glob path character-by-character. Also auto-completes glob values: a glob ending in a letter (not a file extension like `.tf`) gets `*/**` appended (e.g. `**/terraform` → `**/terraform*/**`), and a glob ending in `/` gets `**` appended (e.g. `**/terraform/` → `**/terraform/**`). These patches live in the installed extension at `~/.local/share/nvim/site/pack/core/opt/telescope-live-grep-args.nvim/` — they will be overwritten on plugin update.

## 2026-06-16

- Added breadcrumb winbar to oil.nvim directory buffers (`lua/plugins/oil.lua`, `lua/plugins/barbecue.lua`). Oil buffers have filetype `oil` with no LSP, so barbecue skipped them. Fix: added `oil` to barbecue's `exclude_filetypes` (preventing barbecue from rendering an odd path from the `oil://…` buffer name), then added a `BufEnter` autocmd in oil.lua that calls `require('oil').get_current_dir()`, strips the cwd prefix to get a relative path, splits on `/`, and renders the parts joined by ` > ` using barbecue's `BarbecueDirname`/`BarbecueSeparator` highlight groups — so the winbar style is visually consistent with normal file breadcrumbs.



- Added `<Tab>` / `<S-Tab>` in normal and visual mode for indent/dedent (`init.lua`). Normal mode: `<Tab>` maps to `>>` (indent current line), `<S-Tab>` maps to `<<` (dedent). Visual mode: `<Tab>` maps to `>gv`, `<S-Tab>` maps to `<gv` — the `gv` re-selects the visual selection after indenting so you can keep pressing Tab to indent further without re-selecting. These build on the existing `<S-Tab>` = `<C-d>` dedent in insert mode.

## 2026-06-15

- Replaced `lazy.nvim` with `vim.pack` (Neovim 0.12 built-in package manager). All plugin files in `lua/plugins/` rewritten to call `vim.pack.add()` directly — no more declarative lazy specs. Key differences: `vim.pack` uses full GitHub URLs and stores plugins in `site/pack/core/opt/` instead of `~/.local/share/nvim/lazy/`; first startup will re-download all plugins. Plugin structure: `lua/plugins/init.lua` is the new entry point, requiring each plugin file in load order. Lazy loading preserved for: `gitsigns` (BufReadPre), `typescript-tools` (FileType TS/JS), `render-markdown` (FileType markdown). All other plugins load eagerly via `load = true`. `telescope-fzf-native` build step (`make`) wired through `PackChanged` event. `emoji.lua` merged into `blink.lua` (it was always a blink dependency).
- Added `<leader>r` (visual) to replace selection without yanking, `<leader>d` to delete without yanking. Centered navigation: `n`/`N` and `<C-d>`/`<C-u>` now center the view after jumping.

## 2026-06-11

- Fixed `Shift+Tab` in insert mode to dedent (`init.lua`, `lua/plugins/blink.lua`). Two parts: (1) added explicit `vim.keymap.set('i', '<S-Tab>', '<C-d>')` so the key is mapped to Vim's builtin dedent — blink's `fallback` only routes to an *existing* underlying mapping, it doesn't conjure one; (2) moved `undodir` from `~/.vim/undodir` to `vim.fn.stdpath('data') .. '/undodir'` (resolves to `~/.local/share/nvim/undodir`) — the old path crashed on startup because `~/.vim` exists as a file, not a directory, so `mkdir` failed. `stdpath('data')` is the correct XDG location for Neovim data.
- Added `statuscolumn` to left-align line numbers with custom spacing (`init.lua:48`). `statuscolumn = "%l  "` means `%l` (line number, left-aligned) followed by two spaces. This replaces right-alignment and lets you control exact spacing without increasing `numberwidth` (which would pad the left side). Matches VSCode layout: numbers flush left, space to the right before code starts.
- Added `:Bo` custom command to delete all buffers except the current one. Iterates through all listed buffers and skips the current buffer's number in the delete loop (`init.lua`). Solves the problem with `:%bd|e#` leaving an unwanted `[No Name]` buffer by never deleting the current buffer in the first place.
- Diffview: fixed `<cr>` on an added/untracked file jumping straight into the diff on the first press (`lua/plugins/diffview.lua`). Root cause (confirmed with a headless probe): opening a file whose layout *class* differs from the one on screen — e.g. going from a modified file's 2-pane `diff2` to an added file's single-window `diff1_plain` — makes diffview tear down and recreate the diff windows. The recreation runs `vsp`, which leaves nvim's current window inside the new diff pane, and `set_file(focus=false)` never restores panel focus. Same-class opens (modified→modified) reuse windows, so they never drifted — which is why only added files misbehaved. New `open_entry(view, item, focus)` helper registers a one-shot `item.layout.emitter:once('files_opened', …)` listener that snaps the cursor back to the panel window (looked up by buffer via `find_panel_win`) whenever `focus=false`, so the first `<cr>` stays in the panel for every layout. Both `<cr>` and `o` route through it.
- Diffview: killed the remaining single-window conversion delay and fixed `<cr>` focusing the first file immediately (`lua/plugins/diffview.lua`). (1) `view_opened` runs before `git status` finishes loading async (file lists empty), so the bulk convert there was a no-op and conversion only happened on the next directory-watcher tick. Now `view_opened` also attaches a `view.emitter:on('files_updated', …)` listener, which fires the instant status data lands — added files convert with no perceptible delay. (2) diffview auto-opens the first entry, making `view.cur_entry == item` true before the user pressed anything, so the two-stage `<cr>` treated the first Enter as the "already open → focus" case. Added a weak-keyed `cr_activated` set tracking entries the user explicitly opened; `<cr>` now focuses only when the file is on-screen AND was previously opened by `<cr>`/`o`, so the first Enter on any file always stays in the panel.
- Fixed the delay before added/untracked files switched to the single full-width layout (`lua/plugins/diffview.lua`). Conversion was only event-driven — the `view_opened` hook (which runs while git status is still loading async, so `files.working` is often empty) and the directory watcher / `FocusGained`. A freshly-selected added file therefore flashed the 2-pane layout until the next watcher tick (~seconds). Now a per-entry helper `convert_entry_to_single(entry)` runs synchronously inside the panel open keymaps (`<cr>`, `o`), so the layout flips the instant the file opens. The bulk `convert_added_to_single` was refactored to call the same helper.
- Diffview file panel `<cr>` is now two-stage (`lua/plugins/diffview.lua`): first press opens the selected file's diff but keeps the cursor in the panel; pressing `<cr>` again on the already-open file moves the cursor into the diff window. Built from diffview's two primitives — `select_entry` is `view:set_file(item, false)` (open without focus) and `focus_entry` is `view:set_file(item, true)` (open + focus); the custom keymap picks between them by comparing the entry under the cursor to `view.cur_entry`. Directory rows still toggle their fold. `o`/`l`/double-click keep the default open-without-focus behavior. Concepts: diffview panel actions, `set_file` focus arg, custom keymap functions.
- Diffview now renders added/untracked files in a single full-width window instead of a 2-pane diff whose left ("old") side was an empty all-red buffer (`lua/plugins/diffview.lua`). Mechanism: diffview ships a single-window layout class `Diff1` (`diff1_plain`); each file entry owns its `layout` and the view swaps windows based on the entry's layout *class*. A new `convert_added_to_single(view)` helper calls `entry:convert_layout(Diff1)` on every entry whose git status is `A` (staged add) or `?` (untracked), leaving modified files on the normal 2-pane diff. It runs from the `view_opened` hook (initial open) and from the existing `update_left_pane` watcher (files added mid-session). When the currently-shown file is one that got converted, it calls `view:set_file(view.cur_entry, false)` to re-render it with the new single window. Concepts: diffview layout classes, per-entry layout conversion, plugin hooks, git status symbols.
- Changed the insert-mode cursor from a block to a blinking vertical line — `guicursor` segment `i-ci-ve:block` → `i-ci-ve:ver25` (`ver25` = vertical bar 25% of cell width). Blink timing is inherited from the global `a:` segment (`blinkwait700-blinkoff400-blinkon250`). Only renders in terminals that support cursor-shape escape codes.
- Hide the statusline on the Telescope picker — a `FileType TelescopePrompt` autocmd in `init.lua` drops `laststatus` to 0 while the picker is open and restores it on `BufWinLeave`, so no statusline bar is drawn under the picker.

## 2026-06-10

- Added `bufferline.nvim` (`lua/plugins/bufferline.lua`) — VSCode-style per-buffer tabs with file icons, names, LSP diagnostics, and close buttons; replaces Neovim's default path-mangling tabline. Buffer nav on `[b`/`]b` (left `<Tab>` unmapped to preserve `<C-i>` jumplist), pick on `<leader>bp`. Guarded with `cond = not vim.g.vscode`.
- Remapped `<C-t>`/`<C-S-t>` from `tabnext`/`tabprev` (Neovim tabpages) to `BufferLineCycleNext`/`Prev` (buffers), so the key matches the bufferline tab bar — cycling all open buffers including the first. Tabpage create/close stay on `<leader>tn`/`<leader>tc`.
- Added `barbecue.nvim` + `nvim-navic` (`lua/plugins/barbecue.lua`) — VSCode-style breadcrumb winbar showing the file path and LSP symbol trail (`> foo > bar`) above each window. barbecue attaches navic to LSP servers itself (no lsp.lua change). Guarded with `cond = not vim.g.vscode`.

- Neovim 0.12 migration: confirmed clean on 0.12.2 — `:checkhealth vim.deprecated` reports no deprecated functions. Config already used native `vim.lsp.config`, `vim.diagnostic.config`, and the treesitter `main` branch, so no breaking-change fixes were needed. Staying on lazy.nvim (vim.pack has no lazy-loading).
- lazy.nvim: pass `{ rocks = { enabled = false } }` to `setup()` — no plugin needs luarocks; silences the `:checkhealth lazy` hererocks/luarocks error.
- Updated `mason.nvim` to 2.3.0.
- README: added a Requirements section listing external binaries (neovim 0.12+, ripgrep, tree-sitter CLI, gh, C compiler).
- Removed fzf-lua (`lua/plugins/fzf.lua`) — it had no keymaps and nothing required it (the old `gR` LSP-references binding was already gone; references go through `grr` → Trouble). Telescope is the only finder, and it shells out to `rg`, not `find`/`fd`. Dropped the `fd`/`fzf` rows from README Requirements since fzf-lua was their only consumer.

## 2026-05-14

- vscode-neovim: added `<leader>as` (visual) → `claude-code.insertAtMentioned` to send the current selection to the Claude Code VSCode extension.

## 2026-05-12

- vscode-neovim: added `cond = not vim.g.vscode` guards to plugins that don't make sense inside VSCode (LSP, blink, conform, telescope, fzf, gitsigns, diffview, oil, onedark, render-markdown, trouble, octo, claudecode, fugitive, which-key, emoji). Flash, gitlinker, and treesitter remain active.
- vscode-neovim: gated UI-related sections of `init.lua` (line numbers, line wrap, autosave, directory-watcher, scratch, hotreload) behind `vim.g.vscode`.
- Added `lua/custom/vscode.lua` — VSCode-only keymaps that mirror the leader scheme (`<leader>lf` format, `<leader>la` code actions, `<leader>lr` rename, `<leader>f*` pickers, `]d`/`[d` problems, `]c`/`[c` changes, `gi`/`gt`/`grr` LSP nav, `<leader>bd` close editor). Loads only when running under the vscode-neovim extension.

## 2026-05-11

- Yank: `<leader>ya` and `<leader>yr` now resolve the file under the cursor when in an Oil buffer, rather than the Oil buffer path itself.

## 2026-05-06

- Diffview: removed `DiffviewViewLeave` autocmd that was closing the view when switching away from it — diffview now stays open when tabbing out.

## 2026-04-21

- Octo: added `gf` mapping to open the source file in a new tab — works from both the changed-files panel and diff windows.
- README: added Octo review file panel keymaps (toggle viewed, navigate unviewed files, go to file).
- Oil: disabled default `<C-t>` keymap (open in new tab) so the global `<C-t>` (next tab) mapping works in Oil buffers.

## 2026-04-15

- Added `render-markdown.nvim` — renders markdown inline in the buffer (headings, bullets, checkboxes, tables, code blocks). Loads on `markdown` filetype.
- Disabled heading icons in render-markdown — removes the number prefixes (e.g. "1", "2") from rendered headings.

## 2026-03-25

- Telescope: added `<C-q>` mapping to send multi-selected items to quickfix list — enables bulk edits with `:cfdo s///` across selected files.

## 2026-03-23

- Added scratch files feature — persistent notes stored in `stdpath('data')/scratch`. `<leader>sn` creates a new scratch file (defaults to `.md`), `<leader>so` opens Telescope picker for existing scratch files.

## 2026-03-19

- Telescope: narrowed `[narrow]` mode test exclusion from `*.{test,spec}.*` to `*.{test,spec}.ts` — prevents non-TS files like `test.env` from being incorrectly hidden.
- Telescope: added `--no-config` to `[all]` mode — bypasses global ripgrep config (e.g. `~/.ripgreprc`) so truly nothing is excluded.
- Telescope: added `--no-ignore` and `--no-config` to `[+tests]` mode — bypasses `.gitignore` while still excluding heavy dirs (e.g. `node_modules`) via glob exclusions, fixing slow performance in `[all]` mode.
- Telescope: added `--follow` to rg base commands — follows symlinked directories (e.g. git worktree `.local` symlinks).

## 2026-03-13

- Oil: added `<leader>fg` keymap in Oil buffers — opens Telescope live_grep scoped to the directory currently being viewed.

## 2026-03-12

- Added `jsonls` LSP with `schemastore.nvim` for JSON schema validation — auto-detects schemas for `package.json`, `tsconfig.json`, etc. and highlights schema errors.
- Trouble: added `<S-Tab>` in LSP reference/implementation views — toggles between "collapsed to files" and fully expanded. Uses `fold_level` API (depth 2 = files visible, refs hidden).

## 2026-03-10

- Set default indentation to 2 spaces (`tabstop`, `shiftwidth`, `softtabstop`, `expandtab`).
- Telescope: unified excluded dirs into a single `EXCLUDED_DIRS` table (source of truth for both find and grep). Expanded list to include `build`, `coverage`, `out`, `target`, `.yarn`, `vendor`, `.next`, `.nuxt`, `.svelte-kit`, `.turbo`, `.vercel`, `.cache`.
- Telescope: `<M-h>` toggle renamed to `<C-i>` (= Tab) and converted to a three-mode cycle: `[narrow]` (dirs + test/spec/lockfiles/openspec excluded) → `[+tests]` (dirs only) → `[all]` (no exclusions). Works in both `find_files` and `live_grep`. Active mode shown in prompt prefix. Resets to `[narrow]` on fresh picker open.

## 2026-03-04

- Added `_d` and `_x` keymaps — delete without yanking via black hole register. `_dw`, `_dd`, `_d$`, `_x` all work.
- Added auto-save: `autowriteall` for buffer switches + `FocusLost` autocmd for alt-tabbing away. No plugin needed.
- Trouble LSP modes: removed `(typescript-tools)` client suffix from result lines, added file count to References/Implementations title (e.g. "References 111 (5 files)").
- Switched back to `typescript-tools.nvim` from `vtsls` — standalone plugin spec, excluded both `ts_ls` and `vtsls` from mason-lspconfig `automatic_enable`. Conform organize imports guard updated to `typescript-tools` client.
- Mapped `<Esc>` in terminal mode to exit back to normal mode (`<C-\><C-n>`).

## 2026-03-03 (updated 4)

- Replaced `vtsls` with `typescript-tools.nvim` — talks to tsserver directly via native protocol, no LSP translation layer. Added as a standalone plugin spec (not managed by mason-lspconfig). Both `ts_ls` and `vtsls` excluded from `automatic_enable`. Conform organize imports guard updated to check for `typescript-tools` client.
- Switched flash.nvim to `search` mode with `ignorecase`+`smartcase` — case-insensitive substring matching unless an uppercase letter is typed. Also benefits `/` and `?` search.
- Replaced `gr`/`gR` with unambiguous mappings: `grr` → Trouble LSP references (overrides Neovim 0.11 default), `Cmd+B` → same, `Cmd+Shift+B` → ripgrep word/selection → Trouble qflist. Fixes `gr` appearing to "do nothing" — which-key was intercepting the ambiguous prefix (`gr` vs `grr`/`grn`/`gra`/`gri`) and waiting for disambiguation.
- Excluded `vtsls` from mason-lspconfig `automatic_enable` — was auto-starting alongside `ts_ls`.
- Smart `<CR>` in Trouble LSP modes: fold_toggle on group headers, jump_close on leaf items. `<Tab>` still works for fold toggle.
- Routed `gi` (implementation) through Trouble — same bottom split layout as `grr` (references).
- `gd` now always jumps to first result (no quickfix panel when ts_ls returns class + constructor). Shows warning when no definition found.

## 2026-03-03

- Wired `gr` through ripgrep → Trouble qflist — results now open in a bottom split grouped by file with fold/unfold, instead of a flat fzf-lua list. Uses `vim.system` (async) so rg runs without blocking the UI, then populates quickfix list and opens Trouble's `qflist` mode. Visual mode `gr` also supported. `gR` (LSP references via fzf-lua) unchanged.
- Replaced `typescript-tools.nvim` with `ts_ls` — standard LSP client via mason-lspconfig. Tried vtsls first but no speed improvement over typescript-tools; ts_ls is simpler with fewer moving parts. Semantic tokens disabled, 4096MB memory limit carried over.
- Swapped `gr`/`gR` — `gr` is now instant ripgrep (grep_cword/grep_visual scoped to TS/JS files), `gR` is LSP references via fzf-lua. Prioritizes speed for the most common keymap; LSP references still available when you need semantic precision.

## 2026-03-02 (updated 13)

- Made `gr` actually fast: set `async_or_timeout = true` in fzf-lua so LSP pickers use `buf_request()` (async) instead of `buf_request_sync()` — picker opens immediately, results stream in, Neovim stays responsive.
- Disabled semantic tokens in typescript-tools — tsserver was classifying every token on every buffer change, competing for its single-threaded event loop. Tree-sitter already handles all highlighting.
- Bumped tsserver max memory from 3072 → 4096 MB to reduce GC pressure on larger projects.

## 2026-03-02 (updated 12)

- Switched `gr` (find references) from Trouble to fzf-lua — picker appears immediately and streams results as tsserver responds, vs Trouble blocking until all results are collected. Added fzf-lua plugin (`lua/plugins/fzf.lua`).
- Switched `gd`, `gi`, `gt` from Trouble to direct `vim.lsp.buf.*` jumps — these almost always return a single result, so instant jump beats opening a list.
- Stripped Trouble down to diagnostics only (`<leader>tt`). Removed all LSP mode configs and split/tab keybindings that are no longer needed.

## 2026-03-02 (updated 11)

- Made `<CR>` context-aware in LSP Trouble modes: toggles fold on group headers, jumps+closes on leaf items. `<Tab>` still works for fold toggle too.

## 2026-03-02 (updated 10)

- Routed `gd`, `gi`, `gt` through Trouble (previously used raw `vim.lsp.buf.*`). All LSP navigation commands (`gd`, `gr`, `gi`, `gt`) now open in a bottom split with `<C-x>`/`<C-v>`/`<C-t>` for split/vsplit/tab. Extracted shared mode config to avoid duplication across four Trouble modes.

## 2026-03-02 (updated 9)

- Changed `gr` (LSP references) from centered float to bottom split — keeps the code preview visible while cycling through results. Added `<C-x>` (horizontal split), `<C-v>` (vertical split), and `<C-t>` (new tab) keybindings inside the references panel, matching Telescope conventions. All close the panel after jumping.

## 2026-03-02 (updated 8)

- Documented `tree-sitter-cli` as a required dependency in README. The refactored nvim-treesitter plugin uses `tree-sitter build` (not `cc` directly) to compile parser `.so` files. Without the CLI (`brew install tree-sitter-cli`), parsers silently fail to install, and Trouble emits "parser missing" warnings when rendering references.

## 2026-03-02 (updated 7)

- Fixed `ts_ls` auto-starting alongside `typescript-tools` — mason-lspconfig v2 silently ignores `handlers`; switched to `automatic_enable = { exclude = { 'ts_ls' } }` which is the correct API.
- Fixed `lua_ls` not receiving blink.cmp capabilities — the `handlers` config was dead code. Switched to `vim.lsp.config('lua_ls', { capabilities })` in `init`, which mason-lspconfig's `automatic_enable` picks up.
- Added `<Esc>` to close Trouble floats (e.g. `gr` references).

## 2026-03-02 (updated 6)

- Added `ensure_installed` parsers to treesitter config: typescript, tsx, lua, javascript, json, markdown. Previously relied on manual `:TSInstall`; parsers now auto-install on first launch.
- Replaced `ts_ls` (typescript-language-server) with `typescript-tools.nvim` — communicates with tsserver via native protocol directly, eliminating the LSP translation layer. Fixes slow `gr` (find references) and other TypeScript LSP actions. Also fixed a latent bug in `conform.lua` where the `organize_imports` guard always passed (comparing `{}` to `nil`); now correctly checks `#get_clients(...) == 0`.
- Added trouble.nvim for grouped, collapsible LSP references. `gr` now opens Trouble's `lsp_references` view (results grouped by file, `<Tab>` to fold/unfold). `<Space>tt` toggles the Trouble panel. Opens as a float, auto-focuses, and closes on `<cr>`.
- Explicitly mapped `<Tab>` to `fold_toggle` in Trouble (not bound by default; `za` is the vim-native default).
- Rewired `<Space>tt` to toggle a diagnostics panel (bottom split, project-wide errors/warnings grouped by file). References (`gr`) stays a float.
- Updated uaa-shared sync in CLAUDE.md: exclude `.gitignore` from rsync, push to remote after committing. Agent will prompt to sync every 2 weeks. Tracker date stored in `.last-uaa-sync`.
- Added tab keymaps: `<C-t>` next tab, `<C-S-t>` prev tab, `<Space>tn` new tab, `<Space>tc` close tab. Added "Tab" group to which-key.

## 2026-02-25 (updated 3)

- Added `<Space>la` — code actions (import missing symbol, remove unused imports, etc.)

## 2026-02-25 (updated 2)

- Refined diagnostic keymaps: navigation keys `]d`/`[d`/`]e`/`[e` now auto-open float after jumping. Added `<Esc>` to close diagnostic float (otherwise clears search highlight).

## 2026-02-25 (updated)

- Added diagnostic keymaps: `<Space>ld` show float, `]d`/`[d` next/prev diagnostic, `]e`/`[e` next/prev error only. Global diagnostic config with rounded float borders and severity sorting.

## 2026-02-25

- Added `flash.nvim` — label-based motion plugin. `s` to jump, `S` for treesitter node selection, `r` for remote flash in operator-pending mode, `<C-s>` to toggle flash in command-line search.

## 2026-02-24 (updated 2)

- Fixed `<CR>` in Octo review submit popup closing the window instead of accepting blink completions — Octo's default `<C-m>` mapping (byte-equivalent to `<CR>`) was intercepting Enter. Remapped `comment_review` to `<C-s>`.
- Fixed `@`/`#`/`:` git completion sources not triggering in Octo submit popup — popup sets `vim.bo.syntax = "octo"` but not `vim.bo.filetype`. Moved git source into `default` sources with an `enabled` function that checks both filetype and syntax.

## 2026-02-24 (updated)

- Added `emoji.nvim` — emoji autocompletion via blink.cmp source; `<Space>fe` opens Telescope emoji picker.
- Replaced omnifunc `@`/`#` keymaps in Octo buffers with `blink-cmp-git` — native blink.cmp source that handles `@` mentions, `#` issues/PRs automatically. Enabled for `octo` and `gitcommit` filetypes via `per_filetype`.

## 2026-02-24

- Enabled `number` and `relativenumber` globally
- Added `<Space>orc` keymap — `:Octo review resume` (continue existing review)
- Enabled `wrap` and `linebreak` globally
- Fixed wrap being disabled in Octo review buffers: oil.nvim was setting `wrap = false` via its `win_options` default; overridden to `wrap = true` in oil config
- Updated octo.nvim keymaps: renamed `<Space>or` → `<Space>ok` (PRs to review); added `<Space>ors` (review start) and `<Space>ord` (review submit)
- Added `gr` keymap to LSP — go to references (opens quickfix list of all usages)

## 2026-02-23

- Added octo.nvim keymaps: `<Space>op` (PR list), `<Space>on` (notifications), `<Space>oc` (PR checkout), `<Space>or` (PRs to review, excluding bots)
- Added `disable_defaults = false` to diffview.nvim keymaps config to preserve default conflict resolution bindings

- Added hunk mode to gitsigns — `<Space>hp` enters hunk mode (opens preview), `<Down>`/`<Up>` navigate between hunks with auto-preview, `<Esc>` exits and closes the float. Arrow keys are only remapped while in hunk mode.

## 2026-02-20 (updated)

- Updated `conform.nvim` — `<Space>lf` and save now remove unused imports and sort remaining ones before formatting. Uses `source.organizeImports` via ts_ls (synchronous `buf_request_sync`) so organize imports always completes before prettier/biome rewrites the buffer. Dropped `format_on_save` in favor of explicit `BufWritePre` autocmds to guarantee ordering. Only fires for buffers with ts_ls attached, so non-TS files are unaffected.

- Added `blink.cmp` — completion engine with LSP, path, and buffer sources. Uses `lazy = false` to load immediately. Wired into `ts_ls` and `lua_ls` via `get_lsp_capabilities()`. Auto-imports work on completion accept.

## 2026-02-19

- Added `which-key.nvim` — keymap popup when pausing after `<Space>`. Group labels registered for `a` (Claude), `b` (Buffer), `f` (Find), `g` (Git), `h` (Hunks), `l` (LSP), `y` (Yank).
- Added convenience keymaps: `<C-hjkl>` window navigation, `<Space>nh` clear search highlights, `<Space>bd` delete buffer, `<Space>?` show buffer-local keymaps.
- Added `dist` to Telescope exclusions for both `find_files` and `live_grep`
- Added `gitlinker.nvim` — copy GitHub permalinks from normal/visual mode. `<Space>gy` copies link, `<Space>gY` opens in browser.
- Added `conform.nvim` — formats using project-local tool (prettier or biome, whichever is present) rather than LSP formatting. Runs on save automatically. `<Space>lf` to format manually.

## 2026-02-18

- Added `claudecode.nvim` — bridges Neovim and Claude Code CLI via WebSocket MCP protocol. Uses `event = "VeryLazy"` to ensure the WebSocket server starts on launch (lazy-loading on `keys` alone prevents lock file creation). Terminal provider set to `"none"` for external Claude Code usage.
- Added `mason.nvim` + `mason-lspconfig.nvim` + `nvim-lspconfig` for LSP support. Installs `ts_ls` (TypeScript) and `lua_ls` (Lua). Keymaps: `gd` (definition), `gi` (implementation), `gt` (type definition).
- Updated `oil.nvim` to show hidden files (`show_hidden = true`)

## 2026-02-15

- Added `onedark.nvim` colorscheme plugin with `darker` style to match VSCode "Atom One Dark"
- Added `nvim-treesitter` for proper syntax highlighting (keywords like `const`, `import`, etc.)
- Added `telescope.nvim` fuzzy finder with `<Space>f` keymaps
- Added `oil.nvim` file explorer (press `-` to open)
- Added `octo.nvim` for GitHub issues/PRs in Neovim

## 2026-02-13

- Initial config created from https://xata.io/blog/configuring-neovim-coding-agents
  - `custom/directory-watcher` — filesystem watcher via `uv.fs_event`
  - `custom/hotreload` — auto-reload buffers on external file changes
  - `custom/yank` — yank code with file path + line range context
  - `plugins/diffview` — diffview.nvim with auto-refresh on git changes
  - Yank keymaps: `<Space>yr` (relative), `<Space>ya` (absolute) in normal + visual
  - Plugin manager: lazy.nvim (auto-bootstrapped)
- Replaced `clipboard = 'unnamedplus'` with explicit `<Space>y` / `<Space>p` keymaps for system clipboard — keeps default `y`/`d`/`p` on internal registers
