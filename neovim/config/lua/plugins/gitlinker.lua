vim.pack.add({
  'https://github.com/linrongbin16/gitlinker.nvim',
}, { load = true, confirm = false })

require('gitlinker').setup()

vim.keymap.set({ 'n', 'v' }, '<leader>gy', '<cmd>GitLink<cr>', { desc = 'Copy git permalink' })
vim.keymap.set({ 'n', 'v' }, '<leader>gY', '<cmd>GitLink!<cr>', { desc = 'Open git permalink in browser' })
