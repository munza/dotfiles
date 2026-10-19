-- Tawsif's Neovim, linked to ~/.config/nvim: edit and restart nvim.
-- Plugins install on first start with vim.pack; language servers and
-- formatters come from Nix (hosts/macmini/users/munza/neovim.nix).

-- Before any <leader> mapping, since <leader> is expanded when a map is made.
vim.g.mapleader = " "

vim.o.timeoutlen = 300 -- how long to wait on a key sequence like <leader>
vim.o.number = true
vim.o.relativenumber = true

-- Start unfolded; treesitter folds are still there for za/zc/zo.
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

-- 4-space indentation.
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true

require("plugins")
require("lsp")
require("keymaps")
