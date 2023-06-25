vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup {
  renderer = {
    icons = {
      show = {
        git = true,
        folder = false,
        file = false,
        folder_arrow = false,
      }
    }
  }
}

vim.keymap.set('n', '<c-n>', ':NvimTreeFindFileToggle<CR>')
