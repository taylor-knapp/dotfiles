vim.pack.add({
  'https://github.com/nvim-treesitter/nvim-treesitter',
}, { load = true, confirm = false })

-- Install parsers for languages we use (replaces build = ':TSUpdate')
pcall(require('nvim-treesitter.install').install, { 'typescript', 'tsx', 'lua', 'javascript', 'json', 'markdown' })

-- Start treesitter highlighting for every buffer
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
