-- oil.nvim : explorer et modifier les dossiers comme un buffer texte
vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

require('oil').setup {
  default_file_explorer = true, -- `nvim .` ou `:e dossier/` ouvre oil
  view_options = { show_hidden = true }, -- affiche les fichiers cachés (.zshrc…)
}

vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Ouvrir le dossier parent (oil)' })
