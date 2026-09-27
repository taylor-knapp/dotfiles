-- Leader key (set before plugins load)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Reload the config on the fly
vim.keymap.set("n", "<leader>rs", function()
  vim.cmd('mapclear')
  vim.cmd('luafile ~/.config/nvim/init.lua')
end, { desc = "Reload config (clear maps)" })

-- Load plugins via vim.pack (Neovim 0.11+ built-in manager)
require('plugins')

-- Keystroke logger command (:KeyLog) — debug what bytes a key sends
require('custom.keylog')

-- Rounded border on all floats (Neovim 0.11+)
vim.o.winborder = 'rounded'

-- Load project-local .nvim.lua from the cwd. Each file must be approved with
-- `:trust` before it runs; Neovim stores path + content hash, so editing the
-- file re-prompts.
vim.o.exrc = true

-- Indentation: 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

-- Case-insensitive search unless uppercase is typed
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- VSCode owns line numbers, line wrap, autosave, file watching, buffer reload,
-- and scratch/picker UI when running under vscode-neovim. Skip those locally.
if not vim.g.vscode then
  vim.opt.number = true
  vim.opt.numberwidth = 1           -- still used for width calculation, statuscolumn overrides display
  vim.opt.statuscolumn = "%s%l    " -- %s = status, %l = line number (left-aligned), four spaces after
  vim.opt.relativenumber = false
  vim.opt.cursorline = true
  vim.opt.scrolloff = 10
  vim.opt.sidescrolloff = 10

  vim.opt.wrap = true
  vim.opt.linebreak = true

  vim.o.autowriteall = true
  vim.api.nvim_create_autocmd({ 'FocusLost', 'InsertLeave', 'TextChanged' }, {
    callback = function(ev)
      if vim.bo[ev.buf].buftype == '' and vim.bo[ev.buf].modifiable and vim.api.nvim_buf_get_name(ev.buf) ~= '' then
        vim.cmd 'silent! write'
      end
    end,
  })

  require('custom.directory-watcher').setup { path = vim.fn.getcwd() }
  require('custom.scratch')
  require('custom.hotreload').setup()
else
  require('custom.vscode')
end

-- Yank keymaps: copy code with file path context
local yank = require 'custom.yank'

vim.keymap.set('n', '<leader>ya', function()
  yank.yank_path(yank.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank [A]bsolute path to clipboard' })

vim.keymap.set('n', '<leader>yr', function()
  yank.yank_path(yank.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank [R]elative path to clipboard' })

vim.keymap.set('v', '<leader>ya', function()
  yank.yank_visual_with_path(yank.get_buffer_absolute(), 'absolute')
end, { desc = '[Y]ank visual with [A]bsolute path' })

vim.keymap.set('v', '<leader>yr', function()
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), 'relative')
end, { desc = '[Y]ank visual with [R]elative path' })

-- Reveal current file in macOS Finder (`open -R` selects the file in a Finder window)
vim.keymap.set('n', '<leader>of', function()
  local file = vim.fn.expand('%:p')
  if file == '' then
    vim.notify('No file in this buffer to reveal', vim.log.levels.WARN)
    return
  end
  vim.system({ 'open', '-R', file })
end, { desc = '[O]pen file in [F]inder' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', '<D-Left>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<D-Down>', '<C-w>j', { desc = 'Move to lower window' })
vim.keymap.set('n', '<D-Up>', '<C-w>k', { desc = 'Move to upper window' })
vim.keymap.set('n', '<D-Right>', '<C-w>l', { desc = 'Move to right window' })

-- Buffer navigation

vim.keymap.set('n', '<M-Left>', '<cmd>bprev<cr>', { desc = 'Move left one buffer' })
vim.keymap.set('n', '<M-Right>', '<cmd>bnext<cr>', { desc = 'Move right one buffer' })

-- Diff hunk navigation (opt+c / opt+shift+c)
--
-- In a vim diff window (vim.wo.diff == true), use the built-in ]c/[c, which
-- jumps between diff blocks. This covers diffview's diff panes. Everywhere
-- else, fall back to gitsigns hunk navigation.
--
-- Why two left-hand sides per direction: on macOS, holding Option and pressing
-- a letter emits a *composed character* (Option+c -> "ç", Option+Shift+C ->
-- "Ç") rather than the <M-c> key code — unless the terminal is configured to
-- send Option as Meta. tmux adds another layer that can swallow it. Mapping
-- both the <M-c> form and the literal ç makes the keymap fire no matter how
-- the keypress is delivered.
local function diff_next()
  if vim.wo.diff then
    vim.cmd 'normal! ]c'
  else
    local ok, gs = pcall(require, 'gitsigns')
    if ok then gs.next_hunk() end
  end
end
local function diff_prev()
  if vim.wo.diff then
    vim.cmd 'normal! [c'
  else
    local ok, gs = pcall(require, 'gitsigns')
    if ok then gs.prev_hunk() end
  end
end
for _, lhs in ipairs { '<A-c>', 'ç' } do
  vim.keymap.set('n', lhs, diff_next, { desc = 'Next diff change' })
end
for _, lhs in ipairs { '<A-C>', 'Ç' } do
  vim.keymap.set('n', lhs, diff_prev, { desc = 'Previous diff change' })
end

-- Toggle comment (opt+/)
vim.keymap.set('n', '<M-/>', 'gcc', { desc = 'Toggle comment', remap = true })
vim.keymap.set('v', '<M-/>', 'gc', { desc = 'Toggle comment', remap = true })
vim.keymap.set('i', '<M-/>', '<Esc>gcca', { desc = 'Toggle comment', remap = true })

-- Delete without yanking (_d, _dd, _dw, _x, etc.)
vim.keymap.set({ 'n', 'v' }, '_d', '"_d', { desc = 'Delete (no yank)' })
vim.keymap.set({ 'n', 'v' }, '_x', '"_x', { desc = 'Delete char (no yank)' })

-- Dedent in insert mode (S-Tab; blink's fallback routes here)
vim.keymap.set('i', '<S-Tab>', '<C-d>', { desc = 'Dedent in insert mode' })

-- Indent / dedent in normal and visual mode
vim.keymap.set('n', '<Tab>', '>>', { desc = 'Indent line' })
vim.keymap.set('n', '<S-Tab>', '<<', { desc = 'Dedent line' })
vim.keymap.set('v', '<Tab>', '>gv', { desc = 'Indent selection' })
vim.keymap.set('v', '<S-Tab>', '<gv', { desc = 'Dedent selection' })

-- <C-i> and <Tab> share the byte 0x09, so the <Tab> indent map above would
-- normally swallow <C-i>'s builtin jumplist-forward. On this machine they are
-- distinct because of an iTerm2 Key Binding: ^i -> Send escape sequence
-- ^[[105;5u (the kitty/CSI-u form of Ctrl+i). That binding is NOT in this repo
-- -- if it's lost, this mapping silently stops helping. See learning/03.
--
-- noremap is load-bearing: it resolves the RHS to the builtin <C-i> rather than
-- recursing into this mapping.
vim.keymap.set('n', '<C-i>', '<C-i>', { noremap = true, desc = 'Jumplist forward' })

-- Exit terminal mode with Escape
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Clear search highlights
vim.keymap.set('n', '<leader>nh', '<cmd>nohl<cr>', { desc = 'Clear search highlights' })

vim.keymap.set('n', '<leader>ghw', '<cmd>DiffviewOpen<cr>', { desc = '[G]it [H]istory [W]orking Directory' })
vim.keymap.set('n', '<leader>ghf', '<cmd>DiffviewFileHistory %<cr>', { desc = '[G]it [H]istory [F]ile' })
vim.keymap.set('n', '<leader>ghl', '<cmd>DiffviewFileHistory<cr>', { desc = '[G]it [H]istory [L]og' })

-- Search for the visual selection: yank it, then search for its contents.
-- <C-r>" pastes the just-yanked text (register ") into the search line; N
-- jumps back to the selection so the cursor doesn't move off it. Then use
-- cgn/dgn + `.` to change/delete each match and repeat, or `n` to skip.
vim.keymap.set('x', '//', 'y/<C-r>"<CR>N', { desc = 'Search visual selection' })

-- Search WITHIN the visual selection: leave visual mode (which sets the '< '>
-- marks and thus the \%V region) and open a search prefilled with \%V, the
-- built-in "inside the visual area" atom. Type your pattern after it and
-- matches are confined to the highlighted block. E.g. select a function body,
-- press <leader>/ , type `return` -> only returns in that body match.
vim.keymap.set('x', '<leader>/', '<Esc>/\\%V', { desc = 'Search within selection' })


-- ==========================================================================
-- Buffer hotkeys
-- ==========================================================================
-- Delete all buffers and leave an empty new buffer
vim.keymap.set('n', '<leader>ba', '<cmd>%bdelete<cr>', { desc = 'Delete [a]ll buffers' })

-- Buffer (vscode.lua remaps this to closeActiveEditor inside vscode-neovim)
if not vim.g.vscode then
  vim.keymap.set('n', '<leader>bd', '<cmd>bp | bd #<cr>', { desc = '[D]elete buffer' })

  -- Delete all buffers except current
  vim.api.nvim_create_user_command('Bo', function()
    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if buf.bufnr ~= vim.fn.bufnr() then
        vim.cmd('bdelete ' .. buf.bufnr)
      end
    end
  end, {})
  vim.keymap.set('n', '<leader>bo', '<cmd>Bo<cr>', { desc = 'Delete [o]ther buffers' })
end

-- Tabpages (distinct from bufferline buffer-tabs; see plugins/bufferline.lua)
vim.keymap.set('n', '<leader>tn', '<cmd>tabnew<cr>', { desc = 'New tabpage' })
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<cr>', { desc = 'Close tabpage' })

-- ==========================================================================
-- nvim options from radleylewis
-- https://github.com/radleylewis/nvim-lite/blob/master/init.lua
-- https://www.youtube.com/watch?v=lljs_7xB7Ps
-- ==========================================================================

vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"
vim.opt.showmatch = true
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.showmode = false
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""
vim.opt.synmaxcol = 300
vim.opt.fillchars = { eob = " " }

local undodir = vim.fn.stdpath('data') .. '/undodir'
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.undofile = true
vim.opt.undodir = undodir
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 50
vim.opt.autoread = true

vim.opt.hidden = true
vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start"
vim.opt.autochdir = false
vim.opt.iskeyword:append("-")
vim.opt.selection = "inclusive"
vim.opt.mouse = "a"
vim.opt.clipboard:append("unnamedplus")

-- NOTE: These helpers are not required with "unnamedplus", as they become the default behavior
-- Yank/paste to system clipboard via <Space>y / <Space>p
-- vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
-- vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p', { desc = 'Paste from system clipboard' })


vim.opt.modifiable = true
vim.opt.encoding = "utf-8"

vim.opt.guicursor =
"n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- these fold options only work with treesitter available at runtime
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.diffopt:append("linematch:60")
-- Keep both diff panes locked together while scrolling. 'scrollbind' is set
-- automatically by :diffthis on each diff window; 'scrollopt' controls *what*
-- gets bound. Default is "ver" only, so horizontal scrolling and cursor
-- position drift apart. "jump" re-syncs after a jump (search, gg, }) instead of
-- leaving one side offset forever.
vim.opt.scrollopt = "ver,hor,jump"
vim.opt.maxmempattern = 20000

vim.keymap.set("n", "n", "nzz", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzz", { desc = "Next search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
vim.keymap.set("x", "<leader>r", '"_dP', { desc = "Paste without yanking" })
vim.keymap.set({ "n", "x" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

-- herenow

-- ============================================================================
-- STATUSLINE
-- ============================================================================

-- Git branch function with caching and Nerd Font icon
local cached_branch = ""
local last_check = 0
local function git_branch()
  local now = vim.uv.now()
  if now - last_check > 5000 then -- Check every 5 seconds
    cached_branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
    last_check = now
  end
  if cached_branch ~= "" then
    return " \u{e725} " .. cached_branch .. " " -- nf-dev-git_branch
  end
  return ""
end

-- File type with Nerd Font icon
local function file_type()
  local ft = vim.bo.filetype
  local icons = {
    lua = "\u{e620} ",        -- nf-dev-lua
    python = "\u{e73c} ",     -- nf-dev-python
    javascript = "\u{e74e} ", -- nf-dev-javascript
    typescript = "\u{e628} ", -- nf-dev-typescript
    javascriptreact = "\u{e7ba} ",
    typescriptreact = "\u{e7ba} ",
    html = "\u{e736} ",     -- nf-dev-html5
    css = "\u{e749} ",      -- nf-dev-css3
    scss = "\u{e749} ",
    json = "\u{e60b} ",     -- nf-dev-json
    markdown = "\u{e73e} ", -- nf-dev-markdown
    vim = "\u{e62b} ",      -- nf-dev-vim
    sh = "\u{f489} ",       -- nf-oct-terminal
    bash = "\u{f489} ",
    zsh = "\u{f489} ",
    rust = "\u{e7a8} ",  -- nf-dev-rust
    go = "\u{e724} ",    -- nf-dev-go
    c = "\u{e61e} ",     -- nf-dev-c
    cpp = "\u{e61d} ",   -- nf-dev-cplusplus
    java = "\u{e738} ",  -- nf-dev-java
    php = "\u{e73d} ",   -- nf-dev-php
    ruby = "\u{e739} ",  -- nf-dev-ruby
    swift = "\u{e755} ", -- nf-dev-swift
    kotlin = "\u{e634} ",
    dart = "\u{e798} ",
    elixir = "\u{e62d} ",
    haskell = "\u{e777} ",
    sql = "\u{e706} ",
    yaml = "\u{f481} ",
    toml = "\u{e615} ",
    xml = "\u{f05c} ",
    dockerfile = "\u{f308} ", -- nf-linux-docker
    gitcommit = "\u{f418} ",  -- nf-oct-git_commit
    gitconfig = "\u{f1d3} ",  -- nf-fa-git
    vue = "\u{fd42} ",        -- nf-md-vuejs
    svelte = "\u{e697} ",
    astro = "\u{e628} ",
  }

  if ft == "" then
    return " \u{f15b} " -- nf-fa-file_o
  end

  return ((icons[ft] or " \u{f15b} ") .. ft)
end

-- File size with Nerd Font icon
local function file_size()
  local size = vim.fn.getfsize(vim.fn.expand("%"))
  if size < 0 then
    return ""
  end
  local size_str
  if size < 1024 then
    size_str = size .. "B"
  elseif size < 1024 * 1024 then
    size_str = string.format("%.1fK", size / 1024)
  else
    size_str = string.format("%.1fM", size / 1024 / 1024)
  end
  return " \u{f016} " .. size_str .. " " -- nf-fa-file_o
end

-- Mode indicators with Nerd Font icons
local function mode_icon()
  local mode = vim.fn.mode()
  local modes = {
    n = " \u{f121}  NORMAL",
    i = " \u{f11c}  INSERT",
    v = " \u{f0168} VISUAL",
    V = " \u{f0168} V-LINE",
    ["\22"] = " \u{f0168} V-BLOCK",
    c = " \u{f120} COMMAND",
    s = " \u{f0c5} SELECT",
    S = " \u{f0c5} S-LINE",
    ["\19"] = " \u{f0c5} S-BLOCK",
    R = " \u{f044} REPLACE",
    r = " \u{f044} REPLACE",
    ["!"] = " \u{f489} SHELL",
    t = " \u{f120} TERMINAL",
  }
  return modes[mode] or (" \u{f059} " .. mode)
end

_G.mode_icon = mode_icon
_G.git_branch = git_branch
_G.file_type = file_type
_G.file_size = file_size

vim.cmd([[
  highlight StatusLineBold gui=bold cterm=bold
]])

-- Function to change statusline based on window focus
local function setup_dynamic_statusline()
  vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
    callback = function()
      vim.opt_local.statusline = table.concat({
        "  ",
        "%#StatusLineBold#",
        "%{v:lua.mode_icon()}",
        "%#StatusLine#",
        " \u{e0b1} %f %h%m%r",  -- nf-pl-left_hard_divider
        "%{v:lua.git_branch()}",
        "\u{e0b1} ",            -- nf-pl-left_hard_divider
        "%{v:lua.file_type()}",
        "\u{e0b1} ",            -- nf-pl-left_hard_divider
        "%{v:lua.file_size()}",
        "%=",                   -- Right-align everything after this
        " \u{f017} %l:%c  %P ", -- nf-fa-clock_o for line/col
      })
    end,
  })
  vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })

  vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    callback = function()
      vim.opt_local.statusline = "  %f %h%m%r \u{e0b1} %{v:lua.file_type()} %=  %l:%c   %P "
    end,
  })
end

setup_dynamic_statusline()

-- Telescope picker: hide the statusline entirely. A blank window-local
-- statusline still leaves a dark bar drawn, so instead drop `laststatus` to 0
-- (no statusline row at all) while the picker is open, then restore it.
local saved_laststatus = vim.o.laststatus
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopePrompt",
  callback = function(ev)
    saved_laststatus = vim.o.laststatus
    vim.o.laststatus = 0
    vim.api.nvim_create_autocmd("BufWinLeave", {
      buffer = ev.buf,
      once = true,
      callback = function()
        vim.o.laststatus = saved_laststatus
      end,
    })
  end,
})

-- Telescope pickers that jump via `:buffer` (oldfiles, live_grep) leave the
-- empty `[No Name]` buffer behind as the alternate instead of reusing it the
-- way `:edit` does. Wipe it once we've landed on a real file.
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(ev)
    -- Only act once we've landed on a real file.
    if vim.api.nvim_buf_get_name(ev.buf) == '' then
      return
    end
    -- The leftover is always the alternate buffer (`#` in `:ls`), so check that
    -- one rather than scanning the whole buffer list.
    local alt = vim.fn.bufnr('#')
    if alt == -1 or alt == ev.buf or not vim.api.nvim_buf_is_valid(alt) then
      return
    end
    if
        vim.bo[alt].buflisted
        and vim.bo[alt].buftype == ''
        and not vim.bo[alt].modified
        and vim.api.nvim_buf_get_name(alt) == ''
        and vim.api.nvim_buf_line_count(alt) == 1
        and vim.api.nvim_buf_get_lines(alt, 0, 1, false)[1] == ''
        and vim.fn.win_findbuf(alt)[1] == nil
    then
      vim.api.nvim_buf_delete(alt, {})
    end
  end,
})
