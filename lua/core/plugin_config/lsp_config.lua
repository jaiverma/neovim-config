require('mason').setup()
require('mason-lspconfig').setup()

local on_attach = function(_, bufnr)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
  vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, {})
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
  vim.api.nvim_buf_create_user_command(
    bufnr, "Ff", function()
      vim.lsp.buf.format { async = false }
    end, {})
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

require('lspconfig').ocamllsp.setup {
  on_attach = on_attach,
  capabilities = capabilities
}

require('lspconfig').clangd.setup {
  on_attach = on_attach,
  capabilities = capabilities
}

require('lspconfig').sourcekit.setup {
  cmd = { '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp' },
  on_attach = on_attach,
  capabilities = capabilities
}

require('flutter-tools').setup {
  lsp = {
    on_attach = on_attach
  }
}

require('lspconfig').rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    ['rust-analyzer'] = {
      diagnostics = {
        enable = false,
      }
    }
  }
}

require("lspconfig")["lua_ls"].setup {
  on_attach = on_attach,
  capabilities = capabilities
}

-- Enable format-on-save using LSP
-- vim.api.nvim_buf_create_user_command(vim.api.nvim_get_current_buf(), "MyCommand", function()
--     vim.lsp.buf.format { async = false }
--   end, {})
