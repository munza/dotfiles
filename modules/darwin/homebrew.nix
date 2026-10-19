# Homebrew, for apps nixpkgs doesn't ship well (most GUI apps). Declare them in
# the host, e.g. homebrew.casks = [ "firefox" ];
#
# Apps you didn't declare are left alone. To have rebuilds remove them, set
# homebrew.onActivation.cleanup = "uninstall" (or "zap", which also deletes their data).
{ inputs, ... }:
{ config, lib, ... }:
{
  # Installs Homebrew itself, so a fresh Mac needs no manual step.
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  homebrew = {
    enable = lib.mkDefault true;
    # Puts brew and the apps it installs on PATH.
    enableZshIntegration = lib.mkDefault true;
  };

  nix-homebrew = {
    enable = lib.mkDefault config.homebrew.enable;
    user = config.dotfiles.user.name;
    # Takes over a Homebrew that was installed by hand, instead of failing.
    autoMigrate = lib.mkDefault true;
  };
}
