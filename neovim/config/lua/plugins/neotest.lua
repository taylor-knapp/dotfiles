if vim.g.vscode then return end

-- Deferred: neotest costs ~21ms to load and configure, and is only needed
-- once you actually run a test. vim.pack has no built-in lazy triggers, so
-- the first <leader>t* press installs and sets it up, then runs the action.
local loaded = false

local function neotest()
  if not loaded then
    vim.pack.add({
      'https://github.com/nvim-neotest/neotest',
      'https://github.com/nvim-neotest/nvim-nio',
      'https://github.com/antoinemadec/FixCursorHold.nvim',
      'https://github.com/marilari88/neotest-vitest',
      'https://github.com/nvim-neotest/neotest-jest',
    }, { load = true, confirm = false })

    local not_node_modules = function(name) return name ~= 'node_modules' end

    require('neotest').setup({
      adapters = {
        require('neotest-vitest')({ filter_dir = not_node_modules }),
        require('neotest-jest')({
          filter_dir = not_node_modules,
          -- Repos with multiple Jest configs set these globals in their own
          -- `.nvim.lua` (needs `vim.o.exrc` + `:trust`) to route each test file
          -- to the config that owns it. Falls back to the default elsewhere.
          jestCommand = function()
            return vim.g.neotest_jest_command or 'npm test --'
          end,
          jestConfigFile = function(file)
            return vim.g.neotest_jest_config and vim.g.neotest_jest_config(file)
          end,
        }),
      },
      output = {
        open_on_run = false,
      },
      output_panel = {
        open = 'bottomright',
      },
    })
    loaded = true
  end
  return require('neotest')
end

local maps = {
  ['<leader>th'] = { 'Run nearest test', function(n) n.run.run() end },
  ['<leader>tw'] = { 'Run file tests', function(n) n.run.run(vim.fn.expand('%')) end },
  ['<leader>tf'] = { 'Run failed tests', function(n) n.run.run({ failed = true }) end },
  ['<leader>ts'] = { 'Toggle test summary', function(n) n.summary.toggle() end },
  ['<leader>to'] = { 'Open test output', function(n) n.output.open({ enter = true }) end },
  ['<leader>td'] = { 'Debug nearest test', function(n) n.run.run({ strategy = 'dap' }) end },
}

for lhs, spec in pairs(maps) do
  vim.keymap.set('n', lhs, function() spec[2](neotest()) end, { desc = spec[1] })
end
