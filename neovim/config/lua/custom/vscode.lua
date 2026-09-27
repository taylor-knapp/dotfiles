-- Keymaps active only when running inside vscode-neovim. Mirrors the leader
-- scheme used by the native LSP/Telescope plugins so muscle memory carries
-- across both environments. Routes each binding to a VSCode command via
-- `require('vscode').action`.

local ok, vscode = pcall(require, 'vscode')
if not ok then
  return
end

local function action(name, opts)
  return function()
    vscode.action(name, opts)
  end
end

local map = function(mode, lhs, name, desc, opts)
  vim.keymap.set(mode, lhs, action(name, opts), { desc = desc })
end

-- LSP-equivalents
map('n', '<leader>lf', 'editor.action.formatDocument', 'Format document')
map('v', '<leader>lf', 'editor.action.formatSelection', 'Format selection')
map('n', '<leader>la', 'editor.action.quickFix', 'Code actions')
map('n', '<leader>lr', 'editor.action.rename', 'Rename symbol')
map('n', '<leader>ld', 'editor.action.showHover', 'Show hover/diagnostic')
map('n', 'grr', 'editor.action.referenceSearch.trigger', 'Find references')
map('n', 'gi', 'editor.action.goToImplementation', 'Go to implementation')
map('n', 'gt', 'editor.action.goToTypeDefinition', 'Go to type definition')

-- Diagnostics navigation
map('n', ']d', 'editor.action.marker.next', 'Next problem')
map('n', '[d', 'editor.action.marker.prev', 'Prev problem')
map('n', ']e', 'editor.action.marker.nextInFiles', 'Next error in files')
map('n', '[e', 'editor.action.marker.prevInFiles', 'Prev error in files')

-- Pickers (replace Telescope leader-f bindings)
map('n', '<leader>ff', 'workbench.action.quickOpen', 'Find file')
map('n', '<leader>fg', 'workbench.action.findInFiles', 'Grep in workspace')
map('n', '<leader>fb', 'workbench.action.showAllEditors', 'Find buffer')
map('n', '<leader>fr', 'workbench.action.openRecent', 'Recent files')
map('n', '<leader>fs', 'workbench.action.gotoSymbol', 'Find symbol in file')
map('n', '<leader>fS', 'workbench.action.showAllSymbols', 'Find symbol in workspace')

-- Git changes (gitsigns ]c/[c equivalents)
map('n', ']c', 'workbench.action.editor.nextChange', 'Next change')
map('n', '[c', 'workbench.action.editor.previousChange', 'Prev change')

-- Buffer / tab management
map('n', '<leader>bd', 'workbench.action.closeActiveEditor', 'Close editor')

-- Claude Code
map('v', '<leader>as', 'claude-code.insertAtMentioned', 'Send selection to Claude')
