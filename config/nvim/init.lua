-- Neovim starter config, linked to ~/.config/nvim: edit and restart nvim.
-- Plugins install on first start with vim.pack (`:help vim.pack`).

vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2

vim.pack.add({
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/neovim/nvim-lspconfig",
})

require("mini.icons").setup()
require("mini.statusline").setup()
require("mini.pick").setup()
require("mini.completion").setup()

-- Language servers from Nix (see modules/home/neovim.nix).
vim.lsp.enable({ "lua_ls", "nixd" })

vim.keymap.set("n", "<leader>ff", MiniPick.builtin.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", MiniPick.builtin.grep_live, { desc = "Live grep" })
