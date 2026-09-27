-- Key-decoding probe. See learning/05-recommendations.md.
--
-- Records every keycode Neovim's terminal input parser produces, then writes the
-- list to a file and quits. Used by probe.sh to answer "what would Neovim do if it
-- received these exact bytes?"
--
-- vim.on_key registers a callback fired for every key AFTER the terminal parser has
-- turned bytes into a keycode, but BEFORE keymaps run. That position is what makes
-- it a clean layer boundary: if a keycode shows up here, the terminal delivered it
-- successfully and any remaining problem is in your mappings.
--
-- vim.fn.keytrans converts the raw internal byte string into readable '<D-Left>' form.

local out_path = vim.env.NVIM_PROBE_OUT or '/tmp/nvim-probe-out.txt'
local timeout = tonumber(vim.env.NVIM_PROBE_TIMEOUT or '2500')

local keys = {}

vim.on_key(function(k)
  keys[#keys + 1] = vim.fn.keytrans(k)
end)

vim.defer_fn(function()
  local f = io.open(out_path, 'w')
  if f then
    f:write(table.concat(keys, ' | '))
    f:close()
  end
  vim.cmd('qa!')
end, timeout)
