vim.pack.add({
  'https://github.com/folke/flash.nvim',
}, { load = true, confirm = false })

require('flash').setup({
  search = {
    mode = 'search',
  },
})

vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash treesitter' })
vim.keymap.set('o', 'r', function() require('flash').remote() end, { desc = 'Remote flash' })
vim.keymap.set('c', '<C-s>', function() require('flash').toggle() end, { desc = 'Toggle flash search' })
