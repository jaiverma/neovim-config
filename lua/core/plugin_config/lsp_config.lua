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

require("lspconfig")["gopls"].setup {
  on_attach = on_attach,
  capabilities = capabilities
}

require("lspconfig")["tsserver"].setup {
  on_attach = on_attach,
  capabilities = capabilities
}

-- ensure you have pyright installed
-- you can do this by creating a venv
--      python3 -m venv test
--      source test/bin/activate
--      pip install --upgrade pip
--      pip install pyright
--      pip install black
--      pip install ruff
--
-- pyright doesn't offer formatting on it's own so we will use:
-- black + ruff + none-ls
require("lspconfig")["pyright"].setup {
  on_attach = on_attach,
  capabilities = capabilities
}

local null_ls = require("null-ls")

null_ls.setup {
  sources = {
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.ruff
  }
}

-- Enable format-on-save using LSP
-- vim.api.nvim_buf_create_user_command(vim.api.nvim_get_current_buf(), "MyCommand", function()
--     vim.lsp.buf.format { async = false }
--   end, {})
