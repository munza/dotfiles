-- Tawsif's Neovim, linked to ~/.config/nvim: edit and restart nvim.
-- Plugins install on first start with vim.pack; language servers and
-- formatters come from Nix (hosts/macmini/users/munza/neovim.nix).
-- Per-server settings live in lsp/<server>.lua, which Neovim loads on its own.

-- Before any <leader> mapping, since <leader> is expanded when a map is made.
vim.g.mapleader = " "

require("options")
require("plugins")
require("lsp")
require("keymaps")
