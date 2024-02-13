require("nvim-treesitter.configs").setup {
  ensure_installed = {
    "c",
    "lua",
    "vim",
    "python",
    "cpp",
    "ocaml",
    "dart",
    "scala",
    "json",
    "javascript",
    "rust"
  },

  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
  }
}
