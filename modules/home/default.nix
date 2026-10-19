# Added to every home-manager user by darwinModules.default.
{ flake, ... }:
{
  # Through flake.homeModules so modules needing this flake's inputs get them.
  imports = [
    flake.modules.common.user
    flake.homeModules.config-links
    flake.homeModules.direnv
    flake.homeModules.gh
    flake.homeModules.git
    flake.homeModules.nh
    flake.homeModules.nix-index
    flake.homeModules.starship
    flake.homeModules.zsh
  ];

  # XDG_CONFIG_HOME and friends, so tools use ~/.config instead of macOS locations.
  xdg.enable = true;
}
