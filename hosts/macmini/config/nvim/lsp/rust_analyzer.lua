-- Merged over nvim-lspconfig's defaults for rust_analyzer.
return {
  settings = {
    ["rust-analyzer"] = {
      check = { command = "clippy" }, -- clippy on save, not plain cargo check
      cargo = { features = "all" }, -- every feature combination of the workspace
    },
  },
}
