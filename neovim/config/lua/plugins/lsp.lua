if vim.g.vscode then return end

-- Load the LSP stack; schemastore first (needed for jsonls config below).
-- plenary is a typescript-tools dependency.
vim.pack.add({
  'https://github.com/b0o/schemastore.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
  'https://github.com/mason-org/mason-lspconfig.nvim',
  'https://github.com/pmizio/typescript-tools.nvim',
}, { load = true, confirm = false })

-- Configure servers before mason-lspconfig enables them.
-- vim.lsp.config() stores config; it applies when the server starts.
local capabilities = require('blink.cmp').get_lsp_capabilities()

vim.lsp.config('lua_ls', { capabilities = capabilities })

vim.lsp.config('jsonls', {
  capabilities = capabilities,
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
})

vim.diagnostic.config({
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many', max_width = 200, wrap = false },
})

local diag_float_win = nil

local function open_diag_float()
  local _, win = vim.diagnostic.open_float()
  diag_float_win = win
  if win then
    local float_buf = vim.api.nvim_win_get_buf(win)
    vim.keymap.set('n', '<Esc>', function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, false)
      end
      diag_float_win = nil
    end, { buffer = float_buf, desc = 'Close diagnostic float' })
  end
end

local function jump_and_open(opts)
  vim.diagnostic.jump(opts)
  vim.schedule(open_diag_float)
end

local function get_visual_selection()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
  local s = vim.api.nvim_buf_get_mark(0, '<')
  local e = vim.api.nvim_buf_get_mark(0, '>')
  local text = vim.api.nvim_buf_get_text(0, s[1] - 1, s[2], e[1] - 1, e[2] + 1, {})
  return table.concat(text, '\n')
end

local function grep_to_trouble(term)
  vim.system(
    { 'rg', '--vimgrep', '--type', 'ts', '--word-regexp', '--', term },
    { text = true },
    vim.schedule_wrap(function(result)
      local output = result.stdout or ''
      if output == '' then
        vim.notify('No results for: ' .. term, vim.log.levels.INFO)
        return
      end
      local lines = vim.split(output, '\n', { trimempty = true })
      vim.fn.setqflist({}, ' ', { lines = lines, efm = '%f:%l:%c:%m', title = 'grep: ' .. term })
      require('trouble').open({ mode = 'qflist' })
    end)
  )
end

-- Buffer-local keymaps registered whenever an LSP server connects
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }

    vim.keymap.set('n', 'gd', function()
      vim.lsp.buf.definition({
        on_list = function(options)
          if vim.tbl_isempty(options.items) then
            vim.notify('No definition found', vim.log.levels.WARN)
            return
          end
          vim.fn.setqflist({}, ' ', options)
          vim.cmd('cfirst')
        end,
      })
    end, { buffer = args.buf, desc = 'Go to definition' })

    vim.keymap.set('n', 'gi', function()
      require('trouble').open({ mode = 'lsp_implementations' })
    end, { buffer = args.buf, desc = 'Implementation → Trouble' })

    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, { buffer = args.buf, desc = 'Code actions' })

    local function open_refs()
      require('trouble').open({ mode = 'lsp_references' })
    end
    vim.keymap.set('n', 'grr', open_refs, { buffer = args.buf, desc = 'LSP references → Trouble' })
    vim.keymap.set('n', '<D-b>', open_refs, { buffer = args.buf, desc = 'LSP references → Trouble' })

    vim.keymap.set('n', '<D-S-b>', function()
      grep_to_trouble(vim.fn.expand('<cword>'))
    end, { buffer = args.buf, desc = 'Grep word → Trouble' })
    vim.keymap.set('v', '<D-S-b>', function()
      grep_to_trouble(get_visual_selection())
    end, { buffer = args.buf, desc = 'Grep selection → Trouble' })

    vim.keymap.set('n', '<leader>ld', open_diag_float, { buffer = args.buf, desc = 'Show diagnostic' })

    vim.keymap.set('n', '<Esc>', function()
      if diag_float_win and vim.api.nvim_win_is_valid(diag_float_win) then
        vim.api.nvim_win_close(diag_float_win, false)
        diag_float_win = nil
      else
        vim.cmd('nohlsearch')
      end
    end, { buffer = args.buf, desc = 'Close diagnostic float' })

    vim.keymap.set('n', ']d', function() jump_and_open({ count = 1 }) end,
      { buffer = args.buf, desc = 'Next diagnostic' })
    vim.keymap.set('n', '[d', function() jump_and_open({ count = -1 }) end,
      { buffer = args.buf, desc = 'Prev diagnostic' })
    vim.keymap.set('n', ']e', function() jump_and_open({ count = 1, severity = vim.diagnostic.severity.ERROR }) end,
      { buffer = args.buf, desc = 'Next error' })
    vim.keymap.set('n', '[e', function() jump_and_open({ count = -1, severity = vim.diagnostic.severity.ERROR }) end,
      { buffer = args.buf, desc = 'Prev error' })
    vim.keymap.set('n', '<leader>te',
      function() jump_and_open({ count = 1, severity = vim.diagnostic.severity.ERROR }) end,
      { buffer = args.buf, desc = 'Next error with diagnostic' })
  end,
})

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = { 'lua_ls', 'jsonls', 'eslint' },
  automatic_enable = { exclude = { 'ts_ls', 'vtsls' } },
})

-- typescript-tools registers its own FileType autocmd, so tsserver still only
-- spawns for TS/JS buffers. No manual lazy-loading needed.
require('typescript-tools').setup({
  capabilities = capabilities,
  on_attach = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  settings = {
    tsserver_max_memory = 4096,
  },
})

vim.lsp.config('eslint', { capabilities = capabilities })
