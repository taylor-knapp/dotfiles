if vim.g.vscode then return end

vim.pack.add({
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/akinsho/bufferline.nvim',
}, { load = true, confirm = false })

require('bufferline').setup({
  options = {
    mode = 'buffers',
    diagnostics = 'nvim_lsp',
    show_buffer_close_icons = true,
    show_close_icon = false,
    separator_style = 'thin',
    offsets = {
      { filetype = 'oil', text = 'Files', highlight = 'Directory', separator = true },
    },
  },
})

vim.keymap.set('n', '<C-t>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer tab' })
vim.keymap.set('n', '<C-S-t>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer tab' })
vim.keymap.set('n', ']b', '<cmd>BufferLineCycleNext<cr>', { desc = 'Next buffer tab' })
vim.keymap.set('n', '[b', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Prev buffer tab' })
vim.keymap.set('n', '<leader>bp', '<cmd>BufferLinePick<cr>', { desc = '[B]uffer [P]ick' })
