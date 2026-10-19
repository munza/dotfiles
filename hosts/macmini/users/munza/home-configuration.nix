# Tawsif's home. Imports hold each tool's settings and the font; the dotfiles
# block below turns tools on.
{ ... }:
{
  imports = [
    ./aerospace.nix
    ./colima.nix
    ./fonts.nix
    ./gh.nix
    ./ghostty.nix
    ./herdr.nix
    ./neovim.nix
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
    neovim.enable = true;
    yazi.enable = true;
    zed.enable = true;
  };

  home.sessionVariables = {
    # Pi background jobs, without delegation, Fusion or provider overrides.
    PI_BG_FEATURES = "process";
    MANPAGER = "less -R --use-color -Dd+B -Du+G";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  # Set once at install time; never bump on upgrade.
  home.stateVersion = "26.05";
}
