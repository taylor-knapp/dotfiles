-- Stop `indentexpr` re-firing when a line is opened, which mangles JSDoc blocks.
--
-- THE BUG: pressing Enter or `o` inside a `/** */` comment produced stray,
-- progressively-indented `*` lines instead of one aligned continuation.
-- Prettier rewrites them to a single space on save, so every doc-comment edit
-- made a spurious diff.
--
-- THE CAUSE: Neovim's bundled `runtime/indent/typescript.vim` sets
-- `indentkeys` to `0{,0},0),0],0,,!^F,o,O,e`. The `o`/`O` entries re-trigger
-- `GetTypescriptIndent()` every time a line is opened. That function delegates
-- to `cindent()` inside multi-line comments (line 360 of the runtime file), and
-- cindent indents the new leader relative to the previous line — so each
-- continuation drifts one level deeper than the last.
--
-- THE FIX: drop `o`, `O`, and `e` from `indentkeys`. `indentexpr` stays fully
-- active for actual code (it still fires on `{`, `}`, `(`, `)`, `[`, `]`, `,`
-- and `<C-f>`); it just no longer re-indents a line at the moment you open one.
--
-- TO UNDO: delete this file (and its javascript/react siblings). That restores
-- the stock `indentkeys` and the JSDoc drift along with it.
--
-- WHAT TO WATCH FOR: `o`/`O` were the keys that auto-indented a newly opened
-- line in code. `autoindent` still copies the previous line's indent, so normal
-- code is unaffected in practice — but if you ever open a line where the indent
-- should *change* automatically (e.g. `o` directly after a `{` should indent in,
-- or after a `}` should not), and it now keeps the previous line's indent
-- instead, this file is why. `==` re-indents any line on demand.
--
-- Verified interactively: with stock `indentkeys` the drift reproduces; with
-- `o,O,e` removed it does not. It does NOT reproduce in headless nvim, so test
-- any change to this in a real session.
-- Deferred with `vim.schedule` because something in this config re-runs the
-- stock indent file after `after/ftplugin` (setting `indentkeys` directly here
-- gets overwritten — verified). Scheduling puts this last.
local buf = vim.api.nvim_get_current_buf()
vim.schedule(function()
  -- Only touch the buffer that triggered this; by the time the scheduled
  -- callback runs the user may have switched away. `indentkeys` is
  -- buffer-local, so set it via `setbufvar` rather than `opt_local`.
  if vim.api.nvim_buf_is_valid(buf) then
    vim.fn.setbufvar(buf, '&indentkeys', '0{,0},0),0],0,,!^F')
  end
end)
