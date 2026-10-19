-- Language servers, using Neovim's built-in LSP client; nvim-lspconfig only
-- supplies each server's command and root markers. Servers come from Nix.

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      check = { command = "clippy" }, -- clippy on save, not plain cargo check
      cargo = { features = "all" }, -- every feature combination of the workspace
    },
  },
})

vim.lsp.enable({
  "nixd",
  "bashls",
  "lua_ls",
  "ts_ls",
  "basedpyright", -- types
  "ruff", -- lint and format
  "expert", -- Elixir
  "gopls",
  "rust_analyzer",
})

-- Inline type and parameter hints where the server supports them.
vim.lsp.inlay_hint.enable(true)

-- Keys that only make sense once a server is attached.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local function map(key, action, desc)
      vim.keymap.set("n", key, action, { buffer = args.buf, desc = desc })
    end
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>ld", vim.lsp.buf.definition, "Definition")
    map("<leader>lD", vim.lsp.buf.declaration, "Declaration")
    map("<leader>lr", vim.lsp.buf.references, "References")
    map("<leader>lR", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>li", vim.lsp.buf.implementation, "Implementation")
    map("<leader>lt", vim.lsp.buf.type_definition, "Type definition")
  end,
})
