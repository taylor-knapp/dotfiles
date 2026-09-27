if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/tpope/vim-fugitive',
}, { load = true, confirm = false })
