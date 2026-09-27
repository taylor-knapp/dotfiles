-- Build hooks: run after install/update
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'telescope-fzf-native.nvim' and
       (ev.data.kind == 'install' or ev.data.kind == 'update') then
      vim.system({ 'make' }, { cwd = ev.data.path })
    end
  end,
})

-- Load order matters: theme first, then core deps, then features
require('plugins.onedark')
require('plugins.treesitter')
require('plugins.blink')
require('plugins.lsp')
require('plugins.telescope')
require('plugins.oil')
require('plugins.trouble')
require('plugins.diffview')
require('plugins.conform')
require('plugins.gitsigns')
require('plugins.which-key')
require('plugins.bufferline')
require('plugins.barbecue')
require('plugins.flash')
require('plugins.gitlinker')
require('plugins.render-markdown')
require('plugins.fugitive')
require('plugins.octo')
require('plugins.claudecode')
require('plugins.neotest')
require('plugins.copilot')
