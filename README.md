# nvim-config

### Adding support for new language (lsp and auto-complete)

Add tree-sitter highlighting by adding the language to
`lua/core/plugin_config/treesitter.lua`

Install lsp support through `mason`.
In nvim run,

```vim
:Mason
```

Search for the language and press `i` to install.

Configure lspconfig,

```lua
require('lspconfig').rust_analyzer.setup{
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    ['rust-analyzer'] = {
      diagnostics = {
        enable = false;
      }
    }
  }
}
```
