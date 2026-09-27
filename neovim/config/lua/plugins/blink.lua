if vim.g.vscode then return end

-- emoji.nvim loaded first: blink uses it as a source, and it has a telescope extension
vim.pack.add({
  'https://github.com/allaman/emoji.nvim',
  'https://github.com/saghen/blink.compat',
  'https://github.com/Kaiser-Yang/blink-cmp-git',
  {
    src = 'https://github.com/saghen/blink.cmp',
    version = vim.version.range('>=1.0.0, <2.0.0'),
  },
}, { load = true, confirm = false })

require('emoji').setup({ enable_cmp_integration = true })

vim.keymap.set('n', '<leader>fe', '<cmd>Telescope emoji<cr>', { desc = 'Find emoji' })

require('blink.cmp').setup({
  keymap = {
    preset = 'default',
    ['<CR>'] = { 'accept', 'fallback' },
    -- Tab accepts the highlighted item; arrows (from the `default` preset)
    -- navigate. Falls back to a literal Tab when no menu is open.
    ['<Tab>'] = { 'accept', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
  },
  sources = {
    default = { 'lsp', 'path', 'buffer', 'emoji', 'git' },
    providers = {
      emoji = {
        module = 'blink.compat.source',
        name = 'emoji',
        transform_items = function(_, items)
          local kind = require('blink.cmp.types').CompletionItemKind.Text
          for _, item in ipairs(items) do
            item.kind = kind
          end
          return items
        end,
      },
      git = {
        module = 'blink-cmp-git',
        name = 'Git',
        opts = {},
        enabled = function()
          local ft = vim.bo.filetype
          return ft == 'octo' or ft == 'gitcommit' or vim.bo.syntax == 'octo'
        end,
      },
    },
  },
})
