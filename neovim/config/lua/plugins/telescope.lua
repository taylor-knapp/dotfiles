if vim.g.vscode then return end

-- plenary and fzf-native first (telescope depends on both)
-- fzf-native is compiled with `make` — see the PackChanged hook in plugins/init.lua
vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  { src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim',               version = 'master' },
  { src = 'https://github.com/nvim-telescope/telescope-live-grep-args.nvim' },
}, { load = true, confirm = false })

local telescope = require('telescope')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local builtin = require('telescope.builtin')
local lga_actions = require('telescope-live-grep-args.actions')

local EXCLUDED_DIRS = {
  'node_modules', '.pnpm-store', '.yarn', 'vendor',
  'dist', 'build', 'out', 'target', 'coverage',
  '.next', '.nuxt', '.svelte-kit', '.turbo', '.vercel',
  '.cache', '.git', '.DS_Store', '.idea',
}

local EXCLUDED_FILES = {
  '*.{test,spec}.ts',
  'openspec',
  'pnpm-lock.yaml', 'package-lock.json', 'yarn.lock', '*.lock',
}

local function make_globs(patterns)
  return vim.tbl_map(function(p) return '--glob=!' .. p end, patterns)
end

local dir_globs = make_globs(EXCLUDED_DIRS)
local file_globs = make_globs(EXCLUDED_FILES)
local narrow_globs = vim.list_extend(vim.deepcopy(dir_globs), file_globs)

local function build_args(base, extra)
  return vim.list_extend(vim.deepcopy(base), extra)
end

local FIND_BASE = { 'rg', '--files', '--hidden', '--follow' }
local GREP_BASE = {
  'rg', '--color=never', '--no-heading', '--with-filename',
  '--line-number', '--column', '--smart-case', '--hidden', '--follow',
}

-- Three modes cycled with <C-i>. Prompt prefix shows current mode.
--   1. [narrow] — exclude dirs + test/spec/lockfiles/openspec
--   2. [+tests] — exclude dirs only (tests, lockfiles, openspec visible)
--   3. [all]    — no exclusions, ignores .gitignore
local MODES = {
  {
    label = '[narrow]',
    find  = build_args(FIND_BASE, narrow_globs),
    grep  = build_args(GREP_BASE, narrow_globs),
  },
  {
    label = '[+tests]',
    find  = build_args(FIND_BASE, vim.list_extend({ '--no-ignore', '--no-config' }, dir_globs)),
    grep  = build_args(GREP_BASE, vim.list_extend({ '--no-ignore', '--no-config' }, dir_globs)),
  },
  {
    label = '[all]',
    find  = build_args(FIND_BASE, { '--no-ignore', '--no-config' }),
    grep  = build_args(GREP_BASE, { '--no-ignore', '--no-config' }),
  },
}

local mode_idx = 1

local open_picker

-- Typing `.spec`/`.test` in the prompt means you want test files, which
-- [narrow] excludes. Reopen in [+tests] carrying the query over.
local pending_toggle = false
local function auto_widen_for_test_query(is_grep)
  if mode_idx ~= 1 or pending_toggle then return end
  pending_toggle = true
  vim.schedule(function()
    pending_toggle = false
    local bufnr = vim.api.nvim_get_current_buf()
    local picker = action_state.get_current_picker(bufnr)
    if not picker then return end
    local query = picker:_get_prompt()
    if not (query:match('%.spec') or query:match('%.test')) then return end
    mode_idx = 2
    actions.close(bufnr)
    open_picker(is_grep, query)
  end)
end

function open_picker(is_grep, query)
  local mode = MODES[mode_idx]
  local picker_opts = {
    default_text       = query,
    prompt_prefix      = mode.label .. ' > ',
    on_input_filter_cb = function() auto_widen_for_test_query(is_grep) end,
  }
  if is_grep then
    picker_opts.vimgrep_arguments = mode.grep
    require('telescope').extensions.live_grep_args.live_grep_args(picker_opts)
  else
    picker_opts.find_command = mode.find
    builtin.find_files(picker_opts)
  end
end

local function toggle_mode(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local query = picker:_get_prompt()
  local is_grep = picker.prompt_title:lower():match('grep')
  actions.close(prompt_bufnr)
  mode_idx = (mode_idx % #MODES) + 1
  open_picker(is_grep, query)
end

telescope.setup({
  extensions = {
    fzf = {
      fuzzy                   = true,
      override_generic_sorter = true,
      override_file_sorter    = true,
      case_mode               = 'smart_case',
    },
    live_grep_args = {
      auto_quoting = true,
      mappings = {
        i = {
          ['<C-k>'] = lga_actions.quote_prompt(),
          ['<C-g>'] = lga_actions.quote_prompt({ postfix = ' --iglob **/' }),
          ['<C-space>'] = lga_actions.to_fuzzy_refine,
        },
      },
    },
  },
  defaults = {
    mappings = {
      i = {
        ['<C-s>'] = toggle_mode,
        ['<C-q>'] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local multi = picker:get_multi_selection()
          if #multi > 0 then
            actions.send_selected_to_qflist(prompt_bufnr)
          else
            actions.send_to_qflist(prompt_bufnr)
          end
          vim.cmd('copen')
        end,
        ['<C-x>'] = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local raw_query = picker:_get_prompt()
          local query = raw_query:match('^%s*(.-)%s*%-%-.*$') or raw_query:match('^%s*(.-)%s*$') or raw_query
          local multi = picker:get_multi_selection()
          if #multi > 0 then
            actions.send_selected_to_qflist(prompt_bufnr)
          else
            actions.send_to_qflist(prompt_bufnr)
          end
          vim.cmd('copen')
          vim.schedule(function()
            vim.ui.input({ prompt = 'Replace "' .. query .. '" with: ' }, function(replacement)
              if replacement == nil then return end
              local escaped = vim.fn.escape(query, '/\\')
              local repl_escaped = vim.fn.escape(replacement, '/\\')
              vim.cmd('cfdo %s/' .. escaped .. '/' .. repl_escaped .. '/gc | update')
              vim.cmd('close')
              vim.cmd('cclose')
            end)
          end)
        end,
      },
      n = { ['<C-s>'] = toggle_mode },
    },
    vimgrep_arguments = MODES[1].grep,
  },
  pickers = {
    find_files = { find_command = MODES[1].find },
  },
})

telescope.load_extension('fzf')
telescope.load_extension('emoji')
telescope.load_extension('live_grep_args')

local map = vim.keymap.set
map('n', '<leader>ff', function()
  mode_idx = 1
  open_picker(false, nil)
end, { desc = '[F]ind [F]iles' })
map('n', '<leader>fg', function()
  mode_idx = 1
  open_picker(true, nil)
end, { desc = '[F]ind by [G]rep' })
map('n', '<leader>fb', builtin.buffers, { desc = '[F]ind [B]uffers' })
map('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
map('n', '<leader>fr', function()
  local repo_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
  builtin.oldfiles({
    cwd_only = true,
    cwd = repo_root ~= '' and repo_root or vim.fn.getcwd(),
  })
end, { desc = '[F]ind [R]ecent files' })
map('n', '<leader>fs', builtin.grep_string, { desc = '[F]ind [S]tring under cursor' })
