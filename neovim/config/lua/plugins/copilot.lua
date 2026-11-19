-- Skip copilot.vim when Claude Code launched nvim. Its Copilot server exits with status 7 in that session.
-- plugin/copilot.vim returns early when g:loaded_copilot is set, so its VimEnter hook never starts the server.
-- Set the flag before vim.pack.add, because that call loads the plugin.
if vim.startswith(vim.env.AI_AGENT or '', 'claude-code') then vim.g.loaded_copilot = 1 end

vim.pack.add({
  'https://github.com/github/copilot.vim',
}, { load = true, confirm = false })
