# Your home-manager config. The file name is your macOS login name (`whoami`);
# see ../darwin-configuration.nix for the steps.
{
  # Opt-in apps; remove the ones you don't want.
  dotfiles.ghostty.enable = true;

  # Set once at install time; never bump on upgrade.
  home.stateVersion = "26.05";
}
