# Neovim with a plain Lua config: <configDir>/nvim in your repo, linked to
# ~/.config/nvim so you edit it in place and just restart nvim. Plugins are
# managed by Neovim's own vim.pack (lockfile kept next to init.lua); language
# servers and formatters come from Nix, on Neovim's PATH only.
#
# Defaults add what editing Lua and Nix needs, plus tree-sitter and ripgrep
# for parsers and search. Add your languages' tools from the host, e.g.
#   programs.neovim.extraPackages = [ pkgs.gopls pkgs.rust-analyzer ];
{ flake, ... }:
flake.lib.mkModule {
  name = "neovim";
  description = "Neovim";
  enable = false;

  glue = {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      # Anything home-manager generates loads through the wrapper, so it never
      # writes an init.lua that would clash with the linked folder.
      sideloadInitLua = true;
    };
    dotfiles.configLinks = [ "nvim" ];
  };

  defaults =
    { pkgs, ... }:
    {
      programs.neovim.extraPackages = with pkgs; [
        # Parsers (nvim-treesitter compiles them) and search
        tree-sitter
        ripgrep
        fd

        # Lua
        lua-language-server
        stylua

        # Nix
        nixd
        nixfmt
      ];
    };
}
