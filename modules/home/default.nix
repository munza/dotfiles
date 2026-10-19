# Added to every home-manager user by darwinModules.default.
{ flake, ... }:
{
  # Through flake.homeModules so modules needing this flake's inputs get them.
  imports = [
    flake.modules.common.user
    flake.homeModules.aerospace
    flake.homeModules.btop
    flake.homeModules.clamav
    flake.homeModules.colima
    flake.homeModules.config-links
    flake.homeModules.direnv
    flake.homeModules.eza
    flake.homeModules.fonts
    flake.homeModules.fzf
    flake.homeModules.gh
    flake.homeModules.ghostty
    flake.homeModules.git
    flake.homeModules.herdr
    flake.homeModules.lazygit
    flake.homeModules.nh
    flake.homeModules.nix-index
    flake.homeModules.secrets-env
    flake.homeModules.secrets-sops
    flake.homeModules.starship
    flake.homeModules.yazi
    flake.homeModules.zed
    flake.homeModules.zoxide
    flake.homeModules.zsh
  ];

  # XDG_CONFIG_HOME and friends, so tools use ~/.config instead of macOS locations.
  xdg.enable = true;
}
