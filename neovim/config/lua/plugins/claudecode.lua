if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/folke/snacks.nvim',
  'https://github.com/coder/claudecode.nvim',
}, { load = true, confirm = false })

require('claudecode').setup({
  terminal = {
    provider = 'none',
  },
  -- Narrow window so nono can allow just these localhost ports (nono/profiles/agent-base.jsonc open_port_range).
  port_range = { min = 10000, max = 10999 },
})

vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'Add buffer to Claude' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Send selection to Claude' })
