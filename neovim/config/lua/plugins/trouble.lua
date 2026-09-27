if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/folke/trouble.nvim',
}, { load = true, confirm = false })

local lsp_keys = {
  ['<cr>'] = {
    action = function(self, ctx)
      if ctx.item then
        self:jump(ctx.item)
        self:close()
      elseif ctx.node then
        self:fold(ctx.node, { action = 'toggle', recursive = false })
      end
    end,
    desc = 'Fold or jump',
  },
  ['<c-x>'] = 'jump_split_close',
  ['<c-v>'] = 'jump_vsplit_close',
  ['<S-tab>'] = {
    action = function(self)
      local r = self.renderer
      if r.foldlevel and r.foldlevel <= 2 then
        self:fold_level({ level = 1000 })
      else
        self:fold_level({ level = 2 })
      end
    end,
    desc = 'Toggle collapse all to files',
  },
  ['<c-t>'] = {
    action = function(self, ctx)
      if not ctx.item then return end
      local item = ctx.item
      item.buf = item.buf or vim.fn.bufadd(item.filename)
      if not vim.api.nvim_buf_is_loaded(item.buf) then vim.fn.bufload(item.buf) end
      if not vim.bo[item.buf].buflisted then vim.bo[item.buf].buflisted = true end
      self:close()
      vim.cmd('tabnew')
      vim.api.nvim_win_set_buf(0, item.buf)
      vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
      vim.cmd('norm! zzzv')
    end,
    desc = 'Open in new tab',
  },
}

local lsp_mode = {
  win = { type = 'split', position = 'bottom' },
  keys = lsp_keys,
}

require('trouble').setup({
  focus = true,
  win = { type = 'float' },
  keys = {
    ['<cr>'] = 'jump_close',
    ['<tab>'] = 'fold_toggle',
    ['<esc>'] = 'close',
  },
  modes = {
    diagnostics = {
      win = { type = 'split', position = 'bottom' },
    },
    qflist = {
      win = { type = 'split', position = 'bottom' },
    },
    lsp_base = {
      format = '{text:ts} {pos}',
      formatters = {
        file_count = function(ctx)
          local n = ctx.node:width()
          if n == 0 then return end
          return { text = n == 1 and '1 file' or (n .. ' files'), hl = 'Comment' }
        end,
      },
    },
    lsp_references = vim.tbl_deep_extend('force', lsp_mode, {
      title = '{hl:Title}References{hl} {count} ({file_count})',
    }),
    lsp_implementations = vim.tbl_deep_extend('force', lsp_mode, {
      title = '{hl:Title}Implementations{hl} {count} ({file_count})',
    }),
  },
})

vim.keymap.set('n', '<leader>tt', function()
  require('trouble').toggle({ mode = 'diagnostics' })
end, { desc = 'Toggle diagnostics panel' })
