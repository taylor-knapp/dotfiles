if vim.g.vscode then return end

-- Async organize-imports. Calls `done` exactly once — no client, error, or empty
-- result all still fire it — so callers can chain the next step without racing.
--
-- typescript-tools does NOT expose organize-imports via `textDocument/codeAction`;
-- requesting `source.organizeImports` there returns unrelated refactor actions.
-- It uses the custom method `typescriptTools/organizeImports`, whose result IS the
-- workspace edit, and it hardcodes utf-8 when applying it (see the plugin's
-- custom_handlers.lua). Other servers (vtsls, ts_ls) use the standard codeAction
-- route, so both paths are handled.
--
-- Mode "SortAndCombine" merges same-source imports without deleting unused ones;
-- "All" would also strip unused imports on every save.
local function organize_imports(bufnr, done)
  local ts = vim.lsp.get_clients({ bufnr = bufnr, name = 'typescript-tools' })[1]
  if ts then
    ts:request('typescriptTools/organizeImports', {
      file = vim.api.nvim_buf_get_name(bufnr),
      mode = 'SortAndCombine',
    }, function(err, result)
      if not err and result and result.changes then
        vim.lsp.util.apply_workspace_edit(result, 'utf-8')
      end
      done()
    end, bufnr)
    return
  end

  local client = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/codeAction' })[1]
  if not client then return done() end

  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  params.context = { only = { 'source.organizeImports', 'source.organizeImports.ts' }, diagnostics = {} }

  client:request('textDocument/codeAction', params, function(_, result)
    for _, r in pairs(result or {}) do
      -- Filter client-side: some servers ignore the `only` context filter.
      if r.edit and vim.startswith(r.kind or '', 'source.organizeImports') then
        vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
      end
    end
    done()
  end, bufnr)
end

vim.pack.add({
  'https://github.com/stevearc/conform.nvim',
}, { load = true, confirm = false })

local conform = require('conform')

conform.setup({
  formatters_by_ft = {
    typescript = { 'prettier', 'biome', stop_after_first = true },
    typescriptreact = { 'prettier', 'biome', stop_after_first = true },
    javascript = { 'prettier', 'biome', stop_after_first = true },
    javascriptreact = { 'prettier', 'biome', stop_after_first = true },
    json = { 'prettier', 'biome', stop_after_first = true },
    lua = { 'stylua' },
    markdown = { 'prettier', stop_after_first = true },
  },
})

-- Organize imports, then format, then write once. All after the write lands, so
-- `:w` returns immediately. Sequential rather than parallel: both steps edit the
-- buffer, so overlapping them would let one clobber the other's edits.
local function fixup(bufnr, cb)
  organize_imports(bufnr, function()
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    conform.format({ async = true, lsp_format = 'fallback', bufnr = bufnr }, function(err)
      if not err and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
        vim.api.nvim_buf_call(bufnr, function() vim.cmd('noautocmd write') end)
      end
      if cb then cb() end
    end)
  end)
end

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { '*.ts', '*.tsx', '*.js', '*.jsx', '*.lua', '*.json', '*.md' },
  callback = function(args) fixup(args.buf) end,
})

-- Same pipeline on demand, for buffers/filetypes the autocmd doesn't cover.
vim.keymap.set('n', '<leader>lf', function()
  fixup(vim.api.nvim_get_current_buf())
end, { desc = 'Organize imports + format' })
