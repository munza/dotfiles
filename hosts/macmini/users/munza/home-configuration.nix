# Tawsif's home. Each tool's settings live in its own file next to this one;
# this file picks the modules and sets home-wide things.
{ pkgs, ... }:
{
  imports = [
    ./aerospace.nix
    ./gh.nix
    ./ghostty.nix
    ./herdr.nix
    ./starship.nix
    ./zed.nix
  ];

  dotfiles = {
    fonts.mono = {
      name = "AnnotationM Nerd Font Mono";
      package = pkgs.nerd-fonts.annotationmono;
    };

    aerospace.enable = true;
    btop.enable = true;
    clamav.enable = true;
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
