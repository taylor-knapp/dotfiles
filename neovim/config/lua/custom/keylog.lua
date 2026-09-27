-- Keystroke logger: toggle with :KeyLog
--
-- Uses vim.on_key(), Neovim's low-level hook that runs a callback for EVERY
-- key Neovim consumes from the input stream. The callback receives:
--   * key   — the key after mappings/remaps were applied
--   * typed — the raw key as you actually typed it (before mapping)
-- We display `typed` so you see what your terminal/keyboard really sent, which
-- is what you want when debugging "what escape sequence is this key?".
--
-- Two views per keypress:
--   readable — vim.fn.keytrans() turns raw bytes into Neovim's key names,
--              e.g. the byte 0x1b 0x4f 0x50 -> "<F1>", 0x01 -> "<C-A>".
--   raw      — the literal bytes in \xNN hex, the actual escape sequence.
--
-- Output goes through nvim_echo with history=true, so it lands in :messages.
-- Review the full log any time with :messages (or :mes). Toggle off with
-- :KeyLog again — re-running removes the on_key callback for our namespace.

local M = {}

-- A namespace scopes our callback so we can remove exactly this logger later
-- without touching on_key callbacks any other plugin may have registered.
local ns = vim.api.nvim_create_namespace('keylog')
local active = false

local function to_hex(s)
  return (s:gsub('.', function(c) return string.format('\\x%02x', c:byte()) end))
end

function M.toggle()
  if active then
    vim.on_key(nil, ns) -- passing nil removes the callback for this namespace
    active = false
    vim.notify('KeyLog OFF', vim.log.levels.INFO)
    return
  end

  active = true
  vim.on_key(function(key, typed)
    -- `typed` is what was physically entered; fall back to `key` if a mapping
    -- produced keys with no corresponding typed input.
    local bytes = (typed ~= nil and typed ~= '') and typed or key
    if bytes == '' then return end

    local readable = vim.fn.keytrans(bytes)
    local raw = to_hex(bytes)

    -- on_key runs in a fast event context where echoing directly is unsafe;
    -- vim.schedule defers it to the main loop.
    vim.schedule(function()
      vim.api.nvim_echo({
        { 'key ', 'Comment' },
        { readable, 'String' },
        { '  raw ' .. raw, 'Comment' },
      }, true, {}) -- history=true -> visible in :messages
    end)
  end, ns)

  vim.notify('KeyLog ON — type keys, then :messages to review (:KeyLog to stop)', vim.log.levels.INFO)
end

vim.api.nvim_create_user_command('KeyLog', M.toggle, { desc = 'Toggle keystroke/escape-sequence logger' })

return M
