local scratch_dir = vim.fn.stdpath('data') .. '/scratch'

vim.fn.mkdir(scratch_dir, 'p')

vim.keymap.set('n', '<leader>sn', function()
  local name = vim.fn.input('Scratch name: ')
  if name == '' then return end
  if not name:match('%.') then
    name = name .. '.md'
  end
  vim.cmd.edit(scratch_dir .. '/' .. name)
end, { desc = '[S]cratch [N]ew' })

vim.keymap.set('n', '<leader>so', function()
  require('telescope.builtin').find_files({
    cwd = scratch_dir,
    prompt_title = 'Scratch Files',
  })
end, { desc = '[S]cratch [O]pen' })

return {}
