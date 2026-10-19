-- Completion and docs for nixpkgs, nix-darwin and home-manager options,
-- evaluated from this repo's flake (committed or staged files only).
local flake = 'builtins.getFlake "' .. vim.fn.expand("~/.dotfiles") .. '"'
local darwin = "(" .. flake .. ").darwinConfigurations.macmini.options"

return {
  settings = {
    nixd = {
      nixpkgs = { expr = "import (" .. flake .. ").inputs.nixpkgs { }" },
      options = {
        darwin = { expr = darwin },
        home_manager = { expr = darwin .. ".home-manager.users.type.getSubOptions [ ]" },
      },
    },
  },
}
