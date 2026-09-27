if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/folke/which-key.nvim',
}, { load = true, confirm = false })

require('which-key').setup({
  spec = {
    { '<leader>a', group = 'Claude' },
    { '<leader>b', group = 'Buffer' },
    { '<leader>f', group = 'Find' },
    { '<leader>g', group = 'Git' },
    { '<leader>h', group = 'Hunks' },
    { '<leader>l', group = 'LSP' },
    { '<leader>s', group = 'Scratch' },
    { '<leader>t', group = 'Tab' },
    { '<leader>y', group = 'Yank' },
  },
})

vim.keymap.set('n', '<leader>?', function()
  require('which-key').show({ global = false })
end, { desc = 'Show buffer keymaps' })
