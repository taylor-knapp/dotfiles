if vim.g.vscode then return end

-- Lazy by event: gitsigns is only useful in git-tracked buffers.
-- Load once on first BufReadPre; gitsigns auto-attaches to all subsequent buffers.
local function setup()
  vim.pack.add({
    'https://github.com/lewis6991/gitsigns.nvim',
  }, { load = true, confirm = false })

  require('gitsigns').setup({
    current_line_blame = true,
    current_line_blame_opts = {
      delay = 500,
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- Both branches return '<Ignore>' (no replayed keys) and do the actual
      -- jump from a scheduled callback. In a diff window we used to `return
      -- ']c'` to delegate to the built-in motion, but that replayed string
      -- got re-captured by which-key's `]` trigger and never reached the
      -- built-in — so `]c` silently did nothing in diff panes (e.g.
      -- diffview). Calling `normal! ]c` directly (the `!` = no remapping)
      -- fires the built-in change-jump and which-key never sees it.
      map('n', ']c', function()
        if vim.wo.diff then
          vim.schedule(function() vim.cmd 'normal! ]c' end)
        else
          vim.schedule(gs.next_hunk)
        end
        return '<Ignore>'
      end, 'Next hunk')

      map('n', '[c', function()
        if vim.wo.diff then
          vim.schedule(function() vim.cmd 'normal! [c' end)
        else
          vim.schedule(gs.prev_hunk)
        end
        return '<Ignore>'
      end, 'Prev hunk')

      local function close_floats()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(win).relative ~= '' then
            pcall(vim.api.nvim_win_close, win, true)
          end
        end
      end

      local function exit_hunk_mode()
        close_floats()
        pcall(vim.keymap.del, 'n', '<Down>', { buffer = bufnr })
        pcall(vim.keymap.del, 'n', '<Up>', { buffer = bufnr })
        pcall(vim.keymap.del, 'n', '<Esc>', { buffer = bufnr })
      end

      local function enter_hunk_mode()
        gs.preview_hunk()

        vim.keymap.set('n', '<Down>', function()
          close_floats()
          gs.next_hunk()
          vim.schedule(gs.preview_hunk)
        end, { buffer = bufnr, desc = 'Next hunk (hunk mode)' })

        vim.keymap.set('n', '<Up>', function()
          close_floats()
          gs.prev_hunk()
          vim.schedule(gs.preview_hunk)
        end, { buffer = bufnr, desc = 'Prev hunk (hunk mode)' })

        vim.keymap.set('n', '<Esc>', function()
          exit_hunk_mode()
        end, { buffer = bufnr, desc = 'Exit hunk mode' })
      end

      map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
      map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')
      map('v', '<leader>hs', function()
        gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, 'Stage hunk')
      map('v', '<leader>hr', function()
        gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, 'Reset hunk')
      map('n', '<leader>hp', enter_hunk_mode, 'Preview hunk (hunk mode)')
      map('n', '<leader>hb', function()
        gs.blame_line { full = true }
      end, 'Blame line')
      map('n', '<leader>hd', gs.diffthis, 'Diff this')
    end,
  })
end

vim.api.nvim_create_autocmd('BufReadPre', {
  once = true,
  callback = setup,
})
