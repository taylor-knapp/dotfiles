if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/folke/snacks.nvim',
  'https://github.com/coder/claudecode.nvim',
}, { load = true, confirm = false })

require('claudecode').setup({
  terminal = {
    provider = 'none',
  },
})

vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'Add buffer to Claude' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send selection to Claude' })
