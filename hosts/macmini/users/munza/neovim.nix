# Neovim's config is hosts/macmini/config/nvim; this adds the language servers
# and formatters it uses, on top of the module's Lua and Nix tools.
{ pkgs, ... }:
{
  programs.neovim.extraPackages = with pkgs; [
    # Shell
    bash-language-server
    shfmt

    # JavaScript, TypeScript and web formats (JSON, YAML, Markdown, HTML, CSS)
    typescript-language-server
    prettierd

    # Python: types, then linting and formatting
    basedpyright
    ruff

    # Elixir
    beamPackages.expert

    # Go
    gopls

    # Rust
    rust-analyzer
  ];
}
