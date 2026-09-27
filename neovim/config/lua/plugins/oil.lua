if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/stevearc/oil.nvim',
}, { load = true, confirm = false })

require('oil').setup({
  keymaps = {
    ['<C-t>'] = false,
    ['<leader>fg'] = function()
      local dir = require('oil').get_current_dir()
      require('telescope').extensions.live_grep_args.live_grep_args({ search_dirs = { dir } })
    end,
  },
  view_options = {
    show_hidden = true,
  },
  win_options = {
    wrap = true,
  },
})

vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = 'oil://*',
  callback = function()
    local dir = require('oil').get_current_dir()
    if not dir then return end
    dir = dir:gsub('/$', '')
    local cwd = vim.fn.getcwd()
    local relative
    if dir:sub(1, #cwd) == cwd then
      relative = dir:sub(#cwd + 2)
    end
    local parts
    if relative and relative ~= '' then
      parts = vim.split(relative, '/', { plain = true, trimempty = true })
    else
      parts = vim.split(vim.fn.fnamemodify(dir, ':~'), '/', { plain = true, trimempty = true })
    end
    local sep = '%#BarbecueSeparator# > %#BarbecueDirname#'
    vim.wo.winbar = '%#BarbecueDirname#' .. table.concat(parts, sep)
  end,
})
