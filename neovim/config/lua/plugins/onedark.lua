if vim.g.vscode then return end

-- load = true: sources immediately so colorscheme applies before other plugins
vim.pack.add({
  'https://github.com/navarasu/onedark.nvim',
}, { load = true, confirm = false })

require('onedark').setup({
  style = 'dark',
  -- transparent = true nulls the background of Normal (and SignColumn,
  -- EndOfBuffer, etc.) so the terminal's own background shows through. This
  -- makes nvim match the terminal exactly — including the terminal's opacity
  -- and any blur — instead of hardcoding a guessed hex. Floats keep an opaque
  -- bg via the custom_highlights below.
  transparent = true,
  custom_highlights = function(colors)
    return {
      NormalFloat = { bg = colors.bg1 },
      FloatBorder = { fg = colors.blue, bg = colors.bg1 },
      FloatTitle = { fg = colors.blue, bg = colors.bg1, fmt = 'bold' },
    }
  end,
})
require('onedark').load()
