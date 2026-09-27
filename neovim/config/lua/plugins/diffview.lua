if vim.g.vscode then return end

local is_git_ignored = function(filepath)
  vim.fn.system('git check-ignore -q ' .. vim.fn.shellescape(filepath))
  return vim.v.shell_error == 0
end

-- Render added/untracked files in a single full-width window instead of a
-- 2-pane diff whose left ("old") side is just an empty all-red buffer.
--
-- diffview ships a single-window layout called `diff1_plain` (the `Diff1`
-- class). Each file entry carries its own `layout`, and the view swaps the
-- on-screen windows based on the layout *class* of the entry you navigate to.
-- So if we flip the layout of added/untracked entries to `Diff1` up front,
-- diffview handles the window juggling for us — modified files keep the normal
-- 2-pane diff, added files get the whole editor.
-- Flip a single entry's layout to the single-window `Diff1` if it's an added/
-- untracked file. Returns true if it actually converted (so callers know the
-- on-screen layout needs a re-render). Pure data change — no window juggling.
local convert_entry_to_single = function(entry)
  local ok, Diff1 = pcall(function()
    return require('diffview.scene.layouts.diff_1').Diff1
  end)
  if not ok or not entry then
    return false
  end
  -- "A" = staged add, "?" = untracked. Both have an empty old side.
  local is_added = entry.status == 'A' or entry.status == '?'
  if is_added and entry.layout and not entry.layout:instanceof(Diff1) then
    entry:convert_layout(Diff1)
    return true
  end
  return false
end

local convert_added_to_single = function(view)
  pcall(function()
    local files = view and view.files
    if not files then
      return
    end

    local current_changed = false
    for _, set in ipairs { files.working or {}, files.staged or {} } do
      for _, entry in ipairs(set) do
        if convert_entry_to_single(entry) and entry == view.cur_entry then
          current_changed = true
        end
      end
    end

    -- The currently-displayed file was already drawn with the old layout, so
    -- ask the view to re-render it with the freshly-converted single window.
    if current_changed and view.cur_entry then
      view:set_file(view.cur_entry, false)
    end
  end)
end

-- Tracks which file entries the user has explicitly opened via <cr>. diffview
-- auto-opens the first entry when a view opens, so `view.cur_entry` alone can't
-- tell "already showing" from "the user pressed enter on this". Weak keys so
-- entries can be GC'd with their view. Used to make the FIRST <cr> on any file
-- always stay in the panel, and only a SECOND <cr> focus the diff.
local cr_activated = setmetatable({}, { __mode = 'k' })

-- Find the window currently displaying the view's file panel (its window id
-- isn't reliably exposed and can go stale, so we look it up by buffer).
local find_panel_win = function(view)
  local pbuf = view.panel and view.panel.bufid
  if not pbuf then
    return nil
  end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == pbuf then
      return w
    end
  end
end

-- Open a file entry from the panel.
--   focus=false → open but keep the cursor in the panel
--   focus=true  → open and move the cursor into the diff
--
-- The catch: opening a file whose layout *class* differs from the one on screen
-- (e.g. switching from a modified file's 2-pane diff to an added file's single
-- window) makes diffview tear down and recreate the diff windows. The recreation
-- runs `vsp`, which leaves nvim's *current window* inside the new diff pane —
-- and `set_file(focus=false)` never restores panel focus. (Same-class opens just
-- reuse windows, so they don't drift.) To keep `focus=false` honest regardless
-- of layout, we register a one-shot `files_opened` listener (fired when the
-- layout finishes drawing) that snaps the cursor back to the panel.
local open_entry = function(view, item, focus)
  convert_entry_to_single(item)
  cr_activated[item] = true

  if not focus and item.layout and item.layout.emitter then
    item.layout.emitter:once('files_opened', function()
      local pwin = find_panel_win(view)
      if pwin then
        pcall(vim.api.nvim_set_current_win, pwin)
      end
    end)
  end

  view:set_file(item, focus)
end

local update_left_pane = function()
  pcall(function()
    local lib = require 'diffview.lib'
    local view = lib.get_current_view()
    if view then
      view:update_files()
      convert_added_to_single(view)
    end
  end)
end

require('custom.directory-watcher').registerOnChangeHandler('diffview', function(filepath, events)
  local is_in_dot_git_dir = filepath:match '/%.git/' or filepath:match '^%.git/'

  if is_in_dot_git_dir or not is_git_ignored(filepath) then
    update_left_pane()
  end
end)

vim.api.nvim_create_autocmd('FocusGained', {
  callback = update_left_pane,
})

-- Lock the two diff panes together vertically AND by cursor line.
--
-- `:diffthis` (which diffview runs on each pane) sets 'scrollbind' but not
-- 'cursorbind'. scrollbind only ties the *viewport*; cursorbind ties the
-- *cursor line*, so moving with j/k in one pane walks the other pane's cursor
-- down the matching line. Combined with 'diffopt+=filler' (already set in
-- init.lua) the panes stay aligned even where one side has added/removed lines.
--
-- OptionSet on 'diff' fires whenever a window enters or leaves diff mode, so
-- this catches diffview's panes as they're created without us hunting for them.
vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'diff',
  callback = function()
    vim.wo.cursorbind = vim.v.option_new == '1'
  end,
})

vim.pack.add({
  'https://github.com/sindrets/diffview.nvim',
}, { load = true, confirm = false })

require('diffview').setup({
  default_args = {
    DiffviewOpen = { '--imply-local' },
  },
  hooks = {
    view_opened = function(view)
      -- view_opened fires while `git status` is still loading async, so the
      -- file lists are usually empty here — a convert now is a no-op. The
      -- real conversion happens on `files_updated`, which the view emits the
      -- moment the status data lands. We attach that listener once per view.
      convert_added_to_single(view)
      pcall(function()
        view.emitter:on('files_updated', function()
          convert_added_to_single(view)
        end)
      end)
    end,
  },
  keymaps = {
    disable_defaults = false,
    view = {
      { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
    },
    file_panel = {
      { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
      -- Two-stage <cr>: first press opens the diff but keeps the cursor in
      -- the file panel; pressing <cr> again on the already-open file jumps
      -- the cursor into the diff window.
      --
      -- We also convert added/untracked entries to the single-window layout
      -- HERE, the instant they're opened. The view_opened hook and the
      -- directory watcher only catch files that already exist when they run,
      -- and git status loads async — so a freshly-selected added file would
      -- otherwise flash the 2-pane layout until the next watcher tick. This
      -- makes the conversion synchronous with opening, so no delay.
      --
      -- diffview's two built-in open actions are `select_entry`
      -- (= set_file(item, false), open without focus) and `focus_entry`
      -- (= set_file(item, true), open + focus). We pick between them based on
      -- whether the entry under the cursor is already the current entry.
      {
        'n',
        '<cr>',
        function()
          local view = require('diffview.lib').get_current_view()
          if not view or not view.panel:is_open() then
            return
          end
          local item = view.panel:get_item_at_cursor()
          if not item then
            return
          end
          -- Directory rows expose a `collapsed` boolean — toggle the fold.
          if type(item.collapsed) == 'boolean' then
            view.panel:toggle_item_fold(item)
            return
          end
          -- Focus the diff only when this file is already on-screen AND the
          -- user previously opened it with <cr> (not just diffview's auto-
          -- open of the first entry). Otherwise: open + stay in the panel.
          local focus = view.cur_entry == item and cr_activated[item] == true
          open_entry(view, item, focus)
        end,
        { desc = 'Open entry (stay in panel); focus diff if already open' },
      },
      -- o / l: plain open (stay in panel), but convert added files first so
      -- they don't flash the 2-pane layout (same reason as <cr> above).
      {
        'n',
        'o',
        function()
          local view = require('diffview.lib').get_current_view()
          if not view or not view.panel:is_open() then
            return
          end
          local item = view.panel:get_item_at_cursor()
          if not item then
            return
          end
          if type(item.collapsed) == 'boolean' then
            view.panel:toggle_item_fold(item)
            return
          end
          open_entry(view, item, false)
        end,
        { desc = 'Open entry (stay in panel)' },
      },
    },
    file_history_panel = {
      { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
    },
  },
})
