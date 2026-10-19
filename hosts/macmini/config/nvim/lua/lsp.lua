-- Language servers, using Neovim's built-in LSP client; nvim-lspconfig only
-- supplies each server's command and root markers. Servers come from Nix;
-- settings for one server go in lsp/<server>.lua.

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

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { current_line = true }, -- message only on the cursor line
  float = { border = "rounded", source = true },
})

-- Keys that only make sense once a server is attached.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local function map(key, action, desc, modes)
      vim.keymap.set(modes or "n", key, action, { buffer = args.buf, desc = desc })
    end
    -- Results open in mini.pick, like file search.
    local function pick(scope)
      return function()
        MiniExtra.pickers.lsp({ scope = scope })
      end
    end
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "x" })
    map("<leader>ld", pick("definition"), "Definition")
    map("<leader>lD", pick("declaration"), "Declaration")
    map("<leader>lr", pick("references"), "References")
    map("<leader>lR", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>li", pick("implementation"), "Implementation")
    map("<leader>lt", pick("type_definition"), "Type definition")
    map("<leader>ls", pick("document_symbol"), "Document symbols")
    map("<leader>lS", pick("workspace_symbol"), "Workspace symbols")
    map("<leader>le", vim.diagnostic.open_float, "Line diagnostics")
    map("<leader>lh", function()
      local on = vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf })
      vim.lsp.inlay_hint.enable(not on, { bufnr = args.buf })
    end, "Toggle inlay hints")
    map("<leader>lq", "<cmd>lsp restart<CR>", "Restart LSP")
    map("<leader>lf", function()
      require("conform").format({ async = true, lsp_format = "fallback" })
    end, "Format buffer")
  end,
})
