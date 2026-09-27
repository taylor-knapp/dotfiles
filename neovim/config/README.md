# Neovim Config

Optimized for working alongside coding agents (Claude Code, etc.) that modify files externally.

Based on: https://xata.io/blog/configuring-neovim-coding-agents

## Requirements

External binaries this config expects on `$PATH`:

| Tool             | Install                          | Used by                                          |
| ---------------- | -------------------------------- | ------------------------------------------------ |
| Neovim 0.12+     | `brew install neovim`            | everything (native LSP/diagnostics, treesitter `main` branch) |
| `ripgrep` (`rg`) | `brew install ripgrep`           | telescope find/grep, `gr` grep-to-Trouble        |
| `tree-sitter`    | `brew install tree-sitter-cli`   | treesitter parser compilation (`tree-sitter build`) |
| `gh`             | `brew install gh` (authenticated)| octo.nvim (GitHub PRs/issues)                    |
| C compiler       | Xcode CLT (`xcode-select --install`) | treesitter parser builds                     |

## VSCode (vscode-neovim)

This config supports running inside the [vscode-neovim](https://github.com/vscode-neovim/vscode-neovim) extension. When `vim.g.vscode` is set, plugin specs that overlap with VSCode features (LSP, completion, pickers, file explorer, statusline-like UI, diagnostics panel, git signs, diff view, markdown rendering, colorscheme, claudecode) are skipped via `cond = not vim.g.vscode`. Plugins kept active inside VSCode:

- `flash.nvim` — label-based motion (works on the buffer text VSCode shows)
- `gitlinker.nvim` — copy GitHub permalinks
- `nvim-treesitter` — required by `flash.treesitter`

`lua/custom/vscode.lua` mirrors the leader keymaps to their VSCode command equivalents:

| Keymap        | VSCode command                                |
| ------------- | --------------------------------------------- |
| `<leader>lf`  | `editor.action.formatDocument` / `…Selection` |
| `<leader>la`  | `editor.action.quickFix`                      |
| `<leader>lr`  | `editor.action.rename`                        |
| `<leader>ld`  | `editor.action.showHover`                     |
| `grr`         | `editor.action.referenceSearch.trigger`       |
| `gi` / `gt`   | go to implementation / type definition        |
| `]d` / `[d`   | next / prev problem                           |
| `]e` / `[e`   | next / prev error in files                    |
| `]c` / `[c`   | next / prev change                            |
| `<leader>ff`  | `workbench.action.quickOpen`                  |
| `<leader>fg`  | `workbench.action.findInFiles`                |
| `<leader>fb`  | `workbench.action.showAllEditors`             |
| `<leader>fr`  | `workbench.action.openRecent`                 |
| `<leader>fs`  | `workbench.action.gotoSymbol`                 |
| `<leader>fS`  | `workbench.action.showAllSymbols`             |
| `<leader>bd`  | `workbench.action.closeActiveEditor`          |
| `<leader>as`  | `claude-code.insertAtMentioned` (visual)      |


## Structure

```
~/.config/nvim/
├── init.lua                          # Entry point: lazy.nvim bootstrap, keymaps, module setup
├── lua/
│   ├── custom/
│   │   ├── directory-watcher.lua     # Filesystem watcher (uv.fs_event)
│   │   ├── hotreload.lua             # Auto-reload buffers on external changes
│   │   ├── keylog.lua                # :KeyLog keystroke/escape-sequence logger
│   │   ├── scratch.lua               # Persistent scratch notes
│   │   ├── vscode.lua                # vscode-neovim-only keymaps (LSP, pickers, etc.)
│   │   └── yank.lua                  # Copy code with file path context
│   └── plugins/
│       ├── blink.lua                 # Completion engine (LSP, path, buffer sources)
│       ├── barbecue.lua              # VSCode-style breadcrumb winbar (path + symbol trail)
│       ├── bufferline.lua            # VSCode-style per-buffer tabs (icons, diagnostics)
│       ├── claudecode.lua            # Claude Code CLI ↔ Neovim bridge (WebSocket MCP)
│       ├── conform.lua               # Formatter (prettier, biome, stylua)
│       ├── flash.lua                 # Motion/jump plugin (label-based navigation)
│       ├── diffview.lua              # diffview.nvim config + auto-refresh
│       ├── lsp.lua                   # Mason + LSP config (ts_ls, lua_ls)
│       ├── gitlinker.lua              # Copy GitHub permalinks
│       ├── neotest.lua               # Test runner for vitest + jest (TS/JS tests)
│       ├── octo.lua                  # GitHub issues/PRs via Octo
│       ├── oil.lua                   # File explorer (edit dirs like buffers)
│       ├── onedark.lua               # Colorscheme (Atom One Dark)
│       ├── telescope.lua             # Fuzzy finder
│       ├── treesitter.lua            # Treesitter parser install + highlighting
│       ├── trouble.lua               # Diagnostics panel (grouped by file)
│       └── which-key.lua             # Keymap popup with group labels
├── after/
│   ├── ftplugin/typescript.lua       # JSDoc indent fix (see file header); js/tsx/jsx source it
│   └── queries/ecma/highlights.scm   # Custom treesitter query (=> as keyword)
├── learning/                         # Notes on keyboard input: macOS → iTerm2 → nvim
│   ├── 01-keypress-journey.md        # The five layers a keypress crosses
│   ├── 02-key-encoding.md            # Legacy vs kitty/CSI-u, modifier bitmask
│   ├── 03-shared-keycodes.md         # <C-i>/<Tab>, <C-m>/<CR>, <C-[>/<Esc>
│   ├── 04-your-current-setup.md      # Inventory: nvim keymaps + iTerm2 bindings
│   ├── 05-recommendations.md         # Proposed changes and open questions
│   └── probe.sh, probe.lua           # Feed synthetic bytes to nvim's key parser
```

> Keyboard input debugging: start with `:KeyLog`, then see `learning/`. Note that
> several keymaps depend on iTerm2 Key Bindings that are not in this repo —
> `learning/04-your-current-setup.md` lists them.

## Modules

### Directory Watcher (`custom/directory-watcher`)

Low-level filesystem monitor using Neovim's native `uv.fs_event` API. Watches the cwd for file changes and dispatches to named handlers. Other modules register themselves as handlers rather than setting up their own watchers.

### Hot Reload (`custom/hotreload`)

Automatically reloads open buffers when files change on disk. Responds to both filesystem events (via directory-watcher) and Neovim autocmds (`FocusGained`, `BufEnter`, etc.). Skips buffers with unsaved modifications and ignores special buffers (URI schemes like `diffview://`).

### Keystroke Logger (`custom/keylog`)

`:KeyLog` toggles a `vim.on_key()` callback that fires for every key Neovim consumes. Each press is echoed to `:messages` in two forms: the readable key name (`vim.fn.keytrans()`, e.g. `<F1>`, `<C-A>`) and the raw bytes in `\xNN` hex (the actual escape sequence). Logs the pre-mapping `typed` key, so it shows what your terminal/keyboard really sent — handy for debugging which sequence a key or chord produces. Run `:KeyLog` again to stop.

Quick one-off alternatives without the logger: insert-mode `<C-v>` then a key inserts its raw bytes into the buffer, and `:verbose nmap <lhs>` shows a key's current binding.

### Yank with Path (`custom/yank`)

Copies code to the system clipboard with file location context — useful for pasting into Claude Code with `@file:line` references.

### claudecode.nvim (`plugins/claudecode`)

Bridges Neovim and Claude Code CLI via WebSocket. The plugin starts a WebSocket server on launch and writes a lock file to `~/.claude/ide/<port>.lock`. Claude Code CLI scans that directory, matches by `workspaceFolders` against its cwd, and connects automatically. This gives Claude access to open buffers, visual selections, and diagnostics.

- **`event = "VeryLazy"`** is required — without it, lazy.nvim defers loading until a keybinding is pressed, so the WebSocket server never starts.
- **`provider = "none"`** — Claude Code runs externally (terminal/tmux), not inside a Neovim split.
- Lock files are cleaned up on normal exit (`VimLeavePre`). Stale files from crashes can be deleted from `~/.claude/ide/`.

Community plugin by [Coder](https://github.com/coder/claudecode.nvim) — no official Anthropic Neovim plugin exists.

### gitlinker.nvim (`plugins/gitlinker`)

Copies GitHub permalinks (with commit SHA + line range) to the clipboard. Works in normal mode (current line) or visual mode (selected lines). Uses `event = "VeryLazy"` — lazy-loading on `cmd`/`keys` alone doesn't register the `:GitLink` command properly.

| Keymap      | Mode          | Description                 |
| ----------- | ------------- | --------------------------- |
| `<Space>gy` | Normal/Visual | Copy permalink to clipboard |
| `<Space>gY` | Normal/Visual | Open permalink in browser   |

### conform.nvim (`plugins/conform`)

Formatter that runs the project-local tool rather than LSP formatting (which ignores prettier/biome config). Uses `stop_after_first = true` to pick whichever formatter is available — tries prettier before biome.

For TypeScript/JavaScript files, `source.organizeImports` runs synchronously via ts_ls before the formatter — this removes unused imports and sorts the remaining ones. Uses `buf_request_sync` so the organize step always completes before prettier/biome rewrites the buffer. Only fires when ts_ls is attached; non-TS files are unaffected.

| Keymap      | Description                       |
| ----------- | --------------------------------- |
| `<Space>lf` | Organize imports then format file |

Formatters by file type: TypeScript/JavaScript/JSON → prettier or biome, Lua → stylua, Markdown → prettier.

### flash.nvim (`plugins/flash`)

Label-based motion plugin by folke. Type `s` then a search character — flash highlights all matches with jump labels. Press the label key to jump instantly. Also supports treesitter-based node selection with `S`.

| Keymap  | Mode            | Description                          |
| ------- | --------------- | ------------------------------------ |
| `s`     | Normal/Visual/Op | Flash jump (type char, pick label)  |
| `S`     | Normal/Visual/Op | Flash treesitter (select nodes)     |
| `r`     | Operator-pending | Remote flash (operate at distance)  |
| `<C-s>` | Command-line     | Toggle flash search in `/` or `?`  |

### diffview.nvim (`plugins/diffview`)

Git diff viewer with inline editing. Auto-refreshes its file panel when the directory watcher detects changes (git index or working tree). Press `q` to close.

### trouble.nvim (`plugins/trouble`)

Diagnostics panel and grep results viewer. Displays items grouped by file in a bottom split with fold/unfold. `gr` grep results use the `qflist` mode; `<Space>tt` uses the `diagnostics` mode.

| Keymap       | Description                          |
| ------------ | ------------------------------------ |
| `<Space>tt`  | Toggle diagnostics panel (bottom split) |
| `<Tab>`      | Fold/unfold file group               |
| `<S-Tab>`    | Toggle collapse all to files         |
| `Enter`      | Jump and close                       |
| `q` / `Esc`  | Close                                |

### neotest.nvim (`plugins/neotest`)

Test runner for TypeScript/JavaScript projects using vitest or Jest. Both adapters are registered; neotest asks each one whether it claims the current file, so the correct runner is picked per project with no config. Opens a summary window showing test results (pass/fail status, error messages, execution time). Supports running tests at multiple scopes — nearest test, entire file, or custom patterns.

| Keymap       | Description                          |
| ------------ | ------------------------------------ |
| `<leader>tn` | Run nearest test                     |
| `<leader>tf` | Run all tests in current file        |
| `<leader>ts` | Toggle test summary window           |
| `<leader>to` | Open test output in full window      |
| `<leader>td` | Debug nearest test (with DAP)        |

Vitest runs via `npm run test`; Jest runs via `npm test --` so the project's own test script and flags apply. Test output and errors appear in the summary window or in a dedicated output buffer. Press `q` to close the summary, or use `<leader>ts` to toggle it on/off.

### mason + nvim-lspconfig (`plugins/lsp`)

[Mason](https://github.com/mason-org/mason.nvim) manages LSP server installations. Configured with `ts_ls` (TypeScript) and `lua_ls` (Lua). LSP keymaps are set per-buffer via `LspAttach` autocmd:

| Keymap      | Description                                |
| ----------- | ------------------------------------------ |
| `gd`        | Go to definition (direct jump)             |
| `gr`        | Grep word/selection → Trouble qflist       |
| `grr`       | LSP references → Trouble                    |
| `gi`        | Go to implementation (direct jump)         |
| `gt`        | Go to type definition (direct jump)        |
| `<Space>lr` | Rename symbol                              |
| `<Space>la` | Code actions                               |
| `<Space>ld` | Show diagnostic float                      |
| `]d`        | Next diagnostic (open float)               |
| `[d`        | Prev diagnostic (open float)               |
| `]e`        | Next error (open float)                    |
| `[e`        | Prev error (open float)                    |
| `<Esc>`     | Close diagnostic float                     |

### blink.cmp (`plugins/blink`)

Completion engine powered by LSP. Uses `lazy = false` to ensure it's active as soon as insert mode is entered. Wired into `ts_ls` and `lua_ls` via `get_lsp_capabilities()` so completions include LSP suggestions, auto-imports, and signatures.

Sources: LSP (primary), file paths, open buffers. The `git` source via [blink-cmp-git](https://github.com/Kaiser-Yang/blink-cmp-git) is included in default sources but gated by an `enabled` function — activates for `octo` and `gitcommit` filetypes, and also when `vim.bo.syntax == "octo"` (catches the Octo review submit popup which sets syntax but not filetype). Provides `@` mentions, `#` issue/PR references, and `:` emoji.

| Keymap  | Description              |
| ------- | ------------------------ |
| `<C-n>` / `<Down>` | Next completion item     |
| `<C-p>` / `<Up>`   | Previous completion item |
| `<Tab>`            | Accept completion        |
| `<CR>`             | Accept completion        |
| `<C-y>`            | Accept completion        |
| `<C-e>`            | Dismiss completion menu  |

`<Tab>` overrides the `default` preset's `snippet_forward`, so it does not advance through snippet placeholders; `<S-Tab>` still jumps backward.

Auto-imports work automatically — accepting a completion that requires an import inserts it at the top of the file.

## Keymaps

Leader key: `Space`

| Keymap      | Mode          | Description                               |
| ----------- | ------------- | ----------------------------------------- |
| `<Space>y`  | Normal/Visual | Yank to system clipboard                  |
| `<Space>p`  | Normal/Visual | Paste from system clipboard               |
| `<Space>yr` | Normal        | Yank relative file path                   |
| `<Space>ya` | Normal        | Yank absolute file path                   |
| `<Space>yr` | Visual        | Yank selection with relative path + lines |
| `<Space>ya` | Visual        | Yank selection with absolute path + lines |
| `<Space>ab` | Normal        | Add current buffer to Claude Code context |
| `<Space>as` | Visual        | Send selection to Claude Code             |
| `<Space>lf` | Normal        | Organize imports + format file (conform)  |
| `<Space>lr` | Normal        | Rename symbol                             |
| `<Space>of` | Normal        | Reveal current file in macOS Finder       |
| `<Space>nh` | Normal        | Clear search highlights                   |
| `<Space>bd` | Normal        | Delete buffer                             |
| `<Space>tt` | Normal        | Toggle diagnostics panel (Trouble)        |
| `<Space>?`  | Normal        | Show buffer-local keymaps (which-key)     |
| `<leader>tn` | Normal       | Run nearest test                          |
| `<leader>tf` | Normal       | Run all tests in current file             |
| `<leader>ts` | Normal       | Toggle test summary window                |
| `<leader>to` | Normal       | Open test output in full window            |
| `<leader>td` | Normal       | Debug nearest test (with DAP)             |
| `<C-t>`     | Normal        | Next buffer tab (bufferline)              |
| `<C-S-t>`   | Normal        | Prev buffer tab (bufferline)              |
| `]b`        | Normal        | Next buffer tab (bufferline)              |
| `[b`        | Normal        | Prev buffer tab (bufferline)              |
| `<Space>bp` | Normal        | Pick a buffer tab (bufferline)            |
| `<M-Right>` | Normal        | Next buffer (bufferline)                  |
| `<M-Left>`  | Normal        | Prev buffer (bufferline)                  |
| `<Space>tn` | Normal        | New tabpage                               |
| `<Space>tc` | Normal        | Close tabpage                             |
| `<C-h>`     | Normal        | Move to left window                       |
| `<C-j>`     | Normal        | Move to lower window                      |
| `<C-k>`     | Normal        | Move to upper window                      |
| `<C-l>`     | Normal        | Move to right window                      |

### nvim-treesitter (`plugins/treesitter`)

Installs and compiles tree-sitter parsers for syntax highlighting. **Requires the `tree-sitter` CLI** (`brew install tree-sitter-cli`) — the refactored plugin uses `tree-sitter build` to compile parser `.so` files. Without it, parsers silently fail to install and plugins like Trouble will warn about missing parsers. A working C compiler (Xcode license accepted) is also required.

The new API (post-refactor) works differently from older guides:

- **Must use `lazy = false`** — the plugin does not support lazy-loading.
- **Parser install:** `require('nvim-treesitter').install { 'typescript', 'tsx', ... }` (old `require('nvim-treesitter.configs').setup` module no longer exists).
- **Highlighting:** Neovim's built-in `vim.treesitter.start()` must be called per-buffer via a `FileType` autocommand. The old `highlight = { enable = true }` option is gone.
- **Custom queries:** Place in `after/queries/<language>/highlights.scm` with `; extends` at the top to override specific captures without replacing the full query. Example: reclassifying `=>` from `@operator` to `@keyword.operator`.
- Without treesitter active, Neovim falls back to regex syntax highlighting which maps keywords to different highlight groups — this causes color mismatches with themes like onedark.nvim that define treesitter-specific groups (`@keyword`, `@keyword.import`, etc.).

### barbecue.nvim (`plugins/barbecue`)

VSCode-style breadcrumb winbar above each window: file path icon + name, then the LSP document-symbol trail (`> fileDeletion > hpa > metrics`). The symbol trail comes from `nvim-navic`, which barbecue attaches to LSP servers automatically (`attach_navic = true`) — no change needed in `plugins/lsp`. `show_modified` puts a dot on unsaved buffers.

### bufferline.nvim (`plugins/bufferline`)

VSCode-style tabline: one tab per open buffer, with a file icon, name, LSP diagnostic count, and close button. Replaces Neovim's default tabline (which mangles long buffer paths into `o///U/t/c/c/...`). `mode = 'buffers'`, oil buffers render as a `Files` side offset. `<Tab>` is intentionally left unmapped so it keeps working as `<C-i>` (jumplist forward).

### onedark.nvim (`plugins/onedark`)

Colorscheme matching VSCode "Atom One Dark". Uses `style = 'dark'`. When treesitter is active, all `@keyword.*` groups are already purple — no manual highlight overrides needed.

### telescope.nvim (`plugins/telescope`)

Fuzzy finder for files, text, buffers, and help. Lazy-loaded on keymaps.

Both `find_files` and `live_grep` show hidden files and respect `.gitignore`. Uses `rg` as the backend. Edit `EXCLUDED_DIRS` / `EXCLUDED_FILES` in `telescope.lua` to change exclusions.

| Keymap      | Description                      |
| ----------- | -------------------------------- |
| `<Space>ff` | Find files by name               |
| `<Space>fg` | Live grep (search file contents) |
| `<Space>fb` | Switch between open buffers      |
| `<Space>fh` | Search Neovim help docs          |
| `<Space>fr` | Recent files                     |
| `<Space>fs` | Grep word under cursor           |

Inside the picker: `Ctrl+n`/`Ctrl+p` to navigate, `Enter` to open, `Ctrl+x` for horizontal split, `Ctrl+v` for vertical split, `Esc` to close.

**In-picker mode cycle:** `Ctrl+i` (= Tab) cycles through three search modes — works in both `find_files` and `live_grep`. The current mode is shown in the prompt prefix. Query text is preserved on cycle. Resets to `[narrow]` when reopening the picker.

| Prompt prefix | What's excluded |
|---|---|
| `[narrow]` | Build dirs + test/spec files + lockfiles + openspec |
| `[+tests]` | Build dirs only (test files, lockfiles, openspec visible) |
| `[all]` | Nothing — ignores `.gitignore` too |

**Path-scoped grep** (via `telescope-live-grep-args.nvim`):

`<Space>fg` uses the `live_grep_args` extension, which lets you pass ripgrep flags directly in the prompt. With `auto_quoting` enabled, unquoted text is treated as a single search string — you must quote your search term before adding flags.

Workflow to scope grep to a directory:
1. Type your search term (e.g. `lifecycle`)
2. Press `Ctrl+g` — quotes the term and appends `--iglob **/`
3. Type the directory name and `/**` (e.g. `terraform/**`)
4. Result: `"lifecycle" --iglob **/terraform/**` — searches only in terraform dirs

| In-picker keymap | Description |
|---|---|
| `Ctrl+k` | Quote the current prompt (wrap in `"..."`) |
| `Ctrl+g` | Quote prompt + append `--iglob **/` (start typing a path) |
| `Ctrl+Space` | Freeze results and fuzzy-filter within them |

Glob auto-completion (patched in extension): a glob ending in a letter (not an extension like `.tf`) gets `*/**` appended automatically (`**/terraform` → `**/terraform*/**`). A glob ending in `/` gets `**` appended (`**/terraform/` → `**/terraform/**`). Incomplete globs (`*`, `**`, `**/`) skip rg execution entirely to avoid expensive full-project scans while typing.

Oil buffers also use this picker — `<Space>fg` from an oil buffer opens `live_grep_args` scoped to the current directory.

**Fuzzy search syntax** (requires `telescope-fzf-native`):

- `'word` — exact substring match
- `^word` — prefix match
- `word$` — suffix match
- `!word` — inverse match

### oil.nvim (`plugins/oil`)

File explorer that lets you edit your filesystem like a normal buffer. Press `-` to open the parent directory of the current file. From there:

- **Navigate:** Enter a directory to descend, `-` to go up
- **Create files:** Type a new filename on a blank line, then save (`:w`)
- **Delete files:** Delete a line and save
- **Rename files:** Edit the filename text and save
- **Move files:** Cut/paste lines between oil buffers and save

All changes are staged when you edit and applied when you save (`:w`). Press `q` to close without applying.

### octo.nvim (`plugins/octo`)

GitHub issues and PRs directly in Neovim. Requires `gh` CLI to be authenticated. Lazy-loaded on `:Octo` command.

| Keymap      | Description                                      |
| ----------- | ------------------------------------------------ |
| `<Space>op` | List PRs for current repo                        |
| `<Space>on` | Show notifications                               |
| `<Space>oc` | Checkout a PR by number                          |
| `<Space>ok` | PRs requesting your review (bots excluded)       |
| `<Space>ors` | Start a PR review                               |
| `<Space>orc` | Resume pending review                            |
| `<Space>ord` | Submit pending review comments                  |
| `<C-s>`      | Submit review comment (in submit popup)          |

Review keymaps (in the changed files panel and diff windows during a review):

| Keymap              | Context      | Description                              |
| ------------------- | ------------ | ---------------------------------------- |
| `<localleader><space>` | File panel | Toggle file viewed/unviewed              |
| `]u`                | File panel   | Next unviewed file                       |
| `[u`                | File panel   | Previous unviewed file                   |
| `]q`                | File panel   | Next changed file                        |
| `[q`                | File panel   | Previous changed file                    |
| `gf`                | File panel / Diff | Open file in a new tab (full buffer) |

Common commands:
| Command | Description |
|---------|-------------|
| `:Octo pr list` | List PRs for current repo |
| `:Octo pr checkout <number>` | Checkout a PR branch |
| `:Octo pr create` | Create a new PR |
| `:Octo issue list` | List issues |
| `:Octo issue create` | Create a new issue |
| `:Octo review start` | Start a PR review |
| `:Octo review submit` | Submit pending review comments |
| `:Octo review discard` | Discard the current review |
| `:Octo comment add` | Add a comment |
| `:Octo reviewer add <login>` | Add a reviewer |
| `:Octo reviewer remove <login>` | Remove a reviewer |
| `:Octo search <query>` | Search issues/PRs |
| `:Octo notification` | Show GitHub notifications |

Inside an Octo buffer: `<Space>ca` to add a comment, `<Space>cd` to delete, `<Space>la` to add a label.

### which-key.nvim (`plugins/which-key`)

Shows available keybindings in a popup when you pause after pressing the leader key. Groups are labeled so prefix families are easy to discover.

| Group  | Prefix     |
| ------ | ---------- |
| Buffer | `<Space>b` |
| Claude | `<Space>a` |
| Find   | `<Space>f` |
| Git    | `<Space>g` |
| Hunks  | `<Space>h` |
| LSP    | `<Space>l` |
| Tab    | `<Space>t` |
| Yank   | `<Space>y` |

Press `<Space>` in normal mode and wait ~500 ms to trigger the popup. Press `<Space>?` to show all buffer-local keymaps explicitly.

## Search

### Search within Selection

Visually select text, then search/replace only within that selection:

1. Enter visual mode: `v` (charwise), `V` (linewise), or `<C-v>` (blockwise)
2. Select the text to search in
3. Press `:` → command line auto-fills with `:'<,'>`
4. Type the search/replace command: `s/search_term/replacement/g`
5. Press `Enter`

The `'<,'>` range restricts the operation to the visual selection. Only matches within the selection are replaced.

Alternatively, use `:g/pattern/` to find all occurrences within the selection (command-line grep mode):

```
:'<,'>g/pattern/
```

This shows all matches in the selected range. Note: the `/` motion command searches the whole buffer regardless of selection — only `:` commands (substitute, global) respect visual-range bounds.

## Plugin Manager

[lazy.nvim](https://github.com/folke/lazy.nvim) — auto-bootstrapped on first launch. Plugins are loaded from `lua/plugins/`.
