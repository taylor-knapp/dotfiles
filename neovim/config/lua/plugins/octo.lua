if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/pwntester/octo.nvim',
}, { load = true, confirm = false })

require('octo').setup({
  mappings = {
    submit_win = {
      comment_review = { lhs = '<C-s>', desc = 'comment review' },
    },
  },
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'octo_panel',
  callback = function(ev)
    vim.keymap.set('n', 'gf', function()
      local review = require('octo.reviews').get_current_review()
      if not review then return end
      local file = review.layout.file_panel:get_file_at_cursor()
      if not file then return end
      local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
      local full_path = git_root .. '/' .. file.path
      if vim.fn.filereadable(full_path) == 1 then
        vim.cmd 'tabnew'
        vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
      else
        vim.notify('File not found: ' .. file.path, vim.log.levels.WARN)
      end
    end, { buffer = ev.buf, desc = 'Open file in full buffer' })
  end,
})

local function open_review_file_in_tab(bufname)
  local path = bufname:match '/file/[A-Z]+/(.*)'
  if not path then return end
  local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
  local full_path = git_root .. '/' .. path
  if vim.fn.filereadable(full_path) == 1 then
    vim.cmd 'tabnew'
    vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
  else
    vim.notify('File not found: ' .. path, vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(ev)
    local bufname = vim.api.nvim_buf_get_name(ev.buf)

    if bufname:match '^octo://' then
      local win = vim.api.nvim_get_current_win()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_option_value('wrap', true, { win = win, scope = 'local' })
          vim.api.nvim_set_option_value('linebreak', true, { win = win, scope = 'local' })
        end
      end)

      if bufname:match '/review/.*/file/' then
        vim.keymap.set('n', 'gf', function()
          open_review_file_in_tab(vim.api.nvim_buf_get_name(0))
        end, { buffer = ev.buf, desc = 'Open file in full buffer' })
      end
    end
  end,
})

vim.keymap.set('n', '<leader>op', '<cmd>Octo pr list<cr>', { desc = 'PR list' })
vim.keymap.set('n', '<leader>on', '<cmd>Octo notification<cr>', { desc = 'Notifications' })
vim.keymap.set('n', '<leader>oc', ':Octo pr checkout ', { desc = 'PR checkout' })
vim.keymap.set('n', '<leader>ok',
  '<cmd>Octo search is:pr is:open review-requested:@me -author:renovate[bot] -author:dependabot[bot] -author:ct-changesets[bot]<cr>',
  { desc = 'PRs to review' })
vim.keymap.set('n', '<leader>orc', '<cmd>Octo review resume<cr>', { desc = 'Review continue' })
vim.keymap.set('n', '<leader>ors', '<cmd>Octo review start<cr>', { desc = 'Review start' })
vim.keymap.set('n', '<leader>ord', '<cmd>Octo review submit<cr>', { desc = 'Review submit' })
