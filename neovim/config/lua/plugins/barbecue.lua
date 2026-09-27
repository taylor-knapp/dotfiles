if vim.g.vscode then return end

-- nvim-navic reads LSP document symbols for the > foo > bar breadcrumb trail
vim.pack.add({
  'https://github.com/SmiteshP/nvim-navic',
  'https://github.com/nvim-tree/nvim-web-devicons',
  { src = 'https://github.com/utilyre/barbecue.nvim', name = 'barbecue' },
}, { load = true, confirm = false })

require('barbecue').setup({
  attach_navic = true,
  show_modified = true,
  create_autocmd = true,
  exclude_filetypes = { 'netrw', 'toggleterm', 'oil' },
})
