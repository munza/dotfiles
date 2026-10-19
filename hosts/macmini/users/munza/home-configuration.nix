# Tawsif's home. Imports hold each tool's settings and the font; the dotfiles
# block below turns tools on.
{ pkgs, ... }:
{
  imports = [
    ./aerospace.nix
    ./colima.nix
    ./fonts.nix
    ./gh.nix
    ./ghostty.nix
    ./herdr.nix
    ./starship.nix
    ./zed.nix
  ];

  dotfiles = {
    aerospace.enable = true;
    btop.enable = true;
    clamav.enable = true;
    colima.enable = true;
    ghostty.enable = true;
    herdr.enable = true;
    lazygit.enable = true;
    yazi.enable = true;
    zed.enable = true;
  };

  # Plain Neovim for quick edits; its config is parked for now.
  home.packages = [ pkgs.neovim ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    # Pi background jobs, without delegation, Fusion or provider overrides.
    PI_BG_FEATURES = "process";
    MANPAGER = "less -R --use-color -Dd+B -Du+G";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  # Set once at install time; never bump on upgrade.
  home.stateVersion = "26.05";
}
