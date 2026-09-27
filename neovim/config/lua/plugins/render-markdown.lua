if vim.g.vscode then return end

-- Lazy by filetype: render-markdown is only useful in markdown buffers
local loaded = false
local function setup()
  if loaded then return end
  loaded = true
  vim.pack.add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  }, { load = true, confirm = false })
  require('render-markdown').setup({
    heading = {
      icons = { '', '', '', '', '', '' },
    },
  })
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  once = true,
  callback = setup,
})
